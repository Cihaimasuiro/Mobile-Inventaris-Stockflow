import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/sync_summary.dart';
import '../../domain/repositories/sync_repository.dart';
import 'fake_backend.dart';

/// Fake SyncRepository untuk UI. Hitungan PENDING/FAILED diturunkan dari data fake;
/// [isOffline] dan [issue] bisa diubah dari debug menu B untuk melihat tiap kondisi.
class InMemorySyncRepository implements SyncRepository {
  InMemorySyncRepository(this._backend, this._session);

  final FakeBackend _backend;
  final AuthSession Function() _session;

  bool _isSyncing = false;
  bool _isOffline = false;
  SyncIssue? _issue;
  DateTime? _lastSyncedAt;

  bool get isOffline => _isOffline;
  SyncIssue? get issue => _issue;

  set isOffline(bool value) {
    _isOffline = value;
    _backend.notify();
  }

  set issue(SyncIssue? value) {
    _issue = value;
    _backend.notify();
  }

  @override
  Stream<SyncSummary> watchSummary() => _backend.watch(_summary);

  @override
  Future<void> syncNow() async {
    if (_isSyncing || _isOffline || _issue != null) return;
    _isSyncing = true;
    _backend.notify();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _backend.markAllSynced(_session().businessId, includeFailed: false);
    _lastSyncedAt = DateTime.now().toUtc();
    _isSyncing = false;
    _backend.notify();
  }

  @override
  Future<void> retryFailed() async {
    _backend.retryFailed(_session().businessId);
    await syncNow();
  }

  SyncSummary _summary() {
    final businessId = _session().businessId;
    var pending = 0;
    var failed = 0;
    void count(SyncStatus status) {
      if (status == SyncStatus.pending) pending++;
      if (status == SyncStatus.failed) failed++;
    }

    for (final p in _backend.products) {
      if (p.businessId == businessId) count(p.syncStatus);
    }
    for (final t in _backend.transactions) {
      if (t.businessId == businessId) count(t.syncStatus);
    }
    return SyncSummary(
      pendingCount: pending,
      failedCount: failed,
      isSyncing: _isSyncing,
      isOffline: _isOffline,
      initialPullDone: true,
      lastSyncedAt: _lastSyncedAt,
      issue: _issue,
    );
  }
}
