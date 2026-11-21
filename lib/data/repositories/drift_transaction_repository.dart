import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/core/utils/transaction_number.dart';
import 'package:stokflow/core/utils/uuid_generator.dart';
import 'package:stokflow/data/models/row_mappers.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';
import 'package:stokflow/domain/repositories/transaction_repository.dart';
import 'package:stokflow/domain/validation/new_transaction_validator.dart';

import 'business_guard.dart';

/// TransactionRepository di atas Drift, terikat ke satu sesi (bisnis).
/// `createTransaction` adalah penyimpanan atomik (PRD bagian 16): validasi stok, nomor,
/// header, item, dan perubahan stok terjadi dalam SATU transaksi database.
class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db, this._session, {this._ids = const UuidV4Generator()});

  final AppDatabase _db;
  final AuthSession _session;
  final IdGenerator _ids;

  String get _businessId => _session.businessId;

  @override
  Stream<List<StockTransaction>> watchTransactions({TransactionType? type, int limit = 100}) => _db.transactionDao
      .watchList(_businessId, type: type, limit: limit)
      .map((views) => views.map(transactionFromView).toList());

  @override
  Stream<StockTransaction?> watchTransaction(String id) =>
      _db.transactionDao.watchView(_businessId, id).map((view) => view == null ? null : transactionFromView(view));

  @override
  Future<StockTransaction> createTransaction(NewTransaction input) async {
    await requireActiveBusiness(_db, _businessId);
    final errors = validateNewTransaction(input);
    if (errors.isNotEmpty) throw ValidationException(errors);
    final merged = mergeTransactionItems(input.items);

    return _db.transaction(() async {
      final lines = <(NewTransactionItem, ProductRow)>[];
      for (final item in merged) {
        final product =
            await _db.productDao.getById(_businessId, item.productId) ??
            (throw const NotFoundException('Produk tidak ditemukan.'));
        if (product.status != ProductStatus.active) throw ProductArchivedException(product.id);
        if (input.type == TransactionType.stockOut && product.currentStock < item.quantity) {
          throw InsufficientStockException(
            productId: product.id,
            productName: product.name,
            available: product.currentStock,
            requested: item.quantity,
          );
        }
        lines.add((item, product));
      }

      final now = clock.now().toUtc();
      final at = (input.transactionAt ?? now).toUtc();
      final year = at.toLocal().year;
      final seq = await _db.transactionDao.nextSequence(
        _businessId,
        transactionNumberPrefix(_session.businessCode, year),
      );
      final transactionId = _ids.newId();

      await _db.transactionDao.insertHeader(
        StockTransactionsCompanion.insert(
          id: transactionId,
          businessId: _businessId,
          transactionNumber: formatTransactionNumber(_session.businessCode, year, seq),
          type: input.type,
          createdBy: _session.userId,
          transactionAt: at,
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          notes: Value(input.notes),
        ),
      );

      final sign = input.type == TransactionType.stockIn ? 1 : -1;
      for (final (item, product) in lines) {
        await _db.transactionDao.insertItem(
          StockTransactionItemsCompanion.insert(
            id: _ids.newId(),
            businessId: _businessId,
            transactionId: transactionId,
            productId: product.id,
            quantity: item.quantity,
            createdAt: now,
            unitCostSnapshot: Value(product.costPrice),
          ),
        );
        await _db.productDao.addStock(_businessId, product.id, sign * item.quantity);
      }

      return transactionFromView((await _db.transactionDao.getView(_businessId, transactionId))!);
    });
  }
}
