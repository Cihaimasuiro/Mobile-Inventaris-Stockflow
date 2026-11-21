import 'package:clock/clock.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/core/utils/uuid_generator.dart';
import 'package:stokflow/data/datasources/local/daos/transaction_dao.dart';
import 'package:stokflow/data/datasources/remote/sync_remote.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';

/// Hasil satu siklus. `offline` = jaringan gagal (baris tetap PENDING, coba lagi dengan backoff);
/// `issue` = butuh tindakan pengguna (login ulang / bisnis nonaktif).
class SyncOutcome {
  const SyncOutcome({this.issue, this.offline = false});

  final SyncIssue? issue;
  final bool offline;

  bool get ok => issue == null && !offline;
}

/// Satu siklus sinkronisasi untuk satu bisnis: push produk, push transaksi, lalu pull.
/// Aturan: KONTRAK BERSAMA v1, bagian 7.
///
/// - Produk dikirim dulu; transaksi hanya jika semua produknya sudah dikenal server.
/// - Penolakan server menjadi FAILED (tidak dikirim ulang otomatis); jaringan putus membiarkan PENDING.
/// - Kursor pull disimpan hanya setelah SEMUA halaman berhasil diproses.
class SyncEngine {
  SyncEngine({
    required this._db,
    required this._remote,
    required this._session,
    this.productBatchSize = 100,
    this.transactionBatchSize = 50,
    this.pullOverlap = const Duration(seconds: 60),
    this.maxPullPages = 1000,
    this._ids = const UuidV4Generator(),
  });

  final AppDatabase _db;
  final SyncRemote _remote;
  final AuthSession _session;
  final IdGenerator _ids;
  final int productBatchSize;
  final int transactionBatchSize;
  final Duration pullOverlap;
  final int maxPullPages;

  String get _businessId => _session.businessId;

  Future<SyncOutcome> run() async {
    try {
      await _pushProducts();
      await _pushTransactions();
      await _pullAll();
      return const SyncOutcome();
    } on UnauthorizedException {
      return const SyncOutcome(issue: SyncIssue.authRequired);
    } on BusinessInactiveException {
      return const SyncOutcome(issue: SyncIssue.businessInactive);
    } on NetworkException {
      return const SyncOutcome(offline: true);
    }
  }

  Future<void> _pushProducts() async {
    final queue = _db.syncQueueDao;
    final attempted = <String>{};
    while (true) {
      final rows = (await queue.pendingProducts(
        _businessId,
        limit: productBatchSize,
      )).where((r) => !attempted.contains(r.id)).toList();
      if (rows.isEmpty) return;
      attempted.addAll(rows.map((r) => r.id));

      final payload = [
        for (final r in rows)
          ProductPush(
            id: r.id,
            skuBarcode: r.skuBarcode,
            name: r.name,
            unit: r.unit,
            costPrice: r.costPrice,
            sellingPrice: r.sellingPrice,
            status: r.status,
            createdAt: r.createdAt.toUtc(),
            updatedAt: r.updatedAt.toUtc(),
            initialStock: r.lastSyncedAt == null
                ? r.currentStock - await _db.syncDao.pendingDelta(_businessId, r.id)
                : null,
          ),
      ];
      final results = {for (final r in await _remote.pushProducts(payload)) r.id: r};

      final now = clock.now().toUtc();
      for (final row in rows) {
        final result = results[row.id];
        if (result == null) continue; // tidak di-ack server: tetap PENDING
        if (result.isOk) {
          await queue.markProductSynced(_businessId, row.id, now, pushedUpdatedAt: row.updatedAt);
        } else {
          await queue.markProductFailed(_businessId, row.id, result.errorCode!);
        }
      }
    }
  }

  Future<void> _pushTransactions() async {
    final queue = _db.syncQueueDao;
    final attempted = <String>{};
    while (true) {
      final ids = (await queue.eligibleTransactionIds(
        _businessId,
        limit: transactionBatchSize,
      )).where((id) => !attempted.contains(id)).toList();
      if (ids.isEmpty) return;
      attempted.addAll(ids);

      final views = <TransactionView>[];
      for (final id in ids) {
        final view = await _db.transactionDao.getView(_businessId, id);
        if (view != null) views.add(view);
      }
      final payload = [
        for (final v in views)
          TransactionPush(
            id: v.header.id,
            number: v.header.transactionNumber,
            type: v.header.type,
            notes: v.header.notes,
            transactionAt: v.header.transactionAt.toUtc(),
            items: [
              for (final i in v.items)
                TransactionItemPush(
                  id: i.item.id,
                  productId: i.item.productId,
                  quantity: i.item.quantity,
                  unitCostSnapshot: i.item.unitCostSnapshot,
                ),
            ],
          ),
      ];
      final results = {for (final r in await _remote.pushTransactions(payload)) r.id: r};

      for (final v in views) {
        final result = results[v.header.id];
        if (result == null) continue;
        if (result.isOk) {
          final changed = result.serverNumber != null && result.serverNumber != v.header.transactionNumber;
          await queue.markTransactionSynced(_businessId, v.header.id, number: changed ? result.serverNumber : null);
        } else {
          await queue.markTransactionFailed(_businessId, v.header.id, result.errorCode!);
        }
      }
    }
  }

  Future<void> _pullAll() async {
    final queue = _db.syncQueueDao;
    final since = await queue.lastPullServerTime(_businessId);
    final sinceParam = since?.subtract(pullOverlap);

    String? cursor;
    DateTime? firstServerTime;
    for (var page = 0; page < maxPullPages; page++) {
      final result = await _remote.pull(since: sinceParam, cursor: cursor);
      firstServerTime ??= result.serverTime;
      final at = clock.now().toUtc();
      await _db.transaction(() async {
        await _db.pullMergeDao.applyProducts(_businessId, result.products, at);
        await _db.pullMergeDao.applyTransactions(_businessId, result.transactions, newId: _ids.newId);
      });
      final next = result.nextCursor;
      if (!result.hasMore || next == null || next == cursor) break;
      cursor = next;
    }
    await queue.saveLastPull(_businessId, firstServerTime!, clock.now().toUtc());
  }
}
