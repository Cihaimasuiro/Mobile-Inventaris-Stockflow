import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';

enum _LogoutChoice { cancel, syncFirst, logout }

/// Logout dengan peringatan data belum tersinkron (FR-02). Dipanggil dari Profil/Pengaturan (B).
///
/// Tanpa data tertunda -> langsung keluar. Dengan data PENDING/FAILED -> dialog: batal,
/// sinkronkan dulu, atau tetap keluar. Data lokal TIDAK dihapus saat logout; ia tersembunyi dan
/// terkirim saat login lagi dengan akun yang sama.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  // Nilai terbaru yang sudah dipancarkan stream. Layar pemanggil (Profil) menampilkan indikator
  // sync, jadi `syncSummaryProvider` aktif. Jika nilainya belum diketahui, anggap BELUM aman
  // dan tetap beri peringatan (lebih baik bertanya daripada kehilangan data).
  final summary = ref.read(syncSummaryProvider).value;
  if (summary != null && !summary.hasUnsynced) {
    await ref.read(authRepositoryProvider).logout();
    return;
  }
  if (!context.mounted) return;
  final status = summary == null
      ? 'Status sinkronisasi belum diketahui.'
      : '${summary.pendingCount} menunggu sinkron'
            '${summary.failedCount > 0 ? ' dan ${summary.failedCount} gagal' : ''}.';

  final choice = await showDialog<_LogoutChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('logout-warning'),
      title: const Text('Ada data belum tersinkron'),
      content: Text(
        '$status\n\n'
        'Data tetap tersimpan di HP dan akan terkirim saat Anda login lagi dengan akun yang sama. '
        'Jika HP rusak atau hilang sebelum itu, data ini ikut hilang.',
      ),
      actions: [
        TextButton(
          key: const Key('logout-cancel'),
          onPressed: () => Navigator.pop(dialogContext, _LogoutChoice.cancel),
          child: const Text('Batal'),
        ),
        TextButton(
          key: const Key('logout-sync'),
          onPressed: () => Navigator.pop(dialogContext, _LogoutChoice.syncFirst),
          child: const Text('Sinkronkan dulu'),
        ),
        TextButton(
          key: const Key('logout-confirm'),
          onPressed: () => Navigator.pop(dialogContext, _LogoutChoice.logout),
          child: const Text('Tetap keluar'),
        ),
      ],
    ),
  );

  switch (choice) {
    case _LogoutChoice.syncFirst:
      await ref.read(syncRepositoryProvider).syncNow();
    case _LogoutChoice.logout:
      await ref.read(authRepositoryProvider).logout();
    case _LogoutChoice.cancel || null:
      break;
  }
}
