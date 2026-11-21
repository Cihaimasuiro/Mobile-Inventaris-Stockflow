import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// enums.dart dan enum_converters.dart dibutuhkan kode generated (app_database.g.dart)
// untuk tipe kolom enum.
import 'package:stokflow/domain/entities/enums.dart';

import '../../data/datasources/local/daos/business_dao.dart';
import '../../data/datasources/local/daos/product_dao.dart';
import '../../data/datasources/local/daos/pull_merge_dao.dart';
import '../../data/datasources/local/daos/sync_dao.dart';
import '../../data/datasources/local/daos/sync_queue_dao.dart';
import '../../data/datasources/local/daos/transaction_dao.dart';
import '../../data/datasources/local/enum_converters.dart';
import '../../data/datasources/local/tables/businesses.dart';
import '../../data/datasources/local/tables/products.dart';
import '../../data/datasources/local/tables/stock_transaction_items.dart';
import '../../data/datasources/local/tables/stock_transactions.dart';
import '../../data/datasources/local/tables/sync_states.dart';

part 'app_database.g.dart';

/// Database lokal offline-first (SQLite lewat Drift). Skema: KONTRAK BERSAMA v1, bagian 4.
@DriftDatabase(
  tables: [Businesses, Products, StockTransactions, StockTransactionItems, SyncStates],
  daos: [BusinessDao, ProductDao, TransactionDao, SyncDao, SyncQueueDao, PullMergeDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Database file di perangkat. Untuk tes pakai `AppDatabase(NativeDatabase.memory())`.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'stokflow'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
