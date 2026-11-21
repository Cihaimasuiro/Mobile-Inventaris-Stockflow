import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/presentation/history/transaction_tile.dart';

import '../../support/pump_app.dart';

void main() {
  // Data demo (urut sisip): t1 IN 2 produk (SYNCED), t2 OUT minyak (SYNCED), t3 OUT 2 produk (SYNCED),
  // t4 IN beras (PENDING), t5 OUT mie (FAILED).
  testWidgets('menampilkan satu baris per transaksi, terbaru dulu', (tester) async {
    final h = await pumpApp(tester);
    await h.openHistory();

    final ids = h.backend.transactions.map((t) => t.id).toList();
    expect(find.byType(TransactionTile), findsNWidgets(5));
    double top(String id) => tester.getTopLeft(find.byKey(ValueKey('tx-$id'))).dy;
    expect(top(ids[4]), lessThan(top(ids[3])));
    expect(top(ids[3]), lessThan(top(ids[2])));
    expect(top(ids[2]), lessThan(top(ids[1])));
    expect(top(ids[1]), lessThan(top(ids[0])));
  });

  testWidgets('transaksi multi-produk diringkas menjadi satu baris (FR-15)', (tester) async {
    final h = await pumpApp(tester);
    await h.openHistory();

    expect(find.text('Kopi Susu Gula Aren 250ml +1 lainnya'), findsNWidgets(2));
    expect(find.text('-5 unit'), findsOneWidget);
    expect(find.text('+30 unit'), findsOneWidget);
    expect(find.text('-5 pcs'), findsOneWidget);
    expect(find.text('+4 pack'), findsOneWidget);
    expect(find.text('-2 dus'), findsOneWidget);
  });

  testWidgets('nomor memakai format [KODE]-[TAHUN]-[URUT6] dan chip status tampil', (tester) async {
    final h = await pumpApp(tester);
    await h.openHistory();

    final numbers = h.backend.transactions.map((t) => t.number).toList();
    expect(numbers.first, matches(RegExp(r'^TMJ01-\d{4}-000001$')));
    expect(find.text(numbers.last), findsOneWidget);
    expect(find.text('SYNCED'), findsNWidgets(3));
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
  });

  testWidgets('filter Masuk (IN), Keluar (OUT), dan Semua', (tester) async {
    final h = await pumpApp(tester);
    await h.openHistory();

    await tester.tap(find.byKey(const Key('filter-in')));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('filter-out')));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsNWidgets(5));
  });

  testWidgets('belum ada transaksi: tampil keadaan kosong', (tester) async {
    final h = await pumpApp(tester, seeded: false);
    await h.openHistory();

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.byType(TransactionTile), findsNothing);
  });

  group('indikator sinkronisasi', () {
    testWidgets('menampilkan jumlah menunggu dan gagal, dengan aksi Coba lagi', (tester) async {
      final h = await pumpApp(tester);
      await h.openHistory();

      expect(find.text('1 menunggu sinkron • 1 gagal'), findsOneWidget);
      expect(find.byKey(const Key('sync-retry')), findsOneWidget);
    });

    testWidgets('Coba lagi mengirim ulang yang gagal; indikator hilang saat semua tersinkron', (tester) async {
      final h = await pumpApp(tester);
      await h.openHistory();

      await tester.tap(find.byKey(const Key('sync-retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync-status-line')), findsNothing);
      expect(find.text('FAILED'), findsNothing);
      expect(find.text('SYNCED'), findsNWidgets(5));
    });

    testWidgets('Sync Now mengirim yang PENDING, yang FAILED tetap menunggu Coba lagi', (tester) async {
      final h = await pumpApp(tester);
      await h.openHistory();

      await tester.tap(find.byKey(const Key('sync-now')));
      await tester.pumpAndSettle();

      expect(find.text('PENDING'), findsNothing);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('1 gagal'), findsOneWidget);
    });
  });

  testWidgets('mengetuk baris membuka detail transaksi', (tester) async {
    final h = await pumpApp(tester);
    await h.openHistory();
    final last = h.backend.transactions.last;

    await tester.tap(find.byKey(ValueKey('tx-${last.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.byKey(const Key('detail-number')), findsOneWidget);
  });

  testWidgets('tombol Scan di navigasi bawah membuka layar scanner (milik B)', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-scan')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Layar 04'), findsOneWidget);
  });
}
