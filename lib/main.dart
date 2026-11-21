import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/storage/app_database.dart';
import 'data/repositories/drift_product_repository.dart';
import 'data/repositories/drift_transaction_repository.dart';
import 'domain/entities/auth_session.dart';

/// Repository asli dibuat PER SESI: bisnis dan pengguna datang dari [AuthSession],
/// bukan parameter method. Saat sesi berubah, provider ini dibangun ulang otomatis.
AuthSession _requireSession(Ref ref) =>
    ref.watch(sessionProvider).requireValue ?? (throw StateError('Repository diminta saat belum login.'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        // TODO(A): authRepositoryProvider dan syncRepositoryProvider diisi setelah bentuk
        // response login/sync backend terverifikasi (capture-api-samples). Sampai itu,
        // jalankan UI dengan `flutter run -t lib/dev/main_fake.dart`.
        productRepositoryProvider.overrideWith((ref) => DriftProductRepository(db, _requireSession(ref))),
        transactionRepositoryProvider.overrideWith((ref) => DriftTransactionRepository(db, _requireSession(ref))),
      ],
      child: const StokflowApp(),
    ),
  );
}
