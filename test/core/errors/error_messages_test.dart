import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/errors/error_messages.dart';

void main() {
  group('messageOf', () {
    test('memakai pesan AppException', () {
      expect(messageOf(const NotFoundException()), 'Data tidak ditemukan.');
      expect(messageOf(const UnauthorizedException()), contains('login'));
      expect(messageOf(const NetworkException()), contains('internet'));
    });

    test('exception lain menjadi pesan generik, tanpa membocorkan detail', () {
      expect(messageOf(StateError('rahasia internal')), 'Terjadi kesalahan tak terduga.');
    });
  });

  group('pesan exception bisnis', () {
    test('InsufficientStockException menyebut produk, sisa, dan diminta', () {
      final e = InsufficientStockException(productId: 'p', productName: 'Kopi', available: 2, requested: 5);
      expect(e.message, 'Stok Kopi tidak mencukupi (tersisa 2, diminta 5).');
    });

    test('DuplicateBarcodeException menyebut barcode', () {
      expect(DuplicateBarcodeException('123').message, contains('123'));
    });

    test('ValidationException memakai kesalahan pertama sebagai pesan', () {
      expect(ValidationException({'name': 'Nama wajib diisi.'}).message, 'Nama wajib diisi.');
      expect(ValidationException({}).message, 'Data tidak valid.');
    });
  });

  group('syncErrorMessage', () {
    test('memetakan kode server yang dikenal', () {
      expect(syncErrorMessage('INSUFFICIENT_STOCK'), contains('Stok'));
      expect(syncErrorMessage('DUPLICATE_BARCODE'), contains('Barcode'));
    });

    test('kode tidak dikenal menyertakan kodenya, null menjadi pesan umum', () {
      expect(syncErrorMessage('ANEH'), 'Gagal sinkron (ANEH).');
      expect(syncErrorMessage(null), 'Gagal sinkron.');
    });
  });
}
