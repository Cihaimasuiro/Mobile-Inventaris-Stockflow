import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/utils/transaction_number.dart';

void main() {
  group('formatTransactionNumber', () {
    test('zero-pad 6 digit dengan format [KODE]-[TAHUN]-[URUT6]', () {
      expect(formatTransactionNumber('TMJ01', 2026, 4), 'TMJ01-2026-000004');
      expect(formatTransactionNumber('TMJ01', 2026, 123456), 'TMJ01-2026-123456');
    });

    test('lebih dari 6 digit tetap valid (digit bertambah)', () {
      expect(formatTransactionNumber('TMJ01', 2026, 1234567), 'TMJ01-2026-1234567');
    });
  });

  group('maxSequence', () {
    test('0 jika tidak ada nomor berprefix sama', () {
      expect(maxSequence('TMJ01-2026-', const []), 0);
      expect(maxSequence('TMJ01-2026-', const ['TMJ01-2025-000009', 'XYZ99-2026-000003']), 0);
    });

    test('mengambil urutan tertinggi, mengabaikan prefix lain dan format rusak', () {
      const numbers = ['TMJ01-2026-000002', 'TMJ01-2026-000010', 'TMJ01-2025-000099', 'TMJ01-2026-abc'];
      expect(maxSequence('TMJ01-2026-', numbers), 10);
    });
  });

  group('isValidBusinessCode', () {
    test('menerima huruf besar/angka 2-10 karakter', () {
      expect(isValidBusinessCode('TMJ01'), isTrue);
      expect(isValidBusinessCode('AB'), isTrue);
      expect(isValidBusinessCode('ABCDEFGHIJ'), isTrue);
    });

    test('menolak huruf kecil, tanda hubung, spasi, terlalu pendek/panjang', () {
      for (final bad in ['tmj01', 'TMJ-01', 'TM J', 'A', 'ABCDEFGHIJK', '']) {
        expect(isValidBusinessCode(bad), isFalse, reason: bad);
      }
    });
  });
}
