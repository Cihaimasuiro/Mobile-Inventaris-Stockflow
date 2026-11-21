import '../entities/auth_session.dart';
import '../entities/inputs.dart';

abstract interface class AuthRepository {
  /// `null` = belum login. Emit nilai saat ini segera setelah di-listen.
  Stream<AuthSession?> watchSession();

  /// Throw: [ValidationException] (400), [UnauthorizedException] (401),
  /// [BusinessInactiveException] (403), [NetworkException].
  Future<AuthSession> login({required String identifier, required String password});

  /// API mengembalikan JWT, jadi register langsung login.
  /// Throw: [ValidationException], [ConflictException] (409: kode toko/email/HP sudah ada), [NetworkException].
  Future<AuthSession> register(RegisterInput input);

  /// Hapus token dan sesi. TIDAK menghapus data lokal.
  /// UI membaca `SyncRepository.watchSummary()` untuk memutuskan dialog peringatan (FR-02).
  Future<void> logout();
}
