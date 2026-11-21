import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/data/datasources/local/daos/transaction_dao.dart';
import 'package:stokflow/domain/entities/product.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';

/// Baris DB -> entitas domain. Semua waktu dinormalkan ke UTC.
Product productFromRow(ProductRow r) => Product(
  id: r.id,
  businessId: r.businessId,
  skuBarcode: r.skuBarcode,
  name: r.name,
  unit: r.unit,
  costPrice: r.costPrice,
  sellingPrice: r.sellingPrice,
  currentStock: r.currentStock,
  status: r.status,
  syncStatus: r.syncStatus,
  syncErrorCode: r.syncErrorCode,
  createdAt: r.createdAt.toUtc(),
  updatedAt: r.updatedAt.toUtc(),
);

StockTransaction transactionFromView(TransactionView v) => StockTransaction(
  id: v.header.id,
  businessId: v.header.businessId,
  number: v.header.transactionNumber,
  type: v.header.type,
  notes: v.header.notes,
  createdBy: v.header.createdBy,
  transactionAt: v.header.transactionAt.toUtc(),
  createdAt: v.header.createdAt.toUtc(),
  syncStatus: v.header.syncStatus,
  syncErrorCode: v.header.syncErrorCode,
  items: [
    for (final i in v.items)
      StockTransactionItem(
        id: i.item.id,
        productId: i.item.productId,
        productName: i.product.name,
        unit: i.product.unit,
        quantity: i.item.quantity,
        unitCostSnapshot: i.item.unitCostSnapshot,
      ),
  ],
);
