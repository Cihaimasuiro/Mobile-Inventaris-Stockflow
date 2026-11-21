import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/core/errors/error_messages.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';
import 'package:stokflow/core/utils/date_formatter.dart';
import 'package:stokflow/core/utils/rupiah_formatter.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';
import 'package:stokflow/presentation/history/history_providers.dart';
import 'package:stokflow/presentation/shared/status_chip.dart';

/// Layar 08: Detail Transaksi (FR-17, FR-21). Nomor, status sinkronisasi (dengan aksi Coba lagi
/// untuk FAILED), rincian barang beserta harga modal saat transaksi, catatan, pencatat, waktu.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  void _back(BuildContext context) => context.canPop() ? context.pop() : context.go(AppRoutes.history);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(transactionDetailProvider(transactionId));
    final value = transaction.value;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _back(context)),
        title: const Text('Detail Transaksi'),
        actions: [
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SyncStatusChip(status: value.syncStatus),
            ),
        ],
      ),
      body: transaction.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(messageOf(error))),
        data: (t) => t == null
            ? Center(
                child: Text(
                  'Transaksi tidak ditemukan.',
                  key: const Key('detail-not-found'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : _DetailBody(transaction: t, onBack: () => _back(context)),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.transaction, required this.onBack});

  final StockTransaction transaction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final session = ref.watch(sessionProvider).value;
    final recordedBy = session != null && session.userId == t.createdBy
        ? '${session.userName} (Owner)'
        : 'Pengguna lain';
    final sign = t.type.sign;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: t.type.tint, borderRadius: BorderRadius.circular(kRadius)),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${t.type.label}  ',
                  style: TextStyle(color: t.type.textColor, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: '#${t.number}',
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            key: const Key('detail-number'),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        _SyncInfo(transaction: t),
        const SizedBox(height: 16),
        Text('Rincian Barang (${t.itemCount} Item)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _Card(
          children: [
            for (var i = 0; i < t.items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.line),
              _ItemRow(item: t.items[i], type: t.type),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _Card(
          children: [
            if ((t.notes ?? '').trim().isNotEmpty) _InfoRow(label: 'Catatan', value: t.notes!.trim()),
            _InfoRow(label: 'Total Item & Unit', value: '${t.itemCount} Produk • $sign${t.totalQuantity} Unit'),
            _InfoRow(label: 'Dicatat Oleh', value: recordedBy),
            _InfoRow(label: 'Waktu Kejadian', value: formatFullDateTime(t.transactionAt)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(key: const Key('detail-back'), onPressed: onBack, child: const Text('Kembali ke Riwayat')),
      ],
    );
  }
}

class _SyncInfo extends ConsumerWidget {
  const _SyncInfo({required this.transaction});

  final StockTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final (background, color, message) = switch (t.syncStatus) {
      SyncStatus.synced => (AppColors.primarySoft, AppColors.primaryText, 'Tersinkron ke Cloud Server'),
      SyncStatus.pending => (AppColors.pendingTint, AppColors.pendingText, 'Menunggu sinkronisasi. Data aman di HP.'),
      SyncStatus.failed => (
        AppColors.errorTint,
        AppColors.error,
        'Ditolak server: ${syncErrorMessage(t.syncErrorCode)}',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(kRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            key: const Key('detail-sync-message'),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          SelectableText('ID: ${t.id}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          if (t.syncStatus == SyncStatus.failed) ...[
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('detail-retry'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kMinTouchTarget),
                backgroundColor: AppColors.error,
              ),
              onPressed: () => ref.read(syncRepositoryProvider).retryFailed(),
              child: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: children),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.type});

  final StockTransactionItem item;
  final TransactionType type;

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _initials(item.productName),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Modal: ${formatRupiah(item.unitCostSnapshot)}/${item.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '${type.sign}${item.quantity} ${item.unit}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: type.textColor),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
