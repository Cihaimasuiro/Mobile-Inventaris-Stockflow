import 'package:drift/drift.dart';

import '../enum_converters.dart';
import 'businesses.dart';

/// Master produk. Sengaja TANPA unique index barcode: baris dari server harus selalu bisa
/// masuk; keunikan ditegakkan repository (dalam transaksi DB) dan server.
@DataClassName('ProductRow')
@TableIndex(name: 'ix_products_list', columns: {#businessId, #status, #name})
@TableIndex(name: 'ix_products_barcode', columns: {#businessId, #skuBarcode})
@TableIndex(name: 'ix_products_sync', columns: {#businessId, #syncStatus})
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get skuBarcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get sellingPrice => integer().withDefault(const Constant(0))();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  TextColumn get status => text().map(const ProductStatusConverter())();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get syncErrorCode => text().nullable()();

  /// NULL = server belum pernah menerima produk ini (payload push menyertakan stok awal).
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
