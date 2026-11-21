import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/core/theme/app_theme.dart';

/// Root aplikasi: tema dari mockup + router dengan auth guard (lihat `core/router/app_router.dart`).
/// Dipanggil oleh `main.dart` dan `dev/main_fake.dart`.
class StokflowApp extends ConsumerWidget {
  const StokflowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'StokFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
