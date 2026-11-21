import 'package:drift/drift.dart';
import 'package:stokflow/domain/entities/enums.dart';

/// Kolom enum disimpan sebagai nilai `wire` (ACTIVE, PENDING, STOCK_IN, ...) agar sama
/// dengan API backend dan mudah dibaca saat debugging DB.
class ProductStatusConverter extends TypeConverter<ProductStatus, String> {
  const ProductStatusConverter();

  @override
  ProductStatus fromSql(String fromDb) => ProductStatus.fromWire(fromDb);

  @override
  String toSql(ProductStatus value) => value.wire;
}

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) => SyncStatus.fromWire(fromDb);

  @override
  String toSql(SyncStatus value) => value.wire;
}

class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) => TransactionType.fromWire(fromDb);

  @override
  String toSql(TransactionType value) => value.wire;
}

class BusinessStatusConverter extends TypeConverter<BusinessStatus, String> {
  const BusinessStatusConverter();

  @override
  BusinessStatus fromSql(String fromDb) => BusinessStatus.fromWire(fromDb);

  @override
  String toSql(BusinessStatus value) => value.wire;
}
