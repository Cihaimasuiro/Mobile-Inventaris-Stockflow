import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';
import 'package:stokflow/core/utils/date_formatter.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';
import 'package:stokflow/presentation/shared/status_chip.dart';

/// Satu baris per TRANSAKSI (bukan per produk): satu transaksi bisa berisi banyak produk (FR-15).
/// Satu item: nama produk dan `-5 pcs`. Banyak item: `Nama +N lainnya` dan `-7 unit`.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, required this.onTap, super.key});

  final StockTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final first = t.items.isEmpty ? null : t.items.first;
    final title = first == null
        ? '-'
        : t.itemCount == 1
        ? first.productName
        : '${first.productName} +${t.itemCount - 1} lainnya';
    final quantity = first == null
        ? ''
        : t.itemCount == 1
        ? '${t.type.sign}${first.quantity} ${first.unit}'
        : '${t.type.sign}${t.totalQuantity} unit';

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: t.type.tint, borderRadius: BorderRadius.circular(10)),
                  child: Icon(t.type.isIn ? Icons.arrow_downward : Icons.arrow_upward, color: t.type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      // Wrap, bukan Row: saat sempit (teks besar/nomor panjang) chip turun ke baris berikutnya.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(t.number, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          SyncStatusChip(status: t.syncStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      quantity,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t.type.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatTransactionTime(t.transactionAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.subtle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
