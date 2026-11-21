import 'package:drift/drift.dart';

import '../enum_converters.dart';
import 'businesses.dart';

/// Header transaksi stok (immutable setelah dibuat). Tanpa unique index nomor: lihat [Products].
@DataClassName('StockTransactionRow')
@TableIndex(name: 'ix_trx_number', columns: {#businessId, #transactionNumber})
@TableIndex(name: 'ix_trx_history', columns: {#businessId, #transactionAt})
@TableIndex(name: 'ix_trx_type', columns: {#businessId, #type, #transactionAt})
@TableIndex(name: 'ix_trx_sync', columns: {#businessId, #syncStatus})
class StockTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get transactionNumber => text()();
  TextColumn get type => text().map(const TransactionTypeConverter())();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get transactionAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get syncErrorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
