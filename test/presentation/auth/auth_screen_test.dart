import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/dev/fakes/demo_seed.dart';
import 'package:stokflow/presentation/auth/auth_screen.dart';

import '../../support/pump_app.dart';

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  final finder = find.byKey(const Key('auth-submit'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openRegister(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab-register')));
  await tester.pumpAndSettle();
}

void main() {
  group('looksLikeEmailOrPhone', () {
    test('email dan nomor HP yang wajar dianggap valid', () {
      expect(looksLikeEmailOrPhone('budi@tokomajujaya.com'), isTrue);
      expect(looksLikeEmailOrPhone('0812-3456-7890'), isTrue);
      expect(looksLikeEmailOrPhone('+62 812 3456 7890'), isTrue);
    });

    test('teks lain tidak', () {
      for (final bad in ['', 'abc', 'budi@', '@toko.com', '12345', 'budi@toko']) {
        expect(looksLikeEmailOrPhone(bad), isFalse, reason: bad);
      }
    });
  });

  group('Masuk', () {
    testWidgets('belum login: tampil layar masuk sesuai mockup layar 01', (tester) async {
      await pumpApp(tester, loggedIn: false);

      expect(find.text('Atur stok toko\nsecepat scan barcode!'), findsOneWidget);
      expect(find.text('Tanpa ribet buku tulis, tetap jalan meski sinyal hilang.'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Baru'), findsOneWidget);
      expect(find.text('Nomor HP atau Email'), findsOneWidget);
      expect(find.text('PIN / Kata Sandi'), findsOneWidget);
      expect(find.text('Lanjut ke Toko Saya'), findsOneWidget);
      expect(find.text('100% Offline-First Ready'), findsOneWidget);
    });

    testWidgets('submit kosong menampilkan kesalahan per field dan tidak memanggil server', (tester) async {
      final h = await pumpApp(tester, loggedIn: false);

      await _submit(tester);

      expect(find.text('Nomor HP atau email wajib diisi.'), findsOneWidget);
      expect(find.text('PIN / kata sandi wajib diisi.'), findsOneWidget);
      expect(h.backend.session, isNull);
    });

    testWidgets('kata sandi salah menampilkan pesan dari server dan tetap di layar masuk', (tester) async {
      await pumpApp(tester, loggedIn: false);
      await _enter(tester, 'auth-identifier', 'budi@tokomajujaya.com');
      await _enter(tester, 'auth-password', 'salah');

      await _submit(tester);

      expect(find.byKey(const Key('auth-form-error')), findsOneWidget);
      expect(find.text('Identitas atau kata sandi salah.'), findsOneWidget);
      expect(find.text('Lanjut ke Toko Saya'), findsOneWidget);
    });

    testWidgets('login berhasil: auth guard mengarahkan ke beranda', (tester) async {
      final h = await pumpApp(tester, loggedIn: false);
      await _enter(tester, 'auth-identifier', '081234567890');
      await _enter(tester, 'auth-password', 'rahasia1');

      await _submit(tester);

      expect(h.backend.session, kDemoSession);
      expect(find.textContaining('Layar 02'), findsOneWidget);
      expect(find.byKey(const Key('auth-submit')), findsNothing);
    });

    testWidgets('tombol Tampilkan membuka dan menyembunyikan kata sandi', (tester) async {
      await pumpApp(tester, loggedIn: false);
      bool obscured() => tester.widget<TextField>(find.byKey(const Key('auth-password'))).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byKey(const Key('auth-toggle-password')));
      await tester.pump();
      expect(obscured(), isFalse);
      expect(find.text('Sembunyikan'), findsOneWidget);
    });

    testWidgets('lencana Valid hanya muncul untuk email atau nomor HP yang wajar', (tester) async {
      await pumpApp(tester, loggedIn: false);

      await _enter(tester, 'auth-identifier', 'abc');
      expect(find.text('Valid'), findsNothing);

      await _enter(tester, 'auth-identifier', '0812-3456-7890');
      expect(find.text('Valid'), findsOneWidget);
    });
  });

  group('Daftar Baru + buat toko', () {
    testWidgets('tab Daftar menampilkan nama pemilik, nama toko, dan kode toko', (tester) async {
      await pumpApp(tester, loggedIn: false);

      await _openRegister(tester);

      expect(find.byKey(const Key('auth-name')), findsOneWidget);
      expect(find.byKey(const Key('auth-business-name')), findsOneWidget);
      expect(find.byKey(const Key('auth-business-code')), findsOneWidget);
      expect(find.text('Buat Toko & Masuk'), findsOneWidget);
    });

    testWidgets('kode toko otomatis huruf besar, hanya huruf/angka, maksimal 10', (tester) async {
      await pumpApp(tester, loggedIn: false);
      await _openRegister(tester);

      await _enter(tester, 'auth-business-code', 'tmj-01x');
      String code() => tester.widget<TextField>(find.byKey(const Key('auth-business-code'))).controller!.text;
      expect(code(), 'TMJ01X');

      await _enter(tester, 'auth-business-code', 'abcdefghijklmnop');
      expect(code(), 'ABCDEFGHIJ');
    });

    testWidgets('submit kosong dan kode toko tidak valid menampilkan kesalahan', (tester) async {
      await pumpApp(tester, loggedIn: false);
      await _openRegister(tester);
      await _enter(tester, 'auth-business-code', 'A');

      await _submit(tester);

      expect(find.text('Nama pemilik wajib diisi.'), findsOneWidget);
      expect(find.text('Nama toko wajib diisi.'), findsOneWidget);
      expect(find.text('Kode toko 2-10 karakter, huruf besar atau angka.'), findsOneWidget);
    });

    testWidgets('kode toko yang sudah terdaftar (409) menampilkan pesan konflik', (tester) async {
      await pumpApp(tester, loggedIn: false);
      await _openRegister(tester);
      await _enter(tester, 'auth-name', 'Budi');
      await _enter(tester, 'auth-identifier', 'budi@toko.com');
      await _enter(tester, 'auth-password', 'rahasia1');
      await _enter(tester, 'auth-business-name', 'Toko Maju Jaya');
      await _enter(tester, 'auth-business-code', 'tmj01');

      await _submit(tester);

      expect(find.text('Kode toko, email, atau nomor HP sudah terdaftar.'), findsOneWidget);
    });

    testWidgets('daftar berhasil: toko baru dibuat dan langsung masuk ke beranda', (tester) async {
      final h = await pumpApp(tester, loggedIn: false);
      await _openRegister(tester);
      await _enter(tester, 'auth-name', 'Sari');
      await _enter(tester, 'auth-identifier', '081298765432');
      await _enter(tester, 'auth-password', 'rahasia1');
      await _enter(tester, 'auth-business-name', 'Warung Sari');
      await _enter(tester, 'auth-business-code', 'wrg77');

      await _submit(tester);

      expect(h.backend.session?.businessCode, 'WRG77');
      expect(h.backend.session?.businessName, 'Warung Sari');
      expect(find.textContaining('Layar 02'), findsOneWidget);
    });

    testWidgets('pindah tab membersihkan kesalahan sebelumnya', (tester) async {
      await pumpApp(tester, loggedIn: false);
      await _submit(tester);
      expect(find.text('Nomor HP atau email wajib diisi.'), findsOneWidget);

      await _openRegister(tester);

      expect(find.text('Nomor HP atau email wajib diisi.'), findsNothing);
    });
  });
}
