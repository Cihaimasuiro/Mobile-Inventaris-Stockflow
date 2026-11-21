import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/data/datasources/remote/sync_remote.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/products.dart';
import '../tables/stock_transaction_items.dart';
import '../tables/stock_transactions.dart';

part 'pull_merge_dao.g.dart';

/// Aturan merge hasil pull (KONTRAK BERSAMA v1, bagian 7.2). Server adalah otoritas untuk data
/// yang sudah SYNCED; perubahan lokal yang belum terkirim tidak pernah ditimpa.
@DriftAccessor(tables: [Products, StockTransactions, StockTransactionItems])
class PullMergeDao extends DatabaseAccessor<AppDatabase> with _$PullMergeDaoMixin {
  PullMergeDao(super.attachedDatabase);

  /// Mengembalikan jumlah baris yang dilewati (bukan milik bisnis ini).
  ///
  /// - Belum ada lokal, atau lokal SYNCED: timpa semua field master dengan data server.
  /// - Lokal PENDING/FAILED: field master lokal menang sampai terkirim.
  /// - Stok SELALU `stok server + pendingDelta` (tidak kurang dari 0), sehingga stok tidak
  ///   melompat mundur akibat transaksi lokal yang belum terkirim.
  Future<int> applyProducts(String businessId, List<PulledProduct> pulled, DateTime at) => transaction(() async {
    var skipped = 0;
    for (final p in pulled) {
      final existing = await (select(products)..where((r) => r.id.equals(p.id))).getSingleOrNull();
      if (p.businessId != businessId || (existing != null && existing.businessId != businessId)) {
        skipped++;
        continue;
      }
      final stock = math.max(0, p.currentStock + await db.syncDao.pendingDelta(businessId, p.id));
      final scope = update(products)..where((r) => r.id.equals(p.id));

      if (existing == null) {
        await into(products).insert(
          ProductsCompanion.insert(
            id: p.id,
            businessId: businessId,
            name: p.name,
            unit: p.unit,
            status: p.status,
            syncStatus: SyncStatus.synced,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            skuBarcode: Value(p.skuBarcode),
            costPrice: Value(p.costPrice),
            sellingPrice: Value(p.sellingPrice),
            currentStock: Value(stock),
            lastSyncedAt: Value(at),
          ),
        );
      } else if (existing.syncStatus == SyncStatus.synced) {
        await scope.write(
          ProductsCompanion(
            skuBarcode: Value(p.skuBarcode),
            name: Value(p.name),
            unit: Value(p.unit),
            costPrice: Value(p.costPrice),
            sellingPrice: Value(p.sellingPrice),
            status: Value(p.status),
            currentStock: Value(stock),
            updatedAt: Value(p.updatedAt),
            syncErrorCode: const Value(null),
            lastSyncedAt: Value(at),
          ),
        );
      } else {
        // Server mengenal produk ini, tapi perubahan master lokal belum terkirim.
        await scope.write(ProductsCompanion(currentStock: Value(stock), lastSyncedAt: Value(at)));
      }
    }
    return skipped;
  });

  /// Transaksi immutable: yang belum ada disisipkan sebagai SYNCED beserta item; yang sudah ada
  /// hanya diperbarui nomor dan statusnya. Transaksi yang merujuk produk tak dikenal dilewati.
  Future<int> applyTransactions(
    String businessId,
    List<PulledTransaction> pulled, {
    required String Function() newId,
  }) => transaction(() async {
    var skipped = 0;
    for (final t in pulled) {
      final existing = await (select(stockTransactions)..where((r) => r.id.equals(t.id))).getSingleOrNull();
      if (t.businessId != businessId || (existing != null && existing.businessId != businessId)) {
        skipped++;
        continue;
      }
      if (existing != null) {
        await (update(stockTransactions)..where((r) => r.id.equals(t.id))).write(
          StockTransactionsCompanion(
            transactionNumber: Value(t.number),
            syncStatus: const Value(SyncStatus.synced),
            syncErrorCode: const Value(null),
          ),
        );
        continue;
      }
      if (!await _allProductsKnown(businessId, t.items)) {
        skipped++;
        continue;
      }
      await into(stockTransactions).insert(
        StockTransactionsCompanion.insert(
          id: t.id,
          businessId: businessId,
          transactionNumber: t.number,
          type: t.type,
          createdBy: t.createdBy,
          transactionAt: t.transactionAt,
          syncStatus: SyncStatus.synced,
          createdAt: t.createdAt,
          updatedAt: t.createdAt,
          notes: Value(t.notes),
        ),
      );
      for (final item in t.items) {
        await into(stockTransactionItems).insert(
          StockTransactionItemsCompanion.insert(
            id: item.id ?? newId(),
            businessId: businessId,
            transactionId: t.id,
            productId: item.productId,
            quantity: item.quantity,
            createdAt: t.createdAt,
            unitCostSnapshot: Value(item.unitCostSnapshot),
          ),
        );
      }
    }
    return skipped;
  });

  Future<bool> _allProductsKnown(String businessId, List<PulledItem> items) async {
    for (final item in items) {
      final row = await (select(
        products,
      )..where((p) => p.id.equals(item.productId) & p.businessId.equals(businessId))).getSingleOrNull();
      if (row == null) return false;
    }
    return true;
  }
}
