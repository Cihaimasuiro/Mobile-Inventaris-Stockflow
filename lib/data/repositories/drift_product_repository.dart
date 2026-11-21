import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/core/utils/uuid_generator.dart';
import 'package:stokflow/data/models/row_mappers.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/entities/product.dart';
import 'package:stokflow/domain/repositories/product_repository.dart';
import 'package:stokflow/domain/validation/product_input_validator.dart';

import 'business_guard.dart';

/// ProductRepository di atas Drift, terikat ke satu sesi (bisnis).
/// Perilaku dijaga identik dengan fake lewat `test/contract/repository_contract.dart`.
class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db, this._session, {this._ids = const UuidV4Generator()});

  final AppDatabase _db;
  final AuthSession _session;
  final IdGenerator _ids;

  String get _businessId => _session.businessId;

  @override
  Stream<List<Product>> watchProducts({String query = '', bool includeArchived = false}) => _db.productDao
      .watchList(_businessId, query: query, includeArchived: includeArchived)
      .map((rows) => rows.map(productFromRow).toList());

  @override
  Stream<Product?> watchProduct(String id) =>
      _db.productDao.watchById(_businessId, id).map((row) => row == null ? null : productFromRow(row));

  @override
  Future<Product?> findByBarcode(String barcode) async {
    final code = normalizeBarcode(barcode);
    if (code == null) return null;
    final row = await _db.productDao.findActiveByBarcode(_businessId, code);
    return row == null ? null : productFromRow(row);
  }

  @override
  Future<Product> create(ProductInput input, {int initialStock = 0}) async {
    await requireActiveBusiness(_db, _businessId);
    final errors = validateProductInput(input, initialStock: initialStock);
    if (errors.isNotEmpty) throw ValidationException(errors);
    final barcode = normalizeBarcode(input.skuBarcode);

    return _db.transaction(() async {
      if (barcode != null && await _db.productDao.isBarcodeTaken(_businessId, barcode)) {
        throw DuplicateBarcodeException(barcode);
      }
      final now = clock.now().toUtc();
      final id = _ids.newId();
      await _db.productDao.insertRow(
        ProductsCompanion.insert(
          id: id,
          businessId: _businessId,
          name: input.name.trim(),
          unit: input.unit.trim(),
          status: ProductStatus.active,
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          skuBarcode: Value(barcode),
          costPrice: Value(input.costPrice),
          sellingPrice: Value(input.sellingPrice),
          currentStock: Value(initialStock),
        ),
      );
      return productFromRow((await _db.productDao.getById(_businessId, id))!);
    });
  }

  @override
  Future<Product> update(String id, ProductInput input) {
    return _db.transaction(() async {
      final existing =
          await _db.productDao.getById(_businessId, id) ?? (throw const NotFoundException('Produk tidak ditemukan.'));
      final errors = validateProductInput(input);
      if (errors.isNotEmpty) throw ValidationException(errors);
      final barcode = normalizeBarcode(input.skuBarcode);
      if (existing.status == ProductStatus.active &&
          barcode != null &&
          await _db.productDao.isBarcodeTaken(_businessId, barcode, exceptId: id)) {
        throw DuplicateBarcodeException(barcode);
      }

      // Stok sengaja tidak ikut: stok hanya berubah lewat transaksi.
      await _db.productDao.updateRow(
        _businessId,
        id,
        ProductsCompanion(
          name: Value(input.name.trim()),
          unit: Value(input.unit.trim()),
          costPrice: Value(input.costPrice),
          sellingPrice: Value(input.sellingPrice),
          skuBarcode: Value(barcode),
          syncStatus: const Value(SyncStatus.pending),
          syncErrorCode: const Value(null),
          updatedAt: Value(clock.now().toUtc()),
        ),
      );
      return productFromRow((await _db.productDao.getById(_businessId, id))!);
    });
  }

  @override
  Future<void> archive(String id) {
    return _db.transaction(() async {
      final existing = await _db.productDao.getById(_businessId, id);
      if (existing == null) throw const NotFoundException('Produk tidak ditemukan.');
      await _db.productDao.updateRow(
        _businessId,
        id,
        ProductsCompanion(
          status: const Value(ProductStatus.archived),
          syncStatus: const Value(SyncStatus.pending),
          syncErrorCode: const Value(null),
          updatedAt: Value(clock.now().toUtc()),
        ),
      );
    });
  }
}
