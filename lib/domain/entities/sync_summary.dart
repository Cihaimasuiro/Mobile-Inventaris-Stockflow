import 'enums.dart';

/// Ringkasan status sinkronisasi untuk UI (badge, dialog logout FR-02, loader initial pull).
class SyncSummary {
  const SyncSummary({
    this.pendingCount = 0,
    this.failedCount = 0,
    this.isSyncing = false,
    this.isOffline = false,
    this.initialPullDone = false,
    this.lastSyncedAt,
    this.issue,
  });

  /// Produk + transaksi yang belum diterima server.
  final int pendingCount;

  /// Produk + transaksi yang ditolak server dan butuh "Coba lagi".
  final int failedCount;
  final bool isSyncing;
  final bool isOffline;

  /// `false` sampai pull pertama selesai: UI menampilkan loader penuh atau tombol "Coba lagi".
  final bool initialPullDone;
  final DateTime? lastSyncedAt;
  final SyncIssue? issue;

  /// FR-02: ada data yang belum aman di server.
  bool get hasUnsynced => pendingCount > 0 || failedCount > 0;
}
