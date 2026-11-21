import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/storage/secure_session_store.dart';
import 'package:stokflow/domain/entities/auth_session.dart';

const _stored = StoredSession(
  token: 'aaa.bbb.ccc',
  session: AuthSession(
    userId: 'user-1',
    userName: 'Budi',
    businessId: 'biz-1',
    businessCode: 'TMJ01',
    businessName: 'Toko Maju Jaya',
  ),
);

void main() {
  group('SecureSessionStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('kosong -> null', () async {
      expect(await SecureSessionStore().read(), isNull);
    });

    test('save lalu read mengembalikan token dan profil yang sama', () async {
      final store = SecureSessionStore();

      await store.save(_stored);
      final read = await store.read();

      expect(read!.token, 'aaa.bbb.ccc');
      expect(read.session, _stored.session);
      expect(read.session.userName, 'Budi');
      expect(read.session.businessName, 'Toko Maju Jaya');
    });

    test('clear menghapus sesi', () async {
      final store = SecureSessionStore();
      await store.save(_stored);

      await store.clear();

      expect(await store.read(), isNull);
    });

    test('data rusak dianggap belum login dan dibuang (tidak crash berulang)', () async {
      FlutterSecureStorage.setMockInitialValues({SecureSessionStore.storageKey: '{bukan json'});
      final store = SecureSessionStore();

      expect(await store.read(), isNull);
      expect(await const FlutterSecureStorage().read(key: SecureSessionStore.storageKey), isNull);
    });

    test('JSON valid tapi field hilang juga dianggap rusak', () async {
      FlutterSecureStorage.setMockInitialValues({SecureSessionStore.storageKey: '{"token":"x"}'});

      expect(await SecureSessionStore().read(), isNull);
    });
  });

  test('InMemorySessionStore menyimpan dan menghapus tanpa menyentuh perangkat', () async {
    final store = InMemorySessionStore();
    expect(await store.read(), isNull);

    await store.save(_stored);
    expect((await store.read())!.token, 'aaa.bbb.ccc');

    await store.clear();
    expect(await store.read(), isNull);
  });
}
