import 'copy_with.dart';
import 'enums.dart';

/// Master produk. Uang = rupiah bulat. Semua waktu UTC.
class Product {
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.skuBarcode,
    this.syncErrorCode,
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
  final SyncStatus syncStatus;
  final String? syncErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == ProductStatus.active;

  Product copyWith({
    String? name,
    String? unit,
    int? costPrice,
    int? sellingPrice,
    int? currentStock,
    ProductStatus? status,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    Object? skuBarcode = kUnset,
    Object? syncErrorCode = kUnset,
  }) {
    return Product(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skuBarcode: identical(skuBarcode, kUnset) ? this.skuBarcode : skuBarcode as String?,
      syncErrorCode: identical(syncErrorCode, kUnset) ? this.syncErrorCode : syncErrorCode as String?,
    );
  }

  @override
  String toString() => 'Product($id, $name, stok $currentStock, ${status.wire}, ${syncStatus.wire})';
}
