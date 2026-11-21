import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/validation/new_transaction_validator.dart';
import 'package:stokflow/domain/validation/product_input_validator.dart';

void main() {
  group('validateProductInput', () {
    const valid = ProductInput(name: 'Kopi', unit: 'pcs', sellingPrice: 15000);

    test('input valid menghasilkan peta kosong', () {
      expect(validateProductInput(valid), isEmpty);
    });

    test('mengumpulkan semua kesalahan per field', () {
      const bad = ProductInput(name: '  ', unit: '', sellingPrice: -1, costPrice: -5);
      final errors = validateProductInput(bad, initialStock: -2);
      expect(errors.keys, containsAll(['name', 'unit', 'sellingPrice', 'costPrice', 'initialStock']));
    });

    test('nama dan barcode terlalu panjang ditolak', () {
      final longName = ProductInput(name: 'x' * 121, unit: 'pcs', sellingPrice: 1);
      final longCode = ProductInput(name: 'ok', unit: 'pcs', sellingPrice: 1, skuBarcode: '9' * 65);
      expect(validateProductInput(longName).keys, ['name']);
      expect(validateProductInput(longCode).keys, ['skuBarcode']);
    });
  });

  group('normalizeBarcode', () {
    test('trim dan kosong menjadi null', () {
      expect(normalizeBarcode('  123 '), '123');
      expect(normalizeBarcode('   '), isNull);
      expect(normalizeBarcode(null), isNull);
    });
  });

  group('validateNewTransaction', () {
    test('item kosong dan kuantitas < 1 ditolak', () {
      expect(validateNewTransaction(const NewTransaction(type: TransactionType.stockIn, items: [])).keys, ['items']);
      final zero = NewTransaction(
        type: TransactionType.stockIn,
        items: [const NewTransactionItem(productId: 'a', quantity: 0)],
      );
      expect(validateNewTransaction(zero).keys, ['items[0]']);
    });

    test('catatan terlalu panjang ditolak', () {
      final long = NewTransaction(
        type: TransactionType.stockIn,
        items: [const NewTransactionItem(productId: 'a', quantity: 1)],
        notes: 'x' * 501,
      );
      expect(validateNewTransaction(long).keys, ['notes']);
    });
  });

  group('mergeTransactionItems', () {
    test('menjumlahkan produk kembar dan menjaga urutan kemunculan pertama', () {
      final merged = mergeTransactionItems(const [
        NewTransactionItem(productId: 'b', quantity: 1),
        NewTransactionItem(productId: 'a', quantity: 2),
        NewTransactionItem(productId: 'b', quantity: 4),
      ]);
      expect(merged.map((i) => (i.productId, i.quantity)), [('b', 5), ('a', 2)]);
    });
  });
}
