import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/utils/date_formatter.dart';

void main() {
  // Semua waktu dibuat lokal lalu diubah ke UTC, supaya tes tidak bergantung zona waktu mesin.
  DateTime utc(int y, int m, int d, int h, int min) => DateTime(y, m, d, h, min).toUtc();
  final now = DateTime(2026, 11, 19, 10, 30);

  test('formatFullDateTime: tanggal, bulan singkat Indonesia, tahun, jam', () {
    expect(formatFullDateTime(utc(2026, 11, 18, 9, 43)), '18 Nov 2026, 09:43');
    expect(formatFullDateTime(utc(2026, 5, 3, 14, 5)), '3 Mei 2026, 14:05');
    expect(formatFullDateTime(utc(2026, 8, 17, 0, 0)), '17 Agu 2026, 00:00');
  });

  test('hari ini hanya jam, kemarin diberi "Kemarin"', () {
    expect(formatTransactionTime(utc(2026, 11, 19, 8, 15), now: now), '08:15');
    expect(formatTransactionTime(utc(2026, 11, 18, 16, 20), now: now), 'Kemarin, 16:20');
  });

  test('lebih lama dari kemarin memakai tanggal lengkap', () {
    expect(formatTransactionTime(utc(2026, 11, 16, 9, 0), now: now), '16 Nov 2026, 09:00');
    expect(formatTransactionTime(utc(2025, 12, 31, 23, 59), now: now), '31 Des 2025, 23:59');
  });

  test('batas hari dihitung per tanggal kalender, bukan per 24 jam', () {
    final lateNight = DateTime(2026, 11, 19, 0, 10);
    expect(formatTransactionTime(utc(2026, 11, 18, 23, 50), now: lateNight), 'Kemarin, 23:50');
  });
}
