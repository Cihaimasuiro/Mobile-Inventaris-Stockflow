import 'enums.dart';

/// Input master produk (dipakai untuk create dan update). Stok TIDAK ada di sini:
/// stok awal dikirim terpisah saat create, dan stok hanya berubah lewat transaksi.
class ProductInput {
  const ProductInput({
    required this.name,
    required this.unit,
    required this.sellingPrice,
    this.costPrice = 0,
    this.skuBarcode,
  });

  final String name;
  final String unit;
  final int sellingPrice;
  final int costPrice;
  final String? skuBarcode;
}

class NewTransactionItem {
  const NewTransactionItem({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}

class NewTransaction {
  const NewTransaction({required this.type, required this.items, this.notes, this.transactionAt});

  final TransactionType type;
  final List<NewTransactionItem> items;
  final String? notes;

  /// Default: waktu sekarang.
  final DateTime? transactionAt;
}

class RegisterInput {
  const RegisterInput({
    required this.name,
    required this.identifier,
    required this.password,
    required this.businessName,
    required this.businessCode,
    this.businessType,
    this.address,
  });

  final String name;

  /// Email atau nomor HP (satu kolom di UI). Layer data memetakan ke `email`/`phone`.
  final String identifier;
  final String password;
  final String businessName;
  final String businessCode;
  final String? businessType;
  final String? address;
}
