import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/products.dart';
import '../tables/stock_transaction_items.dart';
import '../tables/stock_transactions.dart';
import '../tables/sync_states.dart';

part 'sync_queue_dao.g.dart';

/// Sisi tulis antrean sync: memilih baris yang siap dikirim, menandai hasil, dan kursor pull.
/// Semua method scoped `businessId`.
@DriftAccessor(tables: [Products, StockTransactions, StockTransactionItems, SyncStates])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.attachedDatabase);

  /// Produk PENDING, terlama dulu.
  Future<List<ProductRow>> pendingProducts(String businessId, {int limit = 100}) =>
      (select(products)
            ..where((p) => p.businessId.equals(businessId) & p.syncStatus.equalsValue(SyncStatus.pending))
            ..orderBy([
              (p) => OrderingTerm.asc(p.updatedAt),
              (p) => OrderingTerm.asc(const CustomExpression<int>('products.rowid')),
            ])
            ..limit(limit))
          .get();

  /// Transaksi PENDING yang SEMUA produknya sudah dikenal server (`last_synced_at` terisi),
  /// urut waktu kejadian naik agar STOCK_IN mendahului STOCK_OUT yang terjadi setelahnya.
  Future<List<String>> eligibleTransactionIds(String businessId, {int limit = 50}) async {
    final rows = await customSelect(
      '''
SELECT t.id AS id FROM stock_transactions t
WHERE t.business_id = ? AND t.sync_status = 'PENDING'
  AND NOT EXISTS (
    SELECT 1 FROM stock_transaction_items i JOIN products p ON p.id = i.product_id
    WHERE i.transaction_id = t.id AND p.last_synced_at IS NULL)
ORDER BY t.transaction_at ASC, t.created_at ASC, t.rowid ASC
LIMIT ?
''',
      variables: [Variable.withString(businessId), Variable.withInt(limit)],
      readsFrom: {stockTransactions, stockTransactionItems, products},
    ).get();
    return [for (final r in rows) r.read<String>('id')];
  }

  /// Server menerima produk. `last_synced_at` selalu diisi (server kini mengenalnya); status baru
  /// menjadi SYNCED hanya jika baris tidak diedit lagi sejak dikirim ([pushedUpdatedAt]).
  Future<void> markProductSynced(String businessId, String id, DateTime at, {required DateTime pushedUpdatedAt}) =>
      transaction(() async {
        await (update(products)..where((p) => p.businessId.equals(businessId) & p.id.equals(id))).write(
          ProductsCompanion(lastSyncedAt: Value(at)),
        );
        await (update(products)
              ..where((p) => p.businessId.equals(businessId) & p.id.equals(id) & p.updatedAt.equals(pushedUpdatedAt)))
            .write(const ProductsCompanion(syncStatus: Value(SyncStatus.synced), syncErrorCode: Value(null)));
      });

  Future<void> markProductFailed(String businessId, String id, String errorCode) =>
      (update(products)..where((p) => p.businessId.equals(businessId) & p.id.equals(id))).write(
        ProductsCompanion(syncStatus: const Value(SyncStatus.failed), syncErrorCode: Value(errorCode)),
      );

  /// [number] diisi jika server memberi nomor final yang berbeda.
  Future<void> markTransactionSynced(String businessId, String id, {String? number}) =>
      (update(stockTransactions)..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).write(
        StockTransactionsCompanion(
          syncStatus: const Value(SyncStatus.synced),
          syncErrorCode: const Value(null),
          transactionNumber: number == null ? const Value.absent() : Value(number),
        ),
      );

  Future<void> markTransactionFailed(String businessId, String id, String errorCode) =>
      (update(stockTransactions)..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).write(
        StockTransactionsCompanion(syncStatus: const Value(SyncStatus.failed), syncErrorCode: Value(errorCode)),
      );

  /// FAILED -> PENDING untuk produk dan transaksi. Mengembalikan jumlah baris.
  Future<int> retryFailed(String businessId) => transaction(() async {
    final p =
        await (update(products)
              ..where((r) => r.businessId.equals(businessId) & r.syncStatus.equalsValue(SyncStatus.failed)))
            .write(const ProductsCompanion(syncStatus: Value(SyncStatus.pending), syncErrorCode: Value(null)));
    final t =
        await (update(stockTransactions)
              ..where((r) => r.businessId.equals(businessId) & r.syncStatus.equalsValue(SyncStatus.failed)))
            .write(const StockTransactionsCompanion(syncStatus: Value(SyncStatus.pending), syncErrorCode: Value(null)));
    return p + t;
  });

  Future<DateTime?> lastPullServerTime(String businessId) async => (await (select(
    syncStates,
  )..where((s) => s.businessId.equals(businessId))).getSingleOrNull())?.lastPullServerTime?.toUtc();

  /// Simpan kursor pull. Dipanggil HANYA setelah semua halaman berhasil diproses.
  Future<void> saveLastPull(String businessId, DateTime serverTime, DateTime okAt) =>
      into(syncStates).insertOnConflictUpdate(
        SyncStatesCompanion.insert(
          businessId: businessId,
          lastPullServerTime: Value(serverTime.toUtc()),
          lastSyncOkAt: Value(okAt.toUtc()),
        ),
      );

  Stream<SyncStateRow?> watchState(String businessId) =>
      (select(syncStates)..where((s) => s.businessId.equals(businessId))).watchSingleOrNull();
}
