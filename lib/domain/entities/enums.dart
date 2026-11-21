/// Enum domain bersama. `wire` = nilai persis yang dipakai API backend dan kolom DB lokal.
library;

enum ProductStatus {
  active('ACTIVE'),
  archived('ARCHIVED');

  const ProductStatus(this.wire);
  final String wire;

  static ProductStatus fromWire(String value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'ProductStatus tidak dikenal'),
  );
}

enum TransactionType {
  stockIn('STOCK_IN'),
  stockOut('STOCK_OUT');

  const TransactionType(this.wire);
  final String wire;

  static TransactionType fromWire(String value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'TransactionType tidak dikenal'),
  );
}

enum SyncStatus {
  pending('PENDING'),
  synced('SYNCED'),
  failed('FAILED');

  const SyncStatus(this.wire);
  final String wire;

  static SyncStatus fromWire(String value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'SyncStatus tidak dikenal'),
  );
}

enum BusinessStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  suspended('SUSPENDED');

  const BusinessStatus(this.wire);
  final String wire;

  static BusinessStatus fromWire(String value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'BusinessStatus tidak dikenal'),
  );
}

/// Masalah sinkronisasi yang perlu tindakan pengguna (bukan sekadar offline).
enum SyncIssue { authRequired, businessInactive }
