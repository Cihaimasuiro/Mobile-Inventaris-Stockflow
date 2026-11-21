import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/sync_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Provider ABSTRAK. Implementasinya diisi lewat `ProviderScope(overrides: ...)` di
/// `main.dart` (asli) atau `dev/main_fake.dart` (fake). Layer presentation hanya
/// mengimpor file ini, tidak pernah `data/`.
Never _notWired(String name) =>
    throw UnimplementedError('$name belum di-override. Isi di main.dart atau dev/main_fake.dart.');

final authRepositoryProvider = Provider<AuthRepository>((ref) => _notWired('authRepositoryProvider'));
final productRepositoryProvider = Provider<ProductRepository>((ref) => _notWired('productRepositoryProvider'));
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => _notWired('transactionRepositoryProvider'),
);
final syncRepositoryProvider = Provider<SyncRepository>((ref) => _notWired('syncRepositoryProvider'));

/// Sesi aktif (`null` = belum login). Repository asli dibuat per sesi dari nilai ini.
final sessionProvider = StreamProvider<AuthSession?>((ref) => ref.watch(authRepositoryProvider).watchSession());

/// Status sinkronisasi untuk badge, dialog logout, dan loader initial pull.
final syncSummaryProvider = StreamProvider<SyncSummary>((ref) => ref.watch(syncRepositoryProvider).watchSummary());
