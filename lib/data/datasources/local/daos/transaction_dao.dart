import 'dart:async';

import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/products.dart';
import '../tables/stock_transaction_items.dart';
import '../tables/stock_transactions.dart';

part 'transaction_dao.g.dart';

class ItemView {
  const ItemView(this.item, this.product);

  final StockTransactionItemRow item;
  final ProductRow product;
}

class TransactionView {
  const TransactionView(this.header, this.items);

  final StockTransactionRow header;
  final List<ItemView> items;
}

/// Semua method WAJIB menerima `businessId` sebagai parameter pertama (isolasi multi-bisnis).
@DriftAccessor(tables: [StockTransactions, StockTransactionItems, Products])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  /// Urutan berikutnya untuk prefix `TMJ01-2026-` (dihitung dari data, bukan counter terpisah).
  /// Harus dipanggil di dalam transaksi DB yang sama dengan penyimpanan.
  Future<int> nextSequence(String businessId, String prefix) async {
    final row = await customSelect(
      'SELECT COALESCE(MAX(CAST(SUBSTR(transaction_number, ?) AS INTEGER)), 0) + 1 AS next_seq '
      'FROM stock_transactions WHERE business_id = ? AND SUBSTR(transaction_number, 1, ?) = ?',
      variables: [
        Variable.withInt(prefix.length + 1),
        Variable.withString(businessId),
        Variable.withInt(prefix.length),
        Variable.withString(prefix),
      ],
      readsFrom: {stockTransactions},
    ).getSingle();
    return row.read<int>('next_seq');
  }

  Future<void> insertHeader(StockTransactionsCompanion row) => into(stockTransactions).insert(row);

  Future<void> insertItem(StockTransactionItemsCompanion row) => into(stockTransactionItems).insert(row);

  /// Terbaru dulu: transactionAt DESC, createdAt DESC, urutan sisip DESC.
  Future<List<TransactionView>> list(String businessId, {TransactionType? type, int limit = 100}) async {
    final q = select(stockTransactions)..where((t) => t.businessId.equals(businessId));
    if (type != null) q.where((t) => t.type.equalsValue(type));
    q
      ..orderBy([
        (t) => OrderingTerm.desc(t.transactionAt),
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(const CustomExpression<int>('stock_transactions.rowid')),
      ])
      ..limit(limit);
    return _withItems(businessId, await q.get());
  }

  Future<TransactionView?> getView(String businessId, String id) async {
    final header = await (select(
      stockTransactions,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).getSingleOrNull();
    if (header == null) return null;
    return (await _withItems(businessId, [header])).single;
  }

  Stream<List<TransactionView>> watchList(String businessId, {TransactionType? type, int limit = 100}) =>
      _watchLoaded(() => list(businessId, type: type, limit: limit));

  Stream<TransactionView?> watchView(String businessId, String id) => _watchLoaded(() => getView(businessId, id));

  Future<List<TransactionView>> _withItems(String businessId, List<StockTransactionRow> headers) async {
    if (headers.isEmpty) return const [];
    final rows =
        await (select(stockTransactionItems)
                .join([innerJoin(products, products.id.equalsExp(stockTransactionItems.productId))])
              ..where(
                stockTransactionItems.businessId.equals(businessId) &
                    stockTransactionItems.transactionId.isIn(headers.map((h) => h.id)),
              )
              ..orderBy([OrderingTerm.asc(const CustomExpression<int>('stock_transaction_items.rowid'))]))
            .get();

    final byTransaction = <String, List<ItemView>>{};
    for (final row in rows) {
      final item = row.readTable(stockTransactionItems);
      byTransaction.putIfAbsent(item.transactionId, () => []).add(ItemView(item, row.readTable(products)));
    }
    return [for (final h in headers) TransactionView(h, byTransaction[h.id] ?? const [])];
  }

  /// Stream yang dimuat ulang (berurutan) setiap tabel terkait berubah. Memuat ulang juga saat
  /// nama/satuan produk berubah, karena item membawa nama produk.
  Stream<T> _watchLoaded<T>(Future<T> Function() load) {
    late StreamController<T> controller;
    StreamSubscription<Set<TableUpdate>>? sub;
    var chain = Future<void>.value();

    void emit() {
      chain = chain.then((_) async {
        if (controller.isClosed) return;
        try {
          controller.add(await load());
        } on Object catch (error, stack) {
          controller.addError(error, stack);
        }
      });
    }

    controller = StreamController<T>(
      onListen: () {
        sub = db
            .tableUpdates(TableUpdateQuery.onAllTables([stockTransactions, stockTransactionItems, products]))
            .listen((_) => emit());
        emit();
      },
      onCancel: () async => sub?.cancel(),
    );
    return controller.stream;
  }
}
