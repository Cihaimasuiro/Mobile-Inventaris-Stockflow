import 'package:drift/drift.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../tables/businesses.dart';

part 'business_dao.g.dart';

@DriftAccessor(tables: [Businesses])
class BusinessDao extends DatabaseAccessor<AppDatabase> with _$BusinessDaoMixin {
  BusinessDao(super.attachedDatabase);

  Future<BusinessRow?> getById(String id) => (select(businesses)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> upsert(BusinessesCompanion row) => into(businesses).insertOnConflictUpdate(row);

  Future<void> setStatus(String id, BusinessStatus status) =>
      (update(businesses)..where((b) => b.id.equals(id))).write(BusinessesCompanion(status: Value(status)));
}
