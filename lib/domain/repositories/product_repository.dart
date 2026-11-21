import '../entities/inputs.dart';
import '../entities/product.dart';

abstract interface class ProductRepository {
  /// Pencarian lokal case-insensitive di nama ATAU sku_barcode. Urut nama A-Z.
  /// Default hanya produk ACTIVE.
  Stream<List<Product>> watchProducts({String query = '', bool includeArchived = false});

  Stream<Product?> watchProduct(String id);

  /// Lookup instan untuk scanner. Hanya produk ACTIVE. `null` = "barcode tidak ditemukan".
  Future<Product?> findByBarcode(String barcode);

  /// Membuat UUID v4, simpan lokal dengan sync_status PENDING.
  /// Throw: [ValidationException], [DuplicateBarcodeException], [BusinessInactiveException].
  Future<Product> create(ProductInput input, {int initialStock = 0});

  /// TIDAK pernah mengubah `currentStock`.
  /// Throw: [NotFoundException], [ValidationException], [DuplicateBarcodeException].
  Future<Product> update(String id, ProductInput input);

  /// Soft archive (status ARCHIVED, sync PENDING). Tidak ada hard delete.
  /// Throw: [NotFoundException].
  Future<void> archive(String id);
}
