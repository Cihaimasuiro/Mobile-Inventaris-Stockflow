import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/router/app_router.dart';

import '../../support/pump_app.dart';

void main() {
  // Data demo (urut sisip): t3 OUT 2 produk SYNCED (catatan "Pelanggan tetap"), t5 OUT mie FAILED.
  Future<AppHarness> openDetail(WidgetTester tester, int index) async {
    final h = await pumpApp(tester);
    h.router.go(AppRoutes.transaction(h.backend.transactions[index].id));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('transaksi SYNCED: nomor, rincian barang, modal per satuan, total, pencatat, waktu', (tester) async {
    final h = await openDetail(tester, 2);
    final t = h.backend.transactions[2];

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.textContaining('BARANG KELUAR'), findsOneWidget);
    expect(find.textContaining('#${t.number}'), findsOneWidget);
    expect(find.text('Tersinkron ke Cloud Server'), findsOneWidget);
    expect(find.textContaining('ID: ${t.id}'), findsOneWidget);

    expect(find.text('Rincian Barang (2 Item)'), findsOneWidget);
    expect(find.text('Kopi Susu Gula Aren 250ml'), findsOneWidget);
    expect(find.text('Modal: Rp8.500/pcs'), findsOneWidget);
    expect(find.text('Gula Pasir 1kg'), findsOneWidget);
    expect(find.text('Modal: Rp15.000/kg'), findsOneWidget);
    expect(find.text('-3 pcs'), findsOneWidget);
    expect(find.text('-2 kg'), findsOneWidget);

    expect(find.text('Pelanggan tetap'), findsOneWidget);
    expect(find.text('2 Produk • -5 Unit'), findsOneWidget);
    expect(find.text('Budi Santoso (Owner)'), findsOneWidget);
    expect(find.text('Waktu Kejadian'), findsOneWidget);
  });

  testWidgets('transaksi masuk memakai tanda + dan label BARANG MASUK', (tester) async {
    await openDetail(tester, 0);

    expect(find.textContaining('BARANG MASUK'), findsOneWidget);
    expect(find.text('+10 pcs'), findsOneWidget);
    expect(find.text('+20 pcs'), findsOneWidget);
    expect(find.text('Restock mingguan'), findsOneWidget);
    expect(find.text('2 Produk • +30 Unit'), findsOneWidget);
  });

  testWidgets('transaksi PENDING menjelaskan data aman di HP dan tanpa tombol Coba lagi', (tester) async {
    await openDetail(tester, 3);

    expect(find.text('Menunggu sinkronisasi. Data aman di HP.'), findsOneWidget);
    expect(find.byKey(const Key('detail-retry')), findsNothing);
  });

  testWidgets('transaksi FAILED menampilkan alasan server dan Coba lagi mengirim ulang', (tester) async {
    await openDetail(tester, 4);

    expect(find.text('Ditolak server: Stok di server tidak mencukupi.'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);

    await tester.tap(find.byKey(const Key('detail-retry')));
    // Layar detail tidak punya animasi, jadi pumpAndSettle tidak menunggu timer sync fake (300 ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Tersinkron ke Cloud Server'), findsOneWidget);
    expect(find.byKey(const Key('detail-retry')), findsNothing);
  });

  testWidgets('Kembali ke Riwayat membuka daftar riwayat', (tester) async {
    await openDetail(tester, 2);

    final back = find.byKey(const Key('detail-back'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Stok'), findsOneWidget);
  });

  testWidgets('id tidak dikenal menampilkan pesan, bukan crash', (tester) async {
    final h = await pumpApp(tester);

    h.router.go(AppRoutes.transaction('tidak-ada'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-not-found')), findsOneWidget);
  });
}
