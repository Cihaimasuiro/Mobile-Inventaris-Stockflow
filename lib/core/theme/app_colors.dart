import 'dart:ui';

/// Palet dari `docs/Mockup Visual High-Fidelity StokFlow UMKM (MVP).pdf` (warna fill asli PDF).
/// Hijau = barang masuk / aksi utama; oranye = barang keluar.
abstract final class AppColors {
  // Aksi utama dan barang masuk.
  static const Color primary = Color(0xFF00AA5B);
  static const Color primaryDark = Color(0xFF00880D);
  static const Color primaryText = Color(0xFF047857);
  static const Color primaryTint = Color(0xFFDCFCE7);
  static const Color primarySoft = Color(0xFFECFDF5);
  static const Color primaryLine = Color(0xFFBBF7D0);

  // Barang keluar.
  static const Color out = Color(0xFFFF5C00);
  static const Color outText = Color(0xFFEA580C);
  static const Color outTint = Color(0xFFFFF7ED);

  // Status sinkronisasi.
  static const Color pending = Color(0xFFFBBF24);
  static const Color pendingText = Color(0xFF92400E);
  static const Color pendingTint = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorTint = Color(0xFFFEE2E2);

  // Teks, garis, latar.
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color subtle = Color(0xFF94A3B8);
  static const Color line = Color(0xFFE2E8F0);
  static const Color lineStrong = Color(0xFFCBD5E1);
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
}
