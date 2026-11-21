import 'enums.dart';

/// Satu baris item dalam transaksi stok. `productName` dan `unit` di-join dari produk saat dibaca.
class StockTransactionItem {
  const StockTransactionItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitCostSnapshot,
  });

  final String id;
  final String productId;
  final String productName;
  final String unit;
  final int quantity;

  /// Harga modal produk saat transaksi dibuat. Tidak berubah walau harga modal master berubah.
  final int unitCostSnapshot;
}

/// Transaksi stok (immutable setelah dibuat). `number` = `[KODE]-[TAHUN]-[URUT6]`.
class StockTransaction {
  const StockTransaction({
    required this.id,
    required this.businessId,
    required this.number,
    required this.type,
    required this.createdBy,
    required this.transactionAt,
    required this.syncStatus,
    required this.items,
    required this.createdAt,
    this.notes,
    this.syncErrorCode,
  });

  final String id;
  final String businessId;
  final String number;
  final TransactionType type;
  final String? notes;
  final String createdBy;
  final DateTime transactionAt;

  /// Waktu baris dibuat di HP (UTC). Pemisah urutan saat `transactionAt` sama.
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final String? syncErrorCode;
  final List<StockTransactionItem> items;

  int get itemCount => items.length;

  /// Jumlah semua kuantitas. Hati-hati: satuan bisa campur (pcs + dus).
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  String toString() => 'StockTransaction($number, ${type.wire}, $itemCount item, ${syncStatus.wire})';
}
