import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/data/datasources/remote/sync_remote.dart';
import 'package:stokflow/domain/entities/enums.dart';

import '../../../repositories/fake_sync_server.dart';

final _t = DateTime.utc(2026, 11, 19, 3);

PulledProduct _pulled({
  String id = 'p1',
  String businessId = 'biz-a',
  String name = 'Server',
  int stock = 10,
  String? sku,
}) => PulledProduct(
  id: id,
  businessId: businessId,
  skuBarcode: sku,
  name: name,
  unit: 'pcs',
  costPrice: 1,
  sellingPrice: 2,
  currentStock: stock,
  status: ProductStatus.active,
  createdAt: _t,
  updatedAt: _t,
);

PulledTransaction _pulledTrx({
  String id = 't1',
  String businessId = 'biz-a',
  String number = 'TMJ01-2026-000001',
  String productId = 'p1',
  String? itemId,
}) => PulledTransaction(
  id: id,
  businessId: businessId,
  number: number,
  type: TransactionType.stockIn,
  createdBy: 'server-user',
  transactionAt: _t,
  createdAt: _t,
  items: [PulledItem(id: itemId, productId: productId, quantity: 2, unitCostSnapshot: 7)],
);

void main() {
  late TestDevice d;

  setUp(() async {
    d = await TestDevice.create(FakeSyncServer());
    addTearDown(d.dispose);
  });

  group('produk', () {
    test('produk baru dari server disisipkan SYNCED dengan lastSyncedAt', () async {
      final skipped = await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(stock: 12)], _t);

      final row = (await d.db.productDao.getById('biz-a', 'p1'))!;
      expect(skipped, 0);
      expect(row.syncStatus, SyncStatus.synced);
      expect(row.currentStock, 12);
      expect(row.lastSyncedAt?.toUtc(), _t);
    });

    test('baris lokal SYNCED ditimpa data server', () async {
      await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(name: 'Lama', stock: 5)], _t);

      await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(name: 'Baru', stock: 9)], _t);

      final row = (await d.db.productDao.getById('biz-a', 'p1'))!;
      expect(row.name, 'Baru');
      expect(row.currentStock, 9);
    });

    test('baris lokal PENDING: field master lokal menang, stok = stok server + pendingDelta', () async {
      final id = await d.newProduct(name: 'Lokal', stock: 10);
      await d.move(id, TransactionType.stockOut, 3); // stok lokal 7, belum terkirim

      await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(id: id, name: 'Server', stock: 20)], _t);

      final row = (await d.db.productDao.getById('biz-a', id))!;
      expect(row.name, 'Lokal');
      expect(row.syncStatus, SyncStatus.pending);
      expect(row.currentStock, 17, reason: '20 (server) + (-3) transaksi lokal belum terkirim');
      expect(row.lastSyncedAt, isNotNull, reason: 'server sudah mengenal produk ini');
    });

    test('stok tidak pernah menjadi negatif (dijepit ke 0)', () async {
      final id = await d.newProduct(stock: 10);
      await d.move(id, TransactionType.stockOut, 8);

      await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(id: id, stock: 1)], _t);

      expect((await d.db.productDao.getById('biz-a', id))!.currentStock, 0);
    });

    test('baris milik bisnis lain dilewati', () async {
      final skipped = await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(businessId: 'biz-lain')], _t);

      expect(skipped, 1);
      expect(await d.db.productDao.getById('biz-a', 'p1'), isNull);
    });
  });

  group('transaksi', () {
    test('transaksi baru disisipkan SYNCED beserta item; id item dibuat jika server tidak mengirim', () async {
      await d.db.pullMergeDao.applyProducts('biz-a', [_pulled(stock: 5)], _t);

      final skipped = await d.db.pullMergeDao.applyTransactions('biz-a', [_pulledTrx()], newId: () => 'gen-item');

      final t = (await d.transactions.watchTransaction('t1').first)!;
      expect(skipped, 0);
      expect(t.syncStatus, SyncStatus.synced);
      expect(t.number, 'TMJ01-2026-000001');
      expect(t.items.single.id, 'gen-item');
      expect(t.items.single.unitCostSnapshot, 7);
      expect((await d.db.productDao.getById('biz-a', 'p1'))!.currentStock, 5, reason: 'stok tidak dihitung dua kali');
    });

    test('transaksi yang merujuk produk tak dikenal dilewati', () async {
      final skipped = await d.db.pullMergeDao.applyTransactions('biz-a', [_pulledTrx()], newId: () => 'x');

      expect(skipped, 1);
      expect(await d.transactions.watchTransaction('t1').first, isNull);
    });

    test('transaksi yang sudah ada hanya diperbarui nomor dan statusnya', () async {
      final p = await d.newProduct(stock: 5);
      final id = await d.move(p, TransactionType.stockIn, 1);

      await d.db.pullMergeDao.applyTransactions('biz-a', [
        _pulledTrx(id: id, number: 'TMJ01-2026-000009', productId: p),
      ], newId: () => 'x');

      final t = (await d.transactions.watchTransaction(id).first)!;
      expect(t.number, 'TMJ01-2026-000009');
      expect(t.syncStatus, SyncStatus.synced);
      expect(t.items.single.quantity, 1, reason: 'item lokal tidak diubah');
    });

    test('transaksi bisnis lain dilewati', () async {
      final skipped = await d.db.pullMergeDao.applyTransactions('biz-a', [
        _pulledTrx(businessId: 'biz-lain'),
      ], newId: () => 'x');

      expect(skipped, 1);
    });
  });
}
