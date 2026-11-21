import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

/// PRD aturan bisnis 5: bisnis INACTIVE/SUSPENDED tidak boleh membuat data baru.
/// Gagal tertutup: bisnis yang tidak ada di cache lokal dianggap tidak aktif.
Future<void> requireActiveBusiness(AppDatabase db, String businessId) async {
  final business = await db.businessDao.getById(businessId);
  if (business == null || business.status != BusinessStatus.active) {
    throw const BusinessInactiveException();
  }
}
