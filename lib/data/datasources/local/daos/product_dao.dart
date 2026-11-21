import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/products.dart';

part 'product_dao.g.dart';

/// Semua method WAJIB menerima `businessId` sebagai parameter pertama (isolasi multi-bisnis).
@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.attachedDatabase);

  /// Pencarian case-insensitive di nama ATAU barcode, urut nama A-Z (NOCASE).
  Stream<List<ProductRow>> watchList(String businessId, {String query = '', bool includeArchived = false}) {
    final q = select(products)..where((p) => p.businessId.equals(businessId));
    if (!includeArchived) q.where((p) => p.status.equalsValue(ProductStatus.active));
    final term = query.trim().toLowerCase();
    if (term.isNotEmpty) {
      q.where((p) => p.name.lower().contains(term) | p.skuBarcode.lower().contains(term));
    }
    q.orderBy([(p) => OrderingTerm(expression: p.name.collate(Collate.noCase))]);
    return q.watch();
  }

  Stream<ProductRow?> watchById(String businessId, String id) =>
      (select(products)..where((p) => p.businessId.equals(businessId) & p.id.equals(id))).watchSingleOrNull();

  Future<ProductRow?> getById(String businessId, String id) =>
      (select(products)..where((p) => p.businessId.equals(businessId) & p.id.equals(id))).getSingleOrNull();

  Future<ProductRow?> findActiveByBarcode(String businessId, String barcode) =>
      (select(products)
            ..where(
              (p) =>
                  p.businessId.equals(businessId) &
                  p.skuBarcode.equals(barcode) &
                  p.status.equalsValue(ProductStatus.active),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Barcode dipakai produk ACTIVE lain? ([exceptId] = abaikan produk yang sedang diedit.)
  Future<bool> isBarcodeTaken(String businessId, String barcode, {String? exceptId}) async {
    final q = select(products)
      ..where(
        (p) =>
            p.businessId.equals(businessId) & p.skuBarcode.equals(barcode) & p.status.equalsValue(ProductStatus.active),
      );
    if (exceptId != null) q.where((p) => p.id.equals(exceptId).not());
    return (await q.get()).isNotEmpty;
  }

  Future<void> insertRow(ProductsCompanion row) => into(products).insert(row);

  Future<void> updateRow(String businessId, String id, ProductsCompanion changes) =>
      (update(products)..where((p) => p.businessId.equals(businessId) & p.id.equals(id))).write(changes);

  /// Ubah stok relatif. Sengaja TIDAK menyentuh `sync_status` maupun `updated_at`:
  /// stok hanya berubah lewat transaksi dan tidak boleh membuat produk PENDING.
  Future<void> addStock(String businessId, String id, int delta) => customUpdate(
    'UPDATE products SET current_stock = current_stock + ? WHERE business_id = ? AND id = ?',
    variables: [Variable.withInt(delta), Variable.withString(businessId), Variable.withString(id)],
    updates: {products},
    updateKind: UpdateKind.update,
  );
}
