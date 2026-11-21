import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/products.dart';
import '../tables/stock_transaction_items.dart';
import '../tables/stock_transactions.dart';
import '../tables/sync_states.dart';

part 'sync_dao.g.dart';

typedef UnsyncedCount = ({int pending, int failed});

/// Query antrean sinkronisasi (sync_status di baris = antrean). Semua method scoped `businessId`.
@DriftAccessor(tables: [Products, StockTransactions, StockTransactionItems, SyncStates])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.attachedDatabase);

  static const String _countSql = '''
SELECT
  (SELECT COUNT(*) FROM products WHERE business_id = ?1 AND sync_status = 'PENDING')
  + (SELECT COUNT(*) FROM stock_transactions WHERE business_id = ?1 AND sync_status = 'PENDING') AS pending,
  (SELECT COUNT(*) FROM products WHERE business_id = ?1 AND sync_status = 'FAILED')
  + (SELECT COUNT(*) FROM stock_transactions WHERE business_id = ?1 AND sync_status = 'FAILED') AS failed
''';

  /// Efek transaksi yang BELUM diterima server (PENDING atau FAILED) terhadap stok produk.
  /// Definisi kanonik KONTRAK 4: `stok lokal = stok server + pendingDelta`, dan
  /// `stok awal untuk push produk baru = stok lokal - pendingDelta`.
  Future<int> pendingDelta(String businessId, String productId) async {
    final row = await customSelect(
      '''
SELECT COALESCE(SUM(CASE t.type WHEN 'STOCK_IN' THEN i.quantity ELSE -i.quantity END), 0) AS delta
FROM stock_transaction_items i
JOIN stock_transactions t ON t.id = i.transaction_id
WHERE i.business_id = ? AND i.product_id = ? AND t.sync_status IN ('PENDING', 'FAILED')
''',
      variables: [Variable.withString(businessId), Variable.withString(productId)],
      readsFrom: {stockTransactionItems, stockTransactions},
    ).getSingle();
    return row.read<int>('delta');
  }

  Future<UnsyncedCount> countUnsynced(String businessId) async {
    final row = await customSelect(
      _countSql,
      variables: [Variable.withString(businessId)],
      readsFrom: {products, stockTransactions},
    ).getSingle();
    return (pending: row.read<int>('pending'), failed: row.read<int>('failed'));
  }

  Stream<UnsyncedCount> watchUnsynced(String businessId) => customSelect(
    _countSql,
    variables: [Variable.withString(businessId)],
    readsFrom: {products, stockTransactions},
  ).watchSingle().map((row) => (pending: row.read<int>('pending'), failed: row.read<int>('failed')));

  /// Tandai semua baris bisnis ini SYNCED (setelah push sukses). Atomik.
  Future<void> markAllSynced(String businessId, DateTime at) => transaction(() async {
    await (update(
      products,
    )..where((p) => p.businessId.equals(businessId) & p.syncStatus.equalsValue(SyncStatus.synced).not())).write(
      ProductsCompanion(
        syncStatus: const Value(SyncStatus.synced),
        syncErrorCode: const Value(null),
        lastSyncedAt: Value(at),
      ),
    );
    await (update(stockTransactions)
          ..where((t) => t.businessId.equals(businessId) & t.syncStatus.equalsValue(SyncStatus.synced).not()))
        .write(const StockTransactionsCompanion(syncStatus: Value(SyncStatus.synced), syncErrorCode: Value(null)));
  });
}
