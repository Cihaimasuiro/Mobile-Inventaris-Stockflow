import 'package:clock/clock.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/inputs.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/validation/product_input_validator.dart';
import 'fake_backend.dart';

/// Fake ProductRepository. Perilaku HARUS identik dengan implementasi Drift
/// (dijaga oleh `test/contract/repository_contract.dart`).
class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository(this._backend, this._session);

  final FakeBackend _backend;
  final AuthSession Function() _session;

  String get _businessId => _session().businessId;

  @override
  Stream<List<Product>> watchProducts({String query = '', bool includeArchived = false}) =>
      _backend.watch(() => _list(query, includeArchived));

  @override
  Stream<Product?> watchProduct(String id) => _backend.watch(() => _backend.findProduct(_businessId, id));

  @override
  Future<Product?> findByBarcode(String barcode) async {
    final code = normalizeBarcode(barcode);
    if (code == null) return null;
    for (final p in _backend.products) {
      if (p.businessId == _businessId && p.isActive && p.skuBarcode == code) return p;
    }
    return null;
  }

  @override
  Future<Product> create(ProductInput input, {int initialStock = 0}) async {
    _requireActiveBusiness();
    final errors = validateProductInput(input, initialStock: initialStock);
    if (errors.isNotEmpty) throw ValidationException(errors);
    final barcode = normalizeBarcode(input.skuBarcode);
    _ensureBarcodeFree(barcode);

    final now = clock.now().toUtc();
    final product = Product(
      id: _backend.ids.newId(),
      businessId: _businessId,
      skuBarcode: barcode,
      name: input.name.trim(),
      unit: input.unit.trim(),
      costPrice: input.costPrice,
      sellingPrice: input.sellingPrice,
      currentStock: initialStock,
      status: ProductStatus.active,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _backend.products.add(product);
    _backend.notify();
    return product;
  }

  @override
  Future<Product> update(String id, ProductInput input) async {
    final existing =
        _backend.findProduct(_businessId, id) ?? (throw const NotFoundException('Produk tidak ditemukan.'));
    final errors = validateProductInput(input);
    if (errors.isNotEmpty) throw ValidationException(errors);
    final barcode = normalizeBarcode(input.skuBarcode);
    if (existing.isActive) _ensureBarcodeFree(barcode, exceptId: id);

    final updated = existing.copyWith(
      name: input.name.trim(),
      unit: input.unit.trim(),
      costPrice: input.costPrice,
      sellingPrice: input.sellingPrice,
      skuBarcode: barcode,
      syncStatus: SyncStatus.pending,
      syncErrorCode: null,
      updatedAt: clock.now().toUtc(),
    );
    _backend.replaceProduct(updated);
    _backend.notify();
    return updated;
  }

  @override
  Future<void> archive(String id) async {
    final existing =
        _backend.findProduct(_businessId, id) ?? (throw const NotFoundException('Produk tidak ditemukan.'));
    _backend.replaceProduct(
      existing.copyWith(
        status: ProductStatus.archived,
        syncStatus: SyncStatus.pending,
        syncErrorCode: null,
        updatedAt: clock.now().toUtc(),
      ),
    );
    _backend.notify();
  }

  void _requireActiveBusiness() {
    if (_backend.statusOf(_businessId) != BusinessStatus.active) throw const BusinessInactiveException();
  }

  void _ensureBarcodeFree(String? barcode, {String? exceptId}) {
    if (barcode == null) return;
    for (final p in _backend.products) {
      if (p.businessId == _businessId && p.isActive && p.skuBarcode == barcode && p.id != exceptId) {
        throw DuplicateBarcodeException(barcode);
      }
    }
  }

  List<Product> _list(String query, bool includeArchived) {
    final q = query.trim().toLowerCase();
    final result = _backend.products.where((p) {
      if (p.businessId != _businessId) return false;
      if (!includeArchived && !p.isActive) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || (p.skuBarcode?.toLowerCase().contains(q) ?? false);
    }).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}
