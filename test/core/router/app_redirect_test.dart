import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/dev/fakes/demo_seed.dart';

void main() {
  const loggedIn = AsyncData(kDemoSession);
  const loggedOut = AsyncData<Null>(null);

  group('appRedirect (auth guard)', () {
    test('sesi belum diketahui -> splash, dan tetap di splash', () {
      const loading = AsyncLoading<Null>();
      expect(appRedirect(session: loading, location: AppRoutes.home), AppRoutes.splash);
      expect(appRedirect(session: loading, location: AppRoutes.splash), isNull);
    });

    test('belum login -> semua halaman diarahkan ke login', () {
      expect(appRedirect(session: loggedOut, location: AppRoutes.home), AppRoutes.login);
      expect(appRedirect(session: loggedOut, location: AppRoutes.history), AppRoutes.login);
      expect(appRedirect(session: loggedOut, location: AppRoutes.login), isNull);
    });

    test('sudah login -> login dan splash diarahkan ke beranda, halaman lain dibiarkan', () {
      expect(appRedirect(session: loggedIn, location: AppRoutes.login), AppRoutes.home);
      expect(appRedirect(session: loggedIn, location: AppRoutes.splash), AppRoutes.home);
      expect(appRedirect(session: loggedIn, location: AppRoutes.history), isNull);
      expect(appRedirect(session: loggedIn, location: AppRoutes.transaction('x')), isNull);
    });

    test('error membaca sesi diperlakukan sebagai belum login', () {
      final error = AsyncError<Null>('gagal', StackTrace.empty);
      expect(appRedirect(session: error, location: AppRoutes.home), AppRoutes.login);
    });
  });

  test('detail transaksi berada di bawah riwayat dan path tidak memakai /v1', () {
    expect(AppRoutes.transaction('abc'), '/history/abc');
    expect(AppRoutes.product('p1'), '/products/p1');
  });
}
