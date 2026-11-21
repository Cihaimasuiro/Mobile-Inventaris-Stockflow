import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/presentation/auth/auth_screen.dart';
import 'package:stokflow/presentation/history/history_screen.dart';
import 'package:stokflow/presentation/history/transaction_detail_screen.dart';
import 'package:stokflow/presentation/shared/app_shell.dart';
import 'package:stokflow/presentation/shared/placeholder_screen.dart';

/// Semua route aplikasi. Layar milik B dipasang sebagai placeholder: B cukup mengganti
/// `builder` di [routerProvider] dengan layar aslinya, path tidak berubah.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String history = '/history';
  static const String scan = '/scan';
  static const String newProduct = '/products/new';
  static const String newTransaction = '/transactions/new';

  static String product(String id) => '/products/$id';

  static String transaction(String id) => '$history/$id';
}

/// Auth guard (murni agar mudah dites): belum tahu sesi -> splash; belum login -> login;
/// sudah login tapi di login/splash -> beranda.
String? appRedirect({required AsyncValue<AuthSession?> session, required String location}) {
  if (session.isLoading && !session.hasValue) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final loggedIn = session.value != null;
  if (!loggedIn) return location == AppRoutes.login ? null : AppRoutes.login;
  if (location == AppRoutes.login || location == AppRoutes.splash) return AppRoutes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(session: ref.read(sessionProvider), location: state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _Splash()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const PlaceholderScreen(title: 'Beranda & Katalog', screenNumber: '02', owner: 'B'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.history, builder: (_, _) => const HistoryScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.history}/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) => TransactionDetailScreen(transactionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.scan,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const PlaceholderScreen(title: 'Scanner Kamera', screenNumber: '04', owner: 'B'),
      ),
      GoRoute(
        path: AppRoutes.newProduct,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const PlaceholderScreen(title: 'Tambah Produk', screenNumber: '03', owner: 'B'),
      ),
      GoRoute(
        path: '/products/:id',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const PlaceholderScreen(title: 'Detail & Edit Produk', screenNumber: '07', owner: 'B'),
      ),
      GoRoute(
        path: AppRoutes.newTransaction,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const PlaceholderScreen(title: 'Catat Transaksi', screenNumber: '05', owner: 'B'),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
