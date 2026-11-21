import 'package:stokflow/domain/entities/enums.dart';

/// Batas antara sync engine dan jaringan. Engine hanya bicara tipe di file ini; adapter HTTP
/// (setelah bentuk response backend terverifikasi) menerjemahkannya ke JSON.
///
/// Semua method boleh melempar: [UnauthorizedException] (401), [BusinessInactiveException] (403),
/// [NetworkException] (tidak ada koneksi, timeout, 5xx, 429). Penolakan per item dilaporkan
/// lewat [PushItemResult], bukan exception.
abstract interface class SyncRemote {
  Future<List<PushItemResult>> pushProducts(List<ProductPush> products);

  Future<List<PushItemResult>> pushTransactions(List<TransactionPush> transactions);

  Future<PullPage> pull({DateTime? since, String? cursor});
}

class ProductPush {
  const ProductPush({
    required this.id,
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.skuBarcode,
    this.initialStock,
  });

  final String id;
  final String? skuBarcode;
  final String name;
  final String unit;
  final int costPrice;
  final int sellingPrice;
  final ProductStatus status;

  /// HANYA untuk produk yang belum pernah diterima server: stok lokal dikurangi efek transaksi
  /// yang belum sync (agar tidak terhitung dua kali). `null` untuk produk yang sudah dikenal server.
  final int? initialStock;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class TransactionItemPush {
  const TransactionItemPush({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitCostSnapshot,
  });

  final String id;
  final String productId;
  final int quantity;
  final int unitCostSnapshot;
}

class TransactionPush {
  const TransactionPush({
    required this.id,
    required this.number,
    required this.type,
    required this.transactionAt,
    required this.items,
    this.notes,
  });

  final String id;
  final String number;
  final TransactionType type;
  final String? notes;
  final DateTime transactionAt;
  final List<TransactionItemPush> items;
}

/// Hasil per item. `id` yang sudah pernah diterima server HARUS dilaporkan ok (idempoten).
class PushItemResult {
  const PushItemResult.ok(this.id, {this.serverNumber}) : errorCode = null;

  const PushItemResult.failed(this.id, String this.errorCode) : serverNumber = null;

  final String id;

  /// Nomor final dari server (jika server memberi nomor lain karena bentrok).
  final String? serverNumber;

  /// Kode error server (mis. `INSUFFICIENT_STOCK`); `null` = diterima.
  final String? errorCode;

  bool get isOk => errorCode == null;
}

class PulledProduct {
  const PulledProduct({
    required this.id,
    required this.businessId,
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.skuBarcode,
  });

  final String id;
  final String businessId;
  final String? skuBarcode;
  final String name;
  final String unit;
  final int costPrice;
  final int sellingPrice;
  final int currentStock;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PulledItem {
  const PulledItem({required this.productId, required this.quantity, required this.unitCostSnapshot, this.id});

  /// Boleh `null` jika server tidak mengirim id item; engine membuatkan UUID lokal.
  final String? id;
  final String productId;
  final int quantity;
  final int unitCostSnapshot;
}

class PulledTransaction {
  const PulledTransaction({
    required this.id,
    required this.businessId,
    required this.number,
    required this.type,
    required this.createdBy,
    required this.transactionAt,
    required this.createdAt,
    required this.items,
    this.notes,
  });

  final String id;
  final String businessId;
  final String number;
  final TransactionType type;
  final String? notes;
  final String createdBy;
  final DateTime transactionAt;
  final DateTime createdAt;
  final List<PulledItem> items;
}

class PullPage {
  const PullPage({
    required this.serverTime,
    this.products = const [],
    this.transactions = const [],
    this.hasMore = false,
    this.nextCursor,
  });

  /// Jam SERVER saat query dimulai. Dipakai sebagai kursor berikutnya (bukan jam HP).
  final DateTime serverTime;
  final List<PulledProduct> products;
  final List<PulledTransaction> transactions;
  final bool hasMore;
  final String? nextCursor;
}
