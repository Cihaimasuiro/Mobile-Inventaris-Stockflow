import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/data/repositories/drift_sync_repository.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/sync_summary.dart';

import 'fake_sync_server.dart';

void main() {
  group('backoffDelay', () {
    test('2 dtk, 4, 8, ... dan dibatasi 5 menit', () {
      expect(backoffDelay(1), const Duration(seconds: 2));
      expect(backoffDelay(2), const Duration(seconds: 4));
      expect(backoffDelay(3), const Duration(seconds: 8));
      expect(backoffDelay(20), const Duration(minutes: 5));
    });

    test('jitter menggeser jeda secara proporsional; kegagalan 0 diperlakukan seperti 1', () {
      expect(backoffDelay(1, jitter: 0.5), const Duration(seconds: 3));
      expect(backoffDelay(2, jitter: -0.25), const Duration(seconds: 3));
      expect(backoffDelay(0), const Duration(seconds: 2));
    });
  });

  group('DriftSyncRepository', () {
    late FakeSyncServer server;
    late TestDevice d;
    late DriftSyncRepository repo;

    Future<void> setUpRepo() async {
      server = FakeSyncServer();
      d = await TestDevice.create(server);
      addTearDown(d.dispose);
      repo = DriftSyncRepository(db: d.db, session: d.session, engine: d.engine);
    }

    test('ringkasan: PENDING terlihat, initial pull belum selesai, lalu selesai setelah sync', () {
      return withFixedClock(() async {
        await setUpRepo();
        await d.newProduct();

        final before = await repo.watchSummary().first;
        expect(before.pendingCount, 1);
        expect(before.initialPullDone, isFalse);
        expect(before.hasUnsynced, isTrue);

        final done = expectLater(
          repo.watchSummary(),
          emitsThrough(predicate<SyncSummary>((s) => s.initialPullDone && s.pendingCount == 0 && !s.isSyncing)),
        );
        await repo.syncNow();
        await done;

        final after = await repo.watchSummary().first;
        expect(after.lastSyncedAt, isNotNull);
        expect(after.isOffline, isFalse);
      });
    });

    test('syncNow bersifat single-flight: panggilan bersamaan berbagi satu siklus', () {
      return withFixedClock(() async {
        await setUpRepo();
        await d.newProduct();

        final first = repo.syncNow();
        final second = repo.syncNow();
        await Future.wait([first, second]);

        expect(identical(first, second), isTrue);
        expect(server.pullCalls, 1);
      });
    });

    test('offline dan issue tercermin di ringkasan; pulih setelah sukses', () {
      return withFixedClock(() async {
        await setUpRepo();
        await d.newProduct();

        server.failWith = const NetworkException();
        await repo.syncNow();
        expect((await repo.watchSummary().first).isOffline, isTrue);

        await repo.syncNow();
        expect((await repo.watchSummary().first).isOffline, isFalse);

        server.failWith = const UnauthorizedException();
        await repo.syncNow();
        expect((await repo.watchSummary().first).issue, SyncIssue.authRequired);
      });
    });

    test('retryFailed mengubah FAILED menjadi PENDING lalu mengirim ulang', () {
      return withFixedClock(() async {
        await setUpRepo();
        final p = await d.newProduct(stock: 5);
        await repo.syncNow();
        await d.move(p, TransactionType.stockOut, 3);
        server.setStock(p, 1);
        await repo.syncNow();
        expect((await repo.watchSummary().first).failedCount, 1);

        server.setStock(p, 10);
        await repo.retryFailed();

        final summary = await repo.watchSummary().first;
        expect(summary.failedCount, 0);
        expect(summary.pendingCount, 0);
        expect(server.stockOf(p), 7);
      });
    });
  });
}
