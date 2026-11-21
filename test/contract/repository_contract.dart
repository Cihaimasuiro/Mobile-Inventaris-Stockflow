/// Suite contract test BERSAMA. Dijalankan terhadap fake (B) DAN implementasi Drift (A)
/// sehingga keduanya terbukti berperilaku sama. Lihat KONTRAK BERSAMA v1, bagian 9.
library;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/repositories/product_repository.dart';
import 'package:stokflow/domain/repositories/transaction_repository.dart';

const sessionA = AuthSession(
  userId: 'user-a',
  userName: 'Budi',
  businessId: 'biz-a',
  businessCode: 'TMJ01',
  businessName: 'Toko Maju Jaya',
);

const sessionB = AuthSession(
  userId: 'user-b',
  userName: 'Sari',
  businessId: 'biz-b',
  businessCode: 'XYZ99',
  businessName: 'Warung Sari',
);

/// Jembatan ke implementasi yang diuji. Bisnis dibuat otomatis (ACTIVE) saat pertama dipakai.
abstract class ContractHarness {
  ProductRepository products(AuthSession session);
  TransactionRepository transactions(AuthSession session);
  Future<void> setBusinessStatus(AuthSession session, BusinessStatus status);

  /// Tandai semua produk dan transaksi bisnis ini SYNCED (simulasi setelah push sukses).
  Future<void> markAllSynced(AuthSession session);
  Future<void> dispose();
}

typedef HarnessFactory = Future<ContractHarness> Function();

ProductInput _input({
  String name = 'Kopi Susu',
  String unit = 'pcs',
  int sell = 15000,
  int cost = 8500,
  String? barcode,
}) => ProductInput(name: name, unit: unit, sellingPrice: sell, costPrice: cost, skuBarcode: barcode);

Future<T> _at<T>(DateTime utc, Future<T> Function() body) => withClock(Clock.fixed(utc), body);

final DateTime _t0 = DateTime.utc(2026, 11, 19, 3);

void runRepositoryContract(String name, HarnessFactory create) {
  group('Repository contract: $name', () {
    late ContractHarness h;
    late ProductRepository products;
    late TransactionRepository trx;

    setUp(() async {
      h = await create();
      products = h.products(sessionA);
      trx = h.transactions(sessionA);
    });

    tearDown(() => h.dispose());

    Future<int> stockOf(String id, [ProductRepository? repo]) async =>
        (await (repo ?? products).watchProduct(id).first)!.currentStock;

    Future<String> newProduct({int stock = 10, String? barcode, int cost = 8500, String name = 'Kopi Susu'}) async =>
        (await products.create(
          _input(barcode: barcode, cost: cost, name: name),
          initialStock: stock,
        )).id;

    group('produk', () {
      test('create menyimpan PENDING dengan stok awal dan barcode ter-trim', () async {
        final p = await _at(_t0, () => products.create(_input(barcode: '  8992753123456 '), initialStock: 7));

        expect(p.id, isNotEmpty);
        expect(p.businessId, 'biz-a');
        expect(p.currentStock, 7);
        expect(p.skuBarcode, '8992753123456');
        expect(p.status, ProductStatus.active);
        expect(p.syncStatus, SyncStatus.pending);
        expect(p.createdAt.isUtc, isTrue);
        expect(await products.findByBarcode('8992753123456'), isNotNull);
      });

      test('create dengan input tidak valid melempar ValidationException', () async {
        await expectLater(
          products.create(_input(name: '  ')),
          throwsA(isA<ValidationException>().having((e) => e.fieldErrors.keys, 'keys', contains('name'))),
        );
        await expectLater(products.create(_input(), initialStock: -1), throwsA(isA<ValidationException>()));
      });

      test('barcode ACTIVE kembar ditolak, barcode produk ARCHIVED boleh dipakai ulang', () async {
        final id = await newProduct(barcode: '111');
        await expectLater(
          products.create(_input(name: 'Lain', barcode: '111')),
          throwsA(isA<DuplicateBarcodeException>()),
        );

        await products.archive(id);
        final reuse = await products.create(_input(name: 'Pengganti', barcode: '111'));
        expect(reuse.skuBarcode, '111');
      });

      test('update mengubah master, tidak pernah mengubah stok, dan menandai PENDING', () async {
        final id = await newProduct(stock: 10);
        await h.markAllSynced(sessionA);

        final updated = await products.update(id, _input(name: 'Kopi Baru', sell: 20000, cost: 9000));

        expect(updated.name, 'Kopi Baru');
        expect(updated.sellingPrice, 20000);
        expect(updated.currentStock, 10);
        expect(updated.syncStatus, SyncStatus.pending);
      });

      test('update produk tidak ada -> NotFoundException; barcode bentrok -> DuplicateBarcodeException', () async {
        await expectLater(products.update('tidak-ada', _input()), throwsA(isA<NotFoundException>()));

        await newProduct(barcode: 'AAA');
        final other = await newProduct(name: 'Lain', barcode: 'BBB');
        await expectLater(
          products.update(other, _input(name: 'Lain', barcode: 'AAA')),
          throwsA(isA<DuplicateBarcodeException>()),
        );
        // Barcode sendiri tidak dianggap bentrok.
        await products.update(other, _input(name: 'Lain', barcode: 'BBB'));
      });

      test('archive: hilang dari daftar aktif dan findByBarcode, tetap ada jika includeArchived', () async {
        final id = await newProduct(barcode: '222');
        await h.markAllSynced(sessionA);

        await products.archive(id);

        expect(await products.watchProducts().first, isEmpty);
        expect(await products.findByBarcode('222'), isNull);
        final all = await products.watchProducts(includeArchived: true).first;
        expect(all.single.status, ProductStatus.archived);
        expect(all.single.syncStatus, SyncStatus.pending);
        await expectLater(products.archive('tidak-ada'), throwsA(isA<NotFoundException>()));
      });

      test('pencarian case-insensitive di nama dan barcode, urut nama A-Z', () async {
        await newProduct(name: 'Minyak Goreng', barcode: 'ABC123');
        await newProduct(name: 'kopi susu');
        await newProduct(name: 'Beras');

        expect((await products.watchProducts(query: 'MINYAK').first).map((p) => p.name), ['Minyak Goreng']);
        expect((await products.watchProducts(query: 'abc1').first).map((p) => p.name), ['Minyak Goreng']);
        expect((await products.watchProducts(query: 'zzz').first), isEmpty);
        expect((await products.watchProducts().first).map((p) => p.name), ['Beras', 'kopi susu', 'Minyak Goreng']);
      });

      test('stream watchProducts memancarkan data baru setelah tulis', () async {
        final seen = expectLater(products.watchProducts().map((l) => l.length), emitsThrough(1));
        await newProduct();
        await seen;
      });
    });

    group('createTransaction', () {
      test('STOCK_IN menambah stok dan STOCK_OUT mengurangi; transaksi PENDING dengan item lengkap', () async {
        final id = await newProduct(stock: 10, cost: 8500);

        final tIn = await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockIn,
            items: [NewTransactionItem(productId: id, quantity: 5)],
            notes: 'Restock',
          ),
        );
        expect(await stockOf(id), 15);
        expect(tIn.syncStatus, SyncStatus.pending);
        expect(tIn.notes, 'Restock');
        expect(tIn.createdBy, 'user-a');
        expect(tIn.items.single.productName, 'Kopi Susu');
        expect(tIn.items.single.unit, 'pcs');
        expect(tIn.items.single.unitCostSnapshot, 8500);

        await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockOut,
            items: [NewTransactionItem(productId: id, quantity: 4)],
          ),
        );
        expect(await stockOf(id), 11);
      });

      test('STOCK_OUT melebihi stok -> InsufficientStockException dan tidak ada yang berubah', () async {
        final id = await newProduct(stock: 3);

        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockOut,
              items: [NewTransactionItem(productId: id, quantity: 4)],
            ),
          ),
          throwsA(
            isA<InsufficientStockException>()
                .having((e) => e.available, 'available', 3)
                .having((e) => e.requested, 'requested', 4),
          ),
        );

        expect(await stockOf(id), 3);
        expect(await trx.watchTransactions().first, isEmpty);
      });

      test('multi-item bersifat all-or-nothing', () async {
        final a = await newProduct(stock: 10, name: 'A');
        final b = await newProduct(stock: 1, name: 'B');

        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockOut,
              items: [
                NewTransactionItem(productId: a, quantity: 2),
                NewTransactionItem(productId: b, quantity: 5),
              ],
            ),
          ),
          throwsA(isA<InsufficientStockException>()),
        );

        expect(await stockOf(a), 10);
        expect(await stockOf(b), 1);
        expect(await trx.watchTransactions().first, isEmpty);
      });

      test('produk kembar dalam satu transaksi digabung sebelum validasi stok', () async {
        final id = await newProduct(stock: 5);

        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockOut,
              items: [
                NewTransactionItem(productId: id, quantity: 3),
                NewTransactionItem(productId: id, quantity: 3),
              ],
            ),
          ),
          throwsA(isA<InsufficientStockException>()),
        );

        final ok = await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockOut,
            items: [
              NewTransactionItem(productId: id, quantity: 2),
              NewTransactionItem(productId: id, quantity: 3),
            ],
          ),
        );
        expect(ok.items.single.quantity, 5);
        expect(await stockOf(id), 0);
      });

      test('validasi: item kosong atau qty < 1; produk tidak ada; produk ARCHIVED', () async {
        await expectLater(
          trx.createTransaction(const NewTransaction(type: TransactionType.stockIn, items: [])),
          throwsA(isA<ValidationException>()),
        );

        final id = await newProduct();
        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 0)],
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          trx.createTransaction(
            const NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: 'tidak-ada', quantity: 1)],
            ),
          ),
          throwsA(isA<NotFoundException>()),
        );

        await products.archive(id);
        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
          throwsA(isA<ProductArchivedException>()),
        );
      });

      test('unitCostSnapshot tidak berubah walau harga modal master diubah', () async {
        final id = await newProduct(stock: 10, cost: 8500);
        final t = await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockOut,
            items: [NewTransactionItem(productId: id, quantity: 1)],
          ),
        );

        await products.update(id, _input(cost: 12000));

        final reloaded = (await trx.watchTransaction(t.id).first)!;
        expect(reloaded.items.single.unitCostSnapshot, 8500);
      });

      test('transaksi tidak mengubah sync_status produk', () async {
        final id = await newProduct(stock: 10);
        await h.markAllSynced(sessionA);

        await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockOut,
            items: [NewTransactionItem(productId: id, quantity: 2)],
          ),
        );

        final p = (await products.watchProduct(id).first)!;
        expect(p.syncStatus, SyncStatus.synced);
        expect(p.currentStock, 8);
      });

      test('bisnis INACTIVE tidak bisa membuat produk maupun transaksi', () async {
        final id = await newProduct();
        await h.setBusinessStatus(sessionA, BusinessStatus.suspended);

        await expectLater(products.create(_input(name: 'Baru')), throwsA(isA<BusinessInactiveException>()));
        await expectLater(
          trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
          throwsA(isA<BusinessInactiveException>()),
        );
      });
    });

    group('nomor transaksi', () {
      Future<String> numberOf(TransactionRepository repo, String productId, {TransactionType? type}) async {
        final t = await repo.createTransaction(
          NewTransaction(
            type: type ?? TransactionType.stockIn,
            items: [NewTransactionItem(productId: productId, quantity: 1)],
          ),
        );
        return t.number;
      }

      test('berurutan, zero-pad 6 digit, format [KODE]-[TAHUN]-[URUT6]', () async {
        final id = await newProduct();

        final n1 = await _at(_t0, () => numberOf(trx, id));
        final n2 = await _at(_t0, () => numberOf(trx, id));

        expect(n1, 'TMJ01-2026-000001');
        expect(n2, 'TMJ01-2026-000002');
        expect(RegExp(r'^[A-Z0-9]{2,10}-\d{4}-\d{6}$').hasMatch(n2), isTrue);
      });

      test('ganti tahun mereset urutan', () async {
        final id = await newProduct();

        await _at(DateTime.utc(2026, 6, 1, 3), () => numberOf(trx, id));
        final next = await _at(DateTime.utc(2027, 6, 1, 3), () => numberOf(trx, id));

        expect(next, 'TMJ01-2027-000001');
      });

      test('tiap bisnis punya urutan sendiri', () async {
        final idA = await newProduct();
        final productsB = h.products(sessionB);
        final idB = (await productsB.create(_input(name: 'Barang B'), initialStock: 5)).id;

        await _at(_t0, () => numberOf(trx, idA));
        final nB = await _at(_t0, () => numberOf(h.transactions(sessionB), idB));

        expect(nB, 'XYZ99-2026-000001');
      });
    });

    group('riwayat dan isolasi', () {
      test('urut terbaru dulu, filter jenis, dan limit', () async {
        final id = await newProduct(stock: 100);
        await _at(
          DateTime.utc(2026, 11, 1, 3),
          () => trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
        );
        await _at(
          DateTime.utc(2026, 11, 3, 3),
          () => trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockOut,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
        );
        await _at(
          DateTime.utc(2026, 11, 2, 3),
          () => trx.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
        );

        final all = await trx.watchTransactions().first;
        expect(all.map((t) => t.transactionAt.day), [3, 2, 1]);

        final onlyOut = await trx.watchTransactions(type: TransactionType.stockOut).first;
        expect(onlyOut.single.type, TransactionType.stockOut);

        expect((await trx.watchTransactions(limit: 2).first).length, 2);
      });

      test('data bisnis A tidak terlihat dari bisnis B', () async {
        final id = await newProduct(stock: 5, barcode: '999');
        await trx.createTransaction(
          NewTransaction(
            type: TransactionType.stockIn,
            items: [NewTransactionItem(productId: id, quantity: 1)],
          ),
        );

        final productsB = h.products(sessionB);
        final trxB = h.transactions(sessionB);

        expect(await productsB.watchProducts().first, isEmpty);
        expect(await productsB.findByBarcode('999'), isNull);
        expect(await productsB.watchProduct(id).first, isNull);
        expect(await trxB.watchTransactions().first, isEmpty);
        await expectLater(
          trxB.createTransaction(
            NewTransaction(
              type: TransactionType.stockIn,
              items: [NewTransactionItem(productId: id, quantity: 1)],
            ),
          ),
          throwsA(isA<NotFoundException>()),
        );
        // Barcode yang sama boleh dipakai di bisnis lain.
        await productsB.create(_input(name: 'Barang B', barcode: '999'));
      });
    });
  });
}
