import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/data/repositories/drift_product_repository.dart';
import 'package:stokflow/data/repositories/drift_transaction_repository.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/repositories/product_repository.dart';
import 'package:stokflow/domain/repositories/transaction_repository.dart';

import '../../contract/repository_contract.dart';

class _DriftHarness implements ContractHarness {
  _DriftHarness(this.db);

  final AppDatabase db;

  static Future<_DriftHarness> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    for (final s in [sessionA, sessionB]) {
      await db.businessDao.upsert(
        BusinessesCompanion.insert(
          id: s.businessId,
          code: s.businessCode,
          name: s.businessName,
          status: BusinessStatus.active,
          updatedAt: clock.now().toUtc(),
        ),
      );
    }
    return _DriftHarness(db);
  }

  @override
  ProductRepository products(AuthSession session) => DriftProductRepository(db, session);

  @override
  TransactionRepository transactions(AuthSession session) => DriftTransactionRepository(db, session);

  @override
  Future<void> setBusinessStatus(AuthSession session, BusinessStatus status) =>
      db.businessDao.setStatus(session.businessId, status);

  @override
  Future<void> markAllSynced(AuthSession session) => db.syncDao.markAllSynced(session.businessId, clock.now().toUtc());

  @override
  Future<void> dispose() => db.close();
}

void main() => runRepositoryContract('Drift (implementasi A)', _DriftHarness.create);
