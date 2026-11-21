import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stokflow/domain/entities/auth_session.dart';

/// Token JWT + profil sesi. Token hanya hidup di layer data; UI hanya melihat [AuthSession].
class StoredSession {
  const StoredSession({required this.token, required this.session});

  final String token;
  final AuthSession session;
}

abstract interface class SessionStore {
  Future<StoredSession?> read();

  Future<void> save(StoredSession stored);

  Future<void> clear();
}

/// Penyimpanan aman (Android Keystore / iOS Keychain) untuk satu sesi aktif.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'stokflow.session.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSession(
        token: map['token'] as String,
        session: AuthSession(
          userId: map['userId'] as String,
          userName: map['userName'] as String,
          businessId: map['businessId'] as String,
          businessCode: map['businessCode'] as String,
          businessName: map['businessName'] as String,
        ),
      );
    } on Object {
      // Data rusak/format lama: anggap belum login dan buang, supaya tidak crash berulang.
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(StoredSession stored) => _storage.write(
    key: storageKey,
    value: jsonEncode({
      'token': stored.token,
      'userId': stored.session.userId,
      'userName': stored.session.userName,
      'businessId': stored.session.businessId,
      'businessCode': stored.session.businessCode,
      'businessName': stored.session.businessName,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}

/// Untuk tes dan fake. Tidak menyimpan apa pun ke perangkat.
class InMemorySessionStore implements SessionStore {
  StoredSession? _stored;

  @override
  Future<StoredSession?> read() async => _stored;

  @override
  Future<void> save(StoredSession stored) async => _stored = stored;

  @override
  Future<void> clear() async => _stored = null;
}
