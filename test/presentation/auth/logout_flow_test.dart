import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/dev/fakes/demo_seed.dart';
import 'package:stokflow/dev/fakes/fake_backend.dart';
import 'package:stokflow/dev/fakes/in_memory_auth_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_sync_repository.dart';
import 'package:stokflow/presentation/auth/logout_flow.dart';

/// Meniru layar Profil: menampilkan indikator sync (jadi `syncSummaryProvider` aktif) lalu logout.
/// [watchSummary] false = meniru pemanggil yang tidak mengamati provider (status belum diketahui).
class _Host extends ConsumerWidget {
  const _Host({this.watchSummary = true});

  final bool watchSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (watchSummary) ref.watch(syncSummaryProvider);
    return Scaffold(
      body: Center(
        child: TextButton(
          key: const Key('do-logout'),
          onPressed: () => confirmAndLogout(context, ref),
          child: const Text('Keluar'),
        ),
      ),
    );
  }
}

Future<FakeBackend> _pump(WidgetTester tester, {bool allSynced = false, bool watchSummary = true}) async {
  final backend = FakeBackend();
  await seedDemoData(backend); // 1 PENDING + 1 FAILED
  if (allSynced) backend.markAllSynced(kDemoSession.businessId);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(InMemoryAuthRepository(backend)),
        syncRepositoryProvider.overrideWithValue(InMemorySyncRepository(backend, backend.requireSession)),
      ],
      child: MaterialApp(home: _Host(watchSummary: watchSummary)),
    ),
  );
  await tester.pumpAndSettle(); // beri waktu stream sync memancarkan nilai pertamanya
  return backend;
}

Future<void> _tapLogout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('do-logout')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ada data belum tersinkron: peringatan dengan jumlahnya, Batal tidak keluar', (tester) async {
    final backend = await _pump(tester);

    await _tapLogout(tester);

    expect(find.byKey(const Key('logout-warning')), findsOneWidget);
    expect(find.textContaining('1 menunggu sinkron dan 1 gagal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logout-warning')), findsNothing);
    expect(backend.session, isNotNull);
  });

  testWidgets('Tetap keluar: sesi dihapus tetapi data lokal tidak dihapus', (tester) async {
    final backend = await _pump(tester);

    await _tapLogout(tester);
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(backend.session, isNull);
    expect(backend.transactions, isNotEmpty, reason: 'logout tidak menghapus data');
  });

  testWidgets('Sinkronkan dulu: mengirim yang PENDING dan tidak keluar', (tester) async {
    final backend = await _pump(tester);

    await _tapLogout(tester);
    await tester.tap(find.byKey(const Key('logout-sync')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(backend.session, isNotNull);
    expect(backend.transactions.where((t) => t.syncStatus.wire == 'PENDING'), isEmpty);
  });

  testWidgets('status sinkronisasi belum diketahui: tetap memberi peringatan (gagal aman)', (tester) async {
    final backend = await _pump(tester, allSynced: true, watchSummary: false);

    await _tapLogout(tester);

    expect(find.byKey(const Key('logout-warning')), findsOneWidget);
    expect(find.textContaining('Status sinkronisasi belum diketahui'), findsOneWidget);
    expect(backend.session, isNotNull);
  });

  testWidgets('semua tersinkron: langsung keluar tanpa peringatan', (tester) async {
    final backend = await _pump(tester, allSynced: true);

    await _tapLogout(tester);

    expect(find.byKey(const Key('logout-warning')), findsNothing);
    expect(backend.session, isNull);
  });
}
