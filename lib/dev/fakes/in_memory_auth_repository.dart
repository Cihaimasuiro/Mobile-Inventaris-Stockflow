import '../../core/errors/app_exception.dart';
import '../../core/utils/transaction_number.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/inputs.dart';
import '../../domain/repositories/auth_repository.dart';
import 'demo_seed.dart';
import 'fake_backend.dart';

/// Fake AuthRepository. Login uji: password apa pun >= 6 karakter berhasil sebagai toko demo;
/// password `salah` -> UnauthorizedException. Register dengan kode `TMJ01` -> ConflictException.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository(this._backend);

  final FakeBackend _backend;

  @override
  Stream<AuthSession?> watchSession() => _backend.watch(() => _backend.session);

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    final errors = <String, String>{
      if (identifier.trim().isEmpty) 'identifier': 'Email atau nomor HP wajib diisi.',
      if (password.isEmpty) 'password': 'Password wajib diisi.',
    };
    if (errors.isNotEmpty) throw ValidationException(errors);
    if (password == 'salah' || password.length < 6) {
      throw const UnauthorizedException('Identitas atau kata sandi salah.');
    }
    if (_backend.statusOf(kDemoSession.businessId) != BusinessStatus.active) {
      throw const BusinessInactiveException();
    }
    _backend.session = kDemoSession;
    _backend.notify();
    return kDemoSession;
  }

  @override
  Future<AuthSession> register(RegisterInput input) async {
    final errors = <String, String>{
      if (input.name.trim().isEmpty) 'name': 'Nama wajib diisi.',
      if (input.identifier.trim().isEmpty) 'identifier': 'Email atau nomor HP wajib diisi.',
      if (input.password.length < 6) 'password': 'Password minimal 6 karakter.',
      if (input.businessName.trim().isEmpty) 'businessName': 'Nama toko wajib diisi.',
      if (!isValidBusinessCode(input.businessCode)) 'businessCode': 'Kode toko 2-10 karakter huruf besar atau angka.',
    };
    if (errors.isNotEmpty) throw ValidationException(errors);
    if (input.businessCode == kDemoSession.businessCode) throw const ConflictException();

    final session = AuthSession(
      userId: _backend.ids.newId(),
      userName: input.name.trim(),
      businessId: _backend.ids.newId(),
      businessCode: input.businessCode,
      businessName: input.businessName.trim(),
    );
    _backend.session = session;
    _backend.notify();
    return session;
  }

  @override
  Future<void> logout() async {
    _backend.session = null;
    _backend.notify();
  }
}
