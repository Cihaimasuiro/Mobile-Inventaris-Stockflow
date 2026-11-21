import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/domain/entities/enums.dart';

/// Chip status sinkronisasi: SYNCED (hijau), PENDING (amber), FAILED (merah).
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({required this.status, super.key});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      SyncStatus.synced => (AppColors.primaryTint, AppColors.primaryText),
      SyncStatus.pending => (AppColors.pendingTint, AppColors.pendingText),
      SyncStatus.failed => (AppColors.errorTint, AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.wire,
        style: TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

/// Warna dan tanda jenis transaksi: masuk = hijau (+), keluar = oranye (-).
extension TransactionTypeStyle on TransactionType {
  bool get isIn => this == TransactionType.stockIn;

  String get sign => isIn ? '+' : '-';

  String get label => isIn ? 'BARANG MASUK' : 'BARANG KELUAR';

  Color get color => isIn ? AppColors.primary : AppColors.out;

  Color get textColor => isIn ? AppColors.primaryText : AppColors.outText;

  Color get tint => isIn ? AppColors.primaryTint : AppColors.outTint;
}
