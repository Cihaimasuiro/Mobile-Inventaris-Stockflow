/// Hirarki exception aplikasi. SATU file karena `sealed` mensyaratkan satu library.
///
/// Aturan: layer data/fake melempar tipe ini; UI menangkap [AppException] dan menampilkan
/// `messageOf(error)`. Jangan pernah menampilkan `error.toString()` ke pengguna.
library;

sealed class AppException implements Exception {
  const AppException(this.message);

  /// Pesan siap tampil (Bahasa Indonesia).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Pelanggaran aturan bisnis atau validasi input.
sealed class BusinessException extends AppException {
  const BusinessException(super.message);
}

final class InsufficientStockException extends BusinessException {
  InsufficientStockException({
    required this.productId,
    required this.productName,
    required this.available,
    required this.requested,
  }) : super('Stok $productName tidak mencukupi (tersisa $available, diminta $requested).');

  final String productId;
  final String productName;
  final int available;
  final int requested;
}

final class DuplicateBarcodeException extends BusinessException {
  DuplicateBarcodeException(this.barcode) : super('Barcode $barcode sudah dipakai produk lain.');

  final String barcode;
}

final class ProductArchivedException extends BusinessException {
  ProductArchivedException(this.productId) : super('Produk sudah diarsipkan dan tidak bisa dipakai.');

  final String productId;
}

final class BusinessInactiveException extends BusinessException {
  const BusinessInactiveException() : super('Layanan toko tidak aktif. Hubungi dukungan StokFlow.');
}

/// [fieldErrors]: nama field input -> pesan Indonesia. Kunci mengikuti nama field input
/// (mis. `name`, `sellingPrice`, `items`).
final class ValidationException extends BusinessException {
  ValidationException(this.fieldErrors)
    : super(fieldErrors.values.isEmpty ? 'Data tidak valid.' : fieldErrors.values.first);

  final Map<String, String> fieldErrors;
}

final class NotFoundException extends BusinessException {
  const NotFoundException([super.message = 'Data tidak ditemukan.']);
}

/// 409 saat register: kode toko, email, atau nomor HP sudah terdaftar.
final class ConflictException extends BusinessException {
  const ConflictException([super.message = 'Kode toko, email, atau nomor HP sudah terdaftar.']);
}

/// 401: login salah atau token tidak ada/tidak valid/kedaluwarsa.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sesi berakhir. Silakan login kembali.']);
}

/// Hanya dipakai di dalam layer data (auth/sync). Sync tidak melempar ini ke UI.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet.']);
}

final class UnexpectedException extends AppException {
  const UnexpectedException([super.message = 'Terjadi kesalahan tak terduga.', this.cause]);

  final Object? cause;
}
