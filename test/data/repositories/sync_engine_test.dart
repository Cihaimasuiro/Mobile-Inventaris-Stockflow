import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/domain/entities/enums.dart';

import 'fake_sync_server.dart';

void main() {
  late FakeSyncServer server;
  late TestDevice d;

  Future<void> setUpDevice() async {
    server = FakeSyncServer();
    d = await TestDevice.create(server);
    addTearDown(d.dispose);
  }

  group('push', () {
    test('mengirim produk lalu transaksi; semua SYNCED dan stok server sama dengan stok lokal', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 10);
        final t = await d.move(p, TransactionType.stockOut, 3);

        final outcome = await d.engine.run();

        expect(outcome.ok, isTrue);
        expect(server.stockOf(p), 7);
        expect(await d.stock(p), 7);
        expect(await d.trxStatus(t), SyncStatus.synced);
        expect((await d.products.watchProduct(p).first)!.syncStatus, SyncStatus.synced);
        // Stok awal = stok lokal - efek transaksi yang belum sync (tidak terhitung dua kali).
        expect(server.pushedProducts.single.initialStock, 10);
      });
    });

    test('stok awal hanya dikirim untuk produk yang belum dikenal server', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 10);
        await d.engine.run();

        final current = (await d.products.watchProduct(p).first)!;
        await d.products.update(p, inputFrom(current, name: 'Kopi Baru'));
        await d.engine.run();

        expect(server.pushedProducts.last.initialStock, isNull);
        expect(server.products[p]!.name, 'Kopi Baru');
        expect(server.stockOf(p), 10);
      });
    });

    test('transaksi tidak dikirim jika produknya ditolak server', () {
      return withFixedClock(() async {
        await setUpDevice();
        server.addProduct(id: 'srv-p', name: 'Sudah ada', stock: 1, sku: '111');
        final p = await d.newProduct(barcode: '111');
        final t = await d.move(p, TransactionType.stockIn, 1);

        await d.engine.run();

        final row = (await d.db.productDao.getById('biz-a', p))!;
        expect(row.syncStatus, SyncStatus.failed);
        expect(row.syncErrorCode, 'DUPLICATE_BARCODE');
        expect(await d.trxStatus(t), SyncStatus.pending);
        expect(server.pushedTransactions, isEmpty);
      });
    });

    test('item ditolak menjadi FAILED, tidak dikirim ulang otomatis, dan sukses setelah retryFailed', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 5);
        await d.engine.run();
        final t = await d.move(p, TransactionType.stockOut, 3);
        server.setStock(p, 1);

        await d.engine.run();
        expect(await d.trxStatus(t), SyncStatus.failed);
        expect((await d.transactions.watchTransaction(t).first)!.syncErrorCode, 'INSUFFICIENT_STOCK');

        await d.engine.run();
        expect(server.pushedTransactions.length, 1, reason: 'FAILED tidak dikirim ulang otomatis');

        await d.db.syncQueueDao.retryFailed('biz-a');
        server.setStock(p, 10);
        await d.engine.run();
        expect(await d.trxStatus(t), SyncStatus.synced);
        expect(server.stockOf(p), 7);
      });
    });

    test('satu transaksi gagal tidak memblokir yang lain', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 5);
        await d.engine.run();
        final bad = await d.move(p, TransactionType.stockOut, 4);
        final good = await d.move(p, TransactionType.stockIn, 2);
        server.setStock(p, 2);

        await d.engine.run();

        expect(await d.trxStatus(bad), SyncStatus.failed);
        expect(await d.trxStatus(good), SyncStatus.synced);
      });
    });

    test('kirim ulang id yang sama tidak menggandakan di server (idempoten)', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 10);
        final t = await d.move(p, TransactionType.stockOut, 3);
        await d.engine.run();

        // Simulasi ack hilang: HP mengira transaksi belum terkirim.
        await d.db
            .update(d.db.stockTransactions)
            .write(const StockTransactionsCompanion(syncStatus: Value(SyncStatus.pending)));
        await d.engine.run();

        expect(server.transactions.length, 1);
        expect(server.stockOf(p), 7);
        expect(await d.trxStatus(t), SyncStatus.synced);
      });
    });

    test('server memberi nomor lain saat bentrok: nomor lokal diganti', () {
      return withFixedClock(() async {
        await setUpDevice();
        server
          ..addProduct(id: 'srv-p', name: 'Dari HP lain', stock: 0)
          ..addTransaction(id: 'other', number: 'TMJ01-2026-000001', productId: 'srv-p', qty: 5);
        final p = await d.newProduct(stock: 10);
        final t = await d.move(p, TransactionType.stockIn, 1);
        expect((await d.transactions.watchTransaction(t).first)!.number, 'TMJ01-2026-000001');

        await d.engine.run();

        expect((await d.transactions.watchTransaction(t).first)!.number, 'TMJ01-2026-000002');
        final numbers = (await d.transactions.watchTransactions().first).map((x) => x.number).toSet();
        expect(numbers, {'TMJ01-2026-000001', 'TMJ01-2026-000002'});
      });
    });

    test('edit produk saat push berlangsung tidak ikut dianggap SYNCED', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct(stock: 1);
        final pushed = (await d.db.productDao.getById('biz-a', p))!;

        // Pengguna mengedit setelah baris dibaca engine (waktu berbeda).
        await withClock(Clock.fixed(DateTime.utc(2026, 11, 19, 4)), () async {
          final current = (await d.products.watchProduct(p).first)!;
          await d.products.update(p, inputFrom(current, name: 'Diedit'));
        });
        await d.db.syncQueueDao.markProductSynced(
          'biz-a',
          p,
          DateTime.utc(2026, 11, 19, 5),
          pushedUpdatedAt: pushed.updatedAt,
        );

        final row = (await d.db.productDao.getById('biz-a', p))!;
        expect(row.syncStatus, SyncStatus.pending, reason: 'perubahan baru belum terkirim');
        expect(row.lastSyncedAt, isNotNull, reason: 'server sudah mengenal produknya');
      });
    });
  });

  group('hasil siklus', () {
    test('jaringan putus: baris tetap PENDING, outcome offline, lalu sukses setelah pulih', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct();
        server.failWith = const NetworkException();

        final first = await d.engine.run();
        expect(first.offline, isTrue);
        expect((await d.products.watchProduct(p).first)!.syncStatus, SyncStatus.pending);
        expect(await d.db.syncQueueDao.lastPullServerTime('biz-a'), isNull);

        expect((await d.engine.run()).ok, isTrue);
        expect((await d.products.watchProduct(p).first)!.syncStatus, SyncStatus.synced);
      });
    });

    test('401 -> authRequired dan 403 -> businessInactive, data lokal tidak berubah', () {
      return withFixedClock(() async {
        await setUpDevice();
        final p = await d.newProduct();

        server.failWith = const UnauthorizedException();
        expect((await d.engine.run()).issue, SyncIssue.authRequired);
        server.failWith = const BusinessInactiveException();
        expect((await d.engine.run()).issue, SyncIssue.businessInactive);

        expect((await d.products.watchProduct(p).first)!.syncStatus, SyncStatus.pending);
      });
    });
  });

  group('pull', () {
    test('kursor hanya disimpan setelah semua halaman; halaman gagal tidak memajukan kursor', () {
      return withFixedClock(() async {
        await setUpDevice();
        server.pageSize = 1;
        for (final n in ['a', 'b', 'c']) {
          server.addProduct(id: n, name: n, stock: 1);
        }
        server.failOnPullPage = 1;

        final failed = await d.engine.run();
        expect(failed.offline, isTrue);
        expect(await d.db.syncQueueDao.lastPullServerTime('biz-a'), isNull);

        server.failOnPullPage = null;
        expect((await d.engine.run()).ok, isTrue);
        expect((await d.products.watchProducts().first).length, 3);
        expect(await d.db.syncQueueDao.lastPullServerTime('biz-a'), DateTime.utc(2026, 11, 19, 3));
      });
    });

    test('dua HP: perubahan satu HP sampai ke HP lain dan stok konsisten', () {
      return withFixedClock(() async {
        await setUpDevice();
        final a = d;
        final b = await TestDevice.create(server);
        addTearDown(b.dispose);

        final p = await a.newProduct(stock: 10);
        await a.move(p, TransactionType.stockOut, 3);
        await a.engine.run();

        await b.engine.run();
        expect(await b.stock(p), 7);
        expect((await b.transactions.watchTransactions().first).single.syncStatus, SyncStatus.synced);

        await b.move(p, TransactionType.stockOut, 2);
        await b.engine.run();
        expect(server.stockOf(p), 5);

        await a.engine.run();
        expect(await a.stock(p), 5);
      });
    });
  });
}
