import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/data/repositories/drift_product_repository.dart';
import 'package:stokflow/data/repositories/drift_transaction_repository.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';

const _a = AuthSession(
  userId: 'user-a',
  userName: 'Budi',
  businessId: 'biz-a',
  businessCode: 'TMJ01',
  businessName: 'Toko Maju Jaya',
);
const _b = AuthSession(
  userId: 'user-b',
  userName: 'Sari',
  businessId: 'biz-b',
  businessCode: 'XYZ99',
  businessName: 'Warung Sari',
);

void main() {
  late AppDatabase db;
  late DriftProductRepository products;
  late DriftTransactionRepository trx;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final s in [_a, _b]) {
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
    products = DriftProductRepository(db, _a);
    trx = DriftTransactionRepository(db, _a);
  });

  tearDown(() => db.close());

  Future<String> newProduct(int stock) async => (await products.create(
    const ProductInput(name: 'Kopi', unit: 'pcs', sellingPrice: 1000),
    initialStock: stock,
  )).id;

  Future<String> move(String productId, TransactionType type, int qty) async => (await trx.createTransaction(
    NewTransaction(
      type: type,
      items: [NewTransactionItem(productId: productId, quantity: qty)],
    ),
  )).id;

  group('pendingDelta', () {
    test('menjumlahkan IN (+) dan OUT (-) yang belum diterima server', () async {
      final id = await newProduct(10);
      await move(id, TransactionType.stockIn, 5);
      await move(id, TransactionType.stockOut, 2);

      expect(await db.syncDao.pendingDelta('biz-a', id), 3);
    });

    test('nol setelah semua SYNCED; FAILED tetap dihitung', () async {
      final id = await newProduct(10);
      final failedId = await move(id, TransactionType.stockOut, 4);
      await move(id, TransactionType.stockIn, 1);

      await (db.update(db.stockTransactions)..where((t) => t.id.equals(failedId))).write(
        const StockTransactionsCompanion(syncStatus: Value(SyncStatus.failed)),
      );
      expect(await db.syncDao.pendingDelta('biz-a', id), -3);

      await db.syncDao.markAllSynced('biz-a', clock.now().toUtc());
      expect(await db.syncDao.pendingDelta('biz-a', id), 0);
    });

    test('stok awal untuk push produk baru = stok lokal - pendingDelta', () async {
      final id = await newProduct(10);
      await move(id, TransactionType.stockOut, 3);

      final local = (await products.watchProduct(id).first)!.currentStock;
      final delta = await db.syncDao.pendingDelta('biz-a', id);

      expect(local, 7);
      expect(local - delta, 10);
    });

    test('tidak membaca transaksi bisnis lain', () async {
      final id = await newProduct(10);
      await move(id, TransactionType.stockOut, 3);

      expect(await db.syncDao.pendingDelta('biz-b', id), 0);
    });
  });

  group('countUnsynced', () {
    test('menghitung PENDING dan FAILED produk + transaksi, scoped per bisnis', () async {
      final id = await newProduct(10);
      final trxId = await move(id, TransactionType.stockIn, 1);

      expect(await db.syncDao.countUnsynced('biz-a'), (pending: 2, failed: 0));

      await (db.update(db.stockTransactions)..where((t) => t.id.equals(trxId))).write(
        const StockTransactionsCompanion(syncStatus: Value(SyncStatus.failed)),
      );
      expect(await db.syncDao.countUnsynced('biz-a'), (pending: 1, failed: 1));
      expect(await db.syncDao.countUnsynced('biz-b'), (pending: 0, failed: 0));
    });

    test('watchUnsynced memancarkan hitungan baru setelah tulis', () async {
      final seen = expectLater(db.syncDao.watchUnsynced('biz-a').map((c) => c.pending), emitsThrough(1));
      await newProduct(1);
      await seen;
    });
  });

  test('markAllSynced mengisi lastSyncedAt produk dan menghapus kode error', () async {
    final id = await newProduct(1);
    final at = DateTime.utc(2026, 11, 19, 3);

    await db.syncDao.markAllSynced('biz-a', at);

    final row = (await db.productDao.getById('biz-a', id))!;
    expect(row.syncStatus, SyncStatus.synced);
    expect(row.lastSyncedAt?.toUtc(), at);
    expect(row.syncErrorCode, isNull);
  });
}
