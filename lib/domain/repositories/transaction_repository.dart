import '../entities/enums.dart';
import '../entities/inputs.dart';
import '../entities/stock_transaction.dart';

abstract interface class TransactionRepository {
  /// Terbaru dulu (transactionAt DESC, lalu createdAt DESC). Item sudah termuat.
  Stream<List<StockTransaction>> watchTransactions({TransactionType? type, int limit = 100});

  Stream<StockTransaction?> watchTransaction(String id);

  /// ATOMIK: semua atau tidak sama sekali, dalam satu transaksi database.
  ///
  /// 1. Bisnis tidak ACTIVE -> [BusinessInactiveException].
  /// 2. Validasi: item kosong atau qty < 1 -> [ValidationException].
  ///    Produk kembar digabung (kuantitas dijumlah).
  /// 3. Tiap produk (scoped bisnis): tidak ada -> [NotFoundException];
  ///    ARCHIVED -> [ProductArchivedException];
  ///    STOCK_OUT dan stok < qty -> [InsufficientStockException].
  /// 4. Buat nomor `[KODE]-[TAHUN]-[URUT6]`, simpan header (PENDING) dan item
  ///    (unitCostSnapshot = costPrice produk saat ini).
  /// 5. Ubah `currentStock` produk. JANGAN ubah `sync_status` produk.
  /// 6. Tidak memanggil sync: SyncEngine mengamati baris PENDING.
  ///
  /// Tidak ada yang tertulis jika ada exception.
  Future<StockTransaction> createTransaction(NewTransaction input);
}
