import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/core/errors/error_messages.dart';
import 'package:stokflow/core/router/app_router.dart';
import 'package:stokflow/core/theme/app_colors.dart';
import 'package:stokflow/core/theme/app_theme.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/presentation/history/history_providers.dart';
import 'package:stokflow/presentation/history/transaction_tile.dart';
import 'package:stokflow/presentation/shared/sync_status_line.dart';

/// Layar 06: Riwayat dan Sync (FR-19 sampai FR-22). Terbaru dulu, filter jenis, tombol Sync Now,
/// dan indikator PENDING/FAILED.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// `null` = ALL.
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Stok'), actions: const [_SyncNowButton(), SizedBox(width: 12)]),
      body: Column(
        children: [
          const SyncStatusLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _FilterBar(selected: _filter, onChanged: (type) => setState(() => _filter = type)),
          ),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(messageOf(error))),
              data: (items) => items.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => TransactionTile(
                        key: ValueKey('tx-${items[index].id}'),
                        transaction: items[index],
                        onTap: () => context.push(AppRoutes.transaction(items[index].id)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(Key key, String label, TransactionType? value) {
      final isSelected = selected == value;
      return ChoiceChip(
        key: key,
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.line),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.white : AppColors.inkSoft,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        pill(const Key('filter-all'), 'Semua', null),
        pill(const Key('filter-in'), 'Masuk (IN)', TransactionType.stockIn),
        pill(const Key('filter-out'), 'Keluar (OUT)', TransactionType.stockOut),
      ],
    );
  }
}

class _SyncNowButton extends ConsumerWidget {
  const _SyncNowButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(syncSummaryProvider).value?.isSyncing ?? false;
    return OutlinedButton(
      key: const Key('sync-now'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, kMinTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      onPressed: syncing ? null : () => ref.read(syncRepositoryProvider).syncNow(),
      child: syncing
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Sync Now'),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Belum ada transaksi.',
        key: const Key('history-empty'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
