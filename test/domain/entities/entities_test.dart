import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/entities/product.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';
import 'package:stokflow/domain/entities/sync_summary.dart';

final _t = DateTime.utc(2026, 11, 19, 3);

Product _product({String? barcode = '123', String? error}) => Product(
  id: 'p1',
  businessId: 'b1',
  name: 'Kopi',
  unit: 'pcs',
  costPrice: 8500,
  sellingPrice: 15000,
  currentStock: 10,
  status: ProductStatus.active,
  syncStatus: SyncStatus.failed,
  createdAt: _t,
  updatedAt: _t,
  skuBarcode: barcode,
  syncErrorCode: error,
);

void main() {
  group('enum wire', () {
    test('fromWire adalah kebalikan dari wire untuk semua nilai', () {
      for (final v in ProductStatus.values) {
        expect(ProductStatus.fromWire(v.wire), v);
      }
      for (final v in TransactionType.values) {
        expect(TransactionType.fromWire(v.wire), v);
      }
      for (final v in SyncStatus.values) {
        expect(SyncStatus.fromWire(v.wire), v);
      }
      for (final v in BusinessStatus.values) {
        expect(BusinessStatus.fromWire(v.wire), v);
      }
    });

    test('nilai wire sesuai API backend', () {
      expect(TransactionType.stockOut.wire, 'STOCK_OUT');
      expect(SyncStatus.pending.wire, 'PENDING');
      expect(ProductStatus.archived.wire, 'ARCHIVED');
      expect(BusinessStatus.suspended.wire, 'SUSPENDED');
    });

    test('nilai tidak dikenal melempar ArgumentError', () {
      expect(() => ProductStatus.fromWire('X'), throwsArgumentError);
      expect(() => TransactionType.fromWire('X'), throwsArgumentError);
      expect(() => SyncStatus.fromWire('X'), throwsArgumentError);
      expect(() => BusinessStatus.fromWire('X'), throwsArgumentError);
    });
  });

  group('Product.copyWith', () {
    test('field yang tidak disebut tetap, termasuk yang nullable', () {
      final p = _product(error: 'DUPLICATE_BARCODE').copyWith(name: 'Baru');
      expect(p.name, 'Baru');
      expect(p.skuBarcode, '123');
      expect(p.syncErrorCode, 'DUPLICATE_BARCODE');
    });

    test('null eksplisit menghapus field nullable', () {
      final p = _product(error: 'X').copyWith(skuBarcode: null, syncErrorCode: null);
      expect(p.skuBarcode, isNull);
      expect(p.syncErrorCode, isNull);
    });

    test('isActive mengikuti status', () {
      expect(_product().isActive, isTrue);
      expect(_product().copyWith(status: ProductStatus.archived).isActive, isFalse);
    });
  });

  test('AuthSession sama jika user, bisnis, dan kode sama', () {
    const a = AuthSession(userId: 'u', userName: 'A', businessId: 'b', businessCode: 'TMJ01', businessName: 'X');
    const b = AuthSession(userId: 'u', userName: 'Lain', businessId: 'b', businessCode: 'TMJ01', businessName: 'Y');
    const c = AuthSession(userId: 'u2', userName: 'A', businessId: 'b', businessCode: 'TMJ01', businessName: 'X');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('StockTransaction menghitung itemCount dan totalQuantity', () {
    final t = StockTransaction(
      id: 't',
      businessId: 'b',
      number: 'TMJ01-2026-000001',
      type: TransactionType.stockOut,
      createdBy: 'u',
      transactionAt: _t,
      createdAt: _t,
      syncStatus: SyncStatus.pending,
      items: const [
        StockTransactionItem(id: '1', productId: 'a', productName: 'A', unit: 'pcs', quantity: 2, unitCostSnapshot: 1),
        StockTransactionItem(id: '2', productId: 'b', productName: 'B', unit: 'dus', quantity: 5, unitCostSnapshot: 1),
      ],
    );
    expect(t.itemCount, 2);
    expect(t.totalQuantity, 7);
  });

  test('SyncSummary.hasUnsynced benar jika ada PENDING atau FAILED', () {
    expect(const SyncSummary().hasUnsynced, isFalse);
    expect(const SyncSummary(pendingCount: 1).hasUnsynced, isTrue);
    expect(const SyncSummary(failedCount: 1).hasUnsynced, isTrue);
  });

  test('NewTransaction dan ProductInput membawa nilai default yang benar', () {
    const input = ProductInput(name: 'Kopi', unit: 'pcs', sellingPrice: 1);
    expect(input.costPrice, 0);
    expect(input.skuBarcode, isNull);
    const trx = NewTransaction(type: TransactionType.stockIn, items: []);
    expect(trx.transactionAt, isNull);
  });
}
