import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../core/di/providers.dart';
import 'fakes/demo_seed.dart';
import 'fakes/fake_backend.dart';
import 'fakes/in_memory_auth_repository.dart';
import 'fakes/in_memory_product_repository.dart';
import 'fakes/in_memory_sync_repository.dart';
import 'fakes/in_memory_transaction_repository.dart';

/// Entry point untuk B: UI penuh tanpa Drift/Dio/jaringan.
///
///   flutter run -t lib/dev/main_fake.dart
///
/// Data awal: toko TMJ01 (sudah login). Login uji: password apa pun (>= 6 karakter);
/// password `salah` memicu UnauthorizedException.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = FakeBackend();
  await seedDemoData(backend);

  runApp(
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
}
