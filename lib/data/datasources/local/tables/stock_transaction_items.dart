import 'package:drift/drift.dart';

import 'businesses.dart';
import 'products.dart';
import 'stock_transactions.dart';

/// Item transaksi. Status sync mengikuti header.
@DataClassName('StockTransactionItemRow')
@TableIndex(name: 'ix_items_trx', columns: {#transactionId})
@TableIndex(name: 'ix_items_product', columns: {#businessId, #productId})
class StockTransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get transactionId => text().references(StockTransactions, #id)();
  TextColumn get productId => text().references(Products, #id)();
  // ignore: recursive_getters
  IntColumn get quantity => integer().check(quantity.isBiggerThanValue(0))();

  /// = products.cost_price saat transaksi dibuat. Tidak pernah diubah.
  IntColumn get unitCostSnapshot => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
