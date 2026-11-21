import 'package:clock/clock.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/transaction_number.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/inputs.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/validation/new_transaction_validator.dart';
import 'fake_backend.dart';

/// Fake TransactionRepository. Perilaku HARUS identik dengan implementasi Drift
/// (dijaga oleh `test/contract/repository_contract.dart`).
class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository(this._backend, this._session);

  final FakeBackend _backend;
  final AuthSession Function() _session;

  @override
  Stream<List<StockTransaction>> watchTransactions({TransactionType? type, int limit = 100}) =>
      _backend.watch(() => _list(type, limit));

  @override
  Stream<StockTransaction?> watchTransaction(String id) => _backend.watch(() {
    for (final t in _backend.transactions) {
      if (t.businessId == _session().businessId && t.id == id) return t;
    }
    return null;
  });

  @override
  Future<StockTransaction> createTransaction(NewTransaction input) async {
    final session = _session();
    if (_backend.statusOf(session.businessId) != BusinessStatus.active) {
      throw const BusinessInactiveException();
    }
    final errors = validateNewTransaction(input);
    if (errors.isNotEmpty) throw ValidationException(errors);

    final merged = mergeTransactionItems(input.items);
    final items = <StockTransactionItem>[];
    for (final item in merged) {
      final product =
          _backend.findProduct(session.businessId, item.productId) ??
          (throw const NotFoundException('Produk tidak ditemukan.'));
      if (!product.isActive) throw ProductArchivedException(product.id);
      if (input.type == TransactionType.stockOut && product.currentStock < item.quantity) {
        throw InsufficientStockException(
          productId: product.id,
          productName: product.name,
          available: product.currentStock,
          requested: item.quantity,
        );
      }
      items.add(
        StockTransactionItem(
          id: _backend.ids.newId(),
          productId: product.id,
          productName: product.name,
          unit: product.unit,
          quantity: item.quantity,
          unitCostSnapshot: product.costPrice,
        ),
      );
    }

    // Semua valid: baru ubah state.
    final now = clock.now().toUtc();
    final at = (input.transactionAt ?? now).toUtc();
    final prefix = transactionNumberPrefix(session.businessCode, at.toLocal().year);
    final seq =
        maxSequence(
          prefix,
          _backend.transactions.where((t) => t.businessId == session.businessId).map((t) => t.number),
        ) +
        1;

    final sign = input.type == TransactionType.stockIn ? 1 : -1;
    for (final item in items) {
      final product = _backend.findProduct(session.businessId, item.productId)!;
      // Sengaja TIDAK mengubah syncStatus/updatedAt produk (kontrak: stok hanya lewat transaksi).
      _backend.replaceProduct(product.copyWith(currentStock: product.currentStock + sign * item.quantity));
    }

    final transaction = StockTransaction(
      id: _backend.ids.newId(),
      businessId: session.businessId,
      number: formatTransactionNumber(session.businessCode, at.toLocal().year, seq),
      type: input.type,
      notes: input.notes,
      createdBy: session.userId,
      transactionAt: at,
      createdAt: now,
      syncStatus: SyncStatus.pending,
      items: items,
    );
    _backend.transactions.add(transaction);
    _backend.notify();
    return transaction;
  }

  List<StockTransaction> _list(TransactionType? type, int limit) {
    final businessId = _session().businessId;
    final indexed =
        <(int, StockTransaction)>[
          for (var i = 0; i < _backend.transactions.length; i++)
            if (_backend.transactions[i].businessId == businessId &&
                (type == null || _backend.transactions[i].type == type))
              (i, _backend.transactions[i]),
        ]..sort((a, b) {
          final byAt = b.$2.transactionAt.compareTo(a.$2.transactionAt);
          if (byAt != 0) return byAt;
          final byCreated = b.$2.createdAt.compareTo(a.$2.createdAt);
          return byCreated != 0 ? byCreated : b.$1.compareTo(a.$1);
        });
    return [for (final entry in indexed.take(limit)) entry.$2];
  }
}
