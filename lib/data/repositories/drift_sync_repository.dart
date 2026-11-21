import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/data/datasources/local/daos/sync_dao.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/sync_summary.dart';
import 'package:stokflow/domain/repositories/sync_repository.dart';

import 'sync_engine.dart';

/// Jeda sebelum percobaan berikutnya setelah [failures] kegagalan jaringan beruntun:
/// 2 dtk, 4, 8, ... maksimal 5 menit. [jitter] pecahan, mis. -0.2..0.2.
Duration backoffDelay(int failures, {double jitter = 0}) {
  final exponent = math.min(failures < 1 ? 0 : failures - 1, 8);
  final seconds = math.min(300.0, 2.0 * (1 << exponent)) * (1 + jitter);
  return Duration(milliseconds: (seconds * 1000).round());
}

/// SyncRepository asli: membungkus [SyncEngine] dengan single-flight, backoff, dan pemicu
/// (baris PENDING baru, ticker, koneksi kembali). Error jaringan tidak dilempar ke UI;
/// hasilnya tercermin di [SyncSummary].
class DriftSyncRepository implements SyncRepository {
  DriftSyncRepository({
    required this._db,
    required this._session,
    required this._engine,
    this.tickInterval = const Duration(seconds: 30),
    this.debounce = const Duration(seconds: 2),
    this._connectivityRestored,
    math.Random? random,
  }) : _random = random ?? math.Random();

  final AppDatabase _db;
  final AuthSession _session;
  final SyncEngine _engine;
  final Duration tickInterval;
  final Duration debounce;
  final Stream<void>? _connectivityRestored;
  final math.Random _random;

  final StreamController<void> _flagChanges = StreamController<void>.broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _ticker;
  Timer? _debounceTimer;

  Future<void>? _running;
  bool _isSyncing = false;
  bool _isOffline = false;
  SyncIssue? _issue;
  int _failures = 0;
  DateTime? _nextAllowedAt;

  String get _businessId => _session.businessId;

  /// Mulai pemicu otomatis. Panggil sekali setelah login (repository dibuat per sesi).
  void start() {
    _subscriptions.add(
      _db.syncDao.watchUnsynced(_businessId).listen((UnsyncedCount counts) {
        if (counts.pending > 0) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(debounce, _scheduled);
        }
      }),
    );
    final restored = _connectivityRestored;
    if (restored != null) {
      _subscriptions.add(
        restored.listen((_) {
          _nextAllowedAt = null;
          _scheduled();
        }),
      );
    }
    _ticker = Timer.periodic(tickInterval, (_) => _scheduled());
    _scheduled();
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    _debounceTimer?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    // Tunggu siklus yang sedang berjalan (tidak pernah melempar) sebelum menutup stream.
    await _running;
    await _flagChanges.close();
  }

  @override
  Stream<SyncSummary> watchSummary() {
    late StreamController<SyncSummary> controller;
    final subs = <StreamSubscription<Object?>>[];
    UnsyncedCount? counts;
    SyncStateRow? state;
    var haveState = false;

    void emit() {
      final c = counts;
      if (c == null || !haveState || controller.isClosed) return;
      controller.add(
        SyncSummary(
          pendingCount: c.pending,
          failedCount: c.failed,
          isSyncing: _isSyncing,
          isOffline: _isOffline,
          initialPullDone: state?.lastPullServerTime != null,
          lastSyncedAt: state?.lastSyncOkAt?.toUtc(),
          issue: _issue,
        ),
      );
    }

    controller = StreamController<SyncSummary>(
      onListen: () {
        subs.add(
          _db.syncDao.watchUnsynced(_businessId).listen((v) {
            counts = v;
            emit();
          }),
        );
        subs.add(
          _db.syncQueueDao.watchState(_businessId).listen((v) {
            state = v;
            haveState = true;
            emit();
          }),
        );
        subs.add(_flagChanges.stream.listen((_) => emit()));
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<void> syncNow() {
    final running = _running;
    if (running != null) return running; // single-flight
    final future = _runOnce().whenComplete(() => _running = null);
    _running = future;
    return future;
  }

  @override
  Future<void> retryFailed() async {
    await _db.syncQueueDao.retryFailed(_businessId);
    await syncNow();
  }

  void _scheduled() {
    if (_issue != null) return; // butuh tindakan pengguna; repository dibuat ulang setelah login
    final next = _nextAllowedAt;
    if (next != null && clock.now().isBefore(next)) return;
    unawaited(syncNow());
  }

  Future<void> _runOnce() async {
    _isSyncing = true;
    _flagChanges.add(null);
    try {
      final outcome = await _engine.run();
      _issue = outcome.issue;
      _isOffline = outcome.offline;
      if (outcome.offline) {
        _scheduleBackoff();
      } else {
        _failures = 0;
        _nextAllowedAt = null;
      }
    } on Object catch (error, stack) {
      // Kesalahan tak terduga (bug/data aneh): jangan menjatuhkan app, catat, coba lagi nanti.
      developer.log('Sinkronisasi gagal tak terduga', error: error, stackTrace: stack, name: 'stokflow.sync');
      _scheduleBackoff();
    } finally {
      _isSyncing = false;
      _flagChanges.add(null);
    }
  }

  void _scheduleBackoff() {
    _failures++;
    _nextAllowedAt = clock.now().add(backoffDelay(_failures, jitter: (_random.nextDouble() - 0.5) * 0.4));
  }
}
