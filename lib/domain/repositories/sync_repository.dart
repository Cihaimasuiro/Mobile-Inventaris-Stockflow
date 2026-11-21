import '../entities/sync_summary.dart';

abstract interface class SyncRepository {
  /// Emit nilai saat ini segera setelah di-listen, lalu setiap ada perubahan.
  Stream<SyncSummary> watchSummary();

  /// Push lalu pull. Hanya satu siklus berjalan sekaligus.
  /// Error jaringan TIDAK dilempar: hasilnya tercermin di [SyncSummary].
  Future<void> syncNow();

  /// Ubah semua baris FAILED menjadi PENDING (hapus kode error), lalu [syncNow].
  Future<void> retryFailed();
}
