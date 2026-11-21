import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/sync_summary.dart';

/// Teks ringkas status sinkronisasi, atau `null` jika semua aman (tidak ada yang ditampilkan).
String? syncStatusMessage(SyncSummary s) {
  if (s.issue == SyncIssue.authRequired) return 'Sesi berakhir. Login ulang untuk melanjutkan sinkronisasi.';
  if (s.issue == SyncIssue.businessInactive) return 'Layanan toko tidak aktif. Sinkronisasi dihentikan.';
  if (s.isOffline && s.pendingCount > 0) return 'Offline. ${s.pendingCount} data akan dikirim saat online.';
  if (s.isOffline) return 'Offline. Data tetap tersimpan di HP.';
  final parts = [
    if (s.pendingCount > 0) '${s.pendingCount} menunggu sinkron',
    if (s.failedCount > 0) '${s.failedCount} gagal',
  ];
  return parts.isEmpty ? null : parts.join(' • ');
}

/// Indikator Sync/Pending (FR-19): baris kecil di bawah header. Hilang saat semua tersinkron.
/// Jika ada yang FAILED, menampilkan aksi "Coba lagi".
class SyncStatusLine extends ConsumerWidget {
  const SyncStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(syncSummaryProvider).value;
    final message = summary == null ? null : syncStatusMessage(summary);
    if (summary == null || message == null) return const SizedBox.shrink();

    final problem = summary.failedCount > 0 || summary.issue != null;
    final color = problem ? AppColors.error : AppColors.pendingText;
    return Container(
      key: const Key('sync-status-line'),
      width: double.infinity,
      color: problem ? AppColors.errorTint : AppColors.pendingTint,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: kMinTouchTarget),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (summary.failedCount > 0)
            TextButton(
              key: const Key('sync-retry'),
              onPressed: () => ref.read(syncRepositoryProvider).retryFailed(),
              child: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}
