import 'package:drift/drift.dart';

import 'businesses.dart';

/// Kursor pull per bisnis. `lastPullServerTime` NULL = initial pull belum selesai.
@DataClassName('SyncStateRow')
class SyncStates extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get businessId => text().references(Businesses, #id)();
  DateTimeColumn get lastPullServerTime => dateTime().nullable()();
  DateTimeColumn get lastSyncOkAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {businessId};
}
