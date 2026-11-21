import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stokflow/core/di/providers.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/stock_transaction.dart';

/// Riwayat terbaru dulu. Argumen `null` = semua jenis (filter ALL).
final transactionListProvider = StreamProvider.autoDispose.family<List<StockTransaction>, TransactionType?>(
  (ref, type) => ref.watch(transactionRepositoryProvider).watchTransactions(type: type),
);

final transactionDetailProvider = StreamProvider.autoDispose.family<StockTransaction?, String>(
  (ref, id) => ref.watch(transactionRepositoryProvider).watchTransaction(id),
);
