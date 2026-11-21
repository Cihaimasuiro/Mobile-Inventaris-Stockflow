/// Helper tes UI: menjalankan seluruh aplikasi (tema, router, auth guard) di atas fake in-memory.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stokflow/app.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/dev/fakes/demo_seed.dart';
import 'package:stokflow/dev/fakes/fake_backend.dart';
import 'package:stokflow/dev/fakes/in_memory_auth_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_product_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_sync_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_transaction_repository.dart';

class AppHarness {
  AppHarness(this.tester, this.backend);

  final WidgetTester tester;
  final FakeBackend backend;

  GoRouter get router => ProviderScope.containerOf(tester.element(find.byType(StokflowApp))).read(routerProvider);

  /// Buka tab Riwayat lewat navigasi bawah.
  Future<void> openHistory() async {
    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
  }
}

/// [seeded]: isi data demo (5 transaksi, 1 PENDING, 1 FAILED). [loggedIn]: sudah punya sesi.
Future<AppHarness> pumpApp(WidgetTester tester, {bool seeded = true, bool loggedIn = true}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final backend = FakeBackend();
  if (seeded) {
    await seedDemoData(backend);
  } else {
    backend.session = kDemoSession;
  }
  if (!loggedIn) backend.session = null;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(InMemoryAuthRepository(backend)),
        productRepositoryProvider.overrideWithValue(InMemoryProductRepository(backend, backend.requireSession)),
        transactionRepositoryProvider.overrideWithValue(InMemoryTransactionRepository(backend, backend.requireSession)),
        syncRepositoryProvider.overrideWithValue(InMemorySyncRepository(backend, backend.requireSession)),
      ],
      child: const StokflowApp(),
    ),
  );
  await tester.pumpAndSettle();
  return AppHarness(tester, backend);
}
