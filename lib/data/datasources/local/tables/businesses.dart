import 'package:drift/drift.dart';

import '../enum_converters.dart';

/// Cache profil toko dari login/me. Dibutuhkan offline: `code` untuk nomor transaksi,
/// `status` untuk aturan "bisnis INACTIVE/SUSPENDED tidak bisa transaksi" (PRD aturan 5).
@DataClassName('BusinessRow')
class Businesses extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get businessType => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text().map(const BusinessStatusConverter())();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
