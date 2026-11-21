import 'app_exception.dart';

/// Satu-satunya jalan error menjadi teks untuk pengguna.
String messageOf(Object error) {
  if (error is AppException) return error.message;
  return 'Terjadi kesalahan tak terduga.';
}

/// Teks untuk baris berstatus FAILED. [code] = `sync_error_code` dari server (kontrak 7.3).
String syncErrorMessage(String? code) {
  return switch (code) {
    'INSUFFICIENT_STOCK' => 'Stok di server tidak mencukupi.',
    'DUPLICATE_BARCODE' => 'Barcode sudah dipakai produk lain.',
    'PRODUCT_NOT_FOUND' => 'Produk tidak ditemukan di server.',
    'PRODUCT_ARCHIVED' => 'Produk sudah diarsipkan.',
    'BUSINESS_INACTIVE' => 'Layanan toko tidak aktif.',
    'VALIDATION' => 'Data ditolak server karena tidak valid.',
    null => 'Gagal sinkron.',
    _ => 'Gagal sinkron ($code).',
  };
}
