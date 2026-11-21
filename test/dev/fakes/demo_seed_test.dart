import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/dev/fakes/demo_seed.dart';
import 'package:stokflow/dev/fakes/fake_backend.dart';
import 'package:stokflow/dev/fakes/in_memory_auth_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_product_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_sync_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_transaction_repository.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/domain/entities/enums.dart';

/// Menjaga data demo B tetap menampilkan semua kondisi UI penting.
void main() {
  late FakeBackend backend;

  setUp(() async {
    backend = FakeBackend();
    await seedDemoData(backend);
  });

  test('sudah login sebagai toko demo TMJ01', () async {
    final auth = InMemoryAuthRepository(backend);
    expect((await auth.watchSession().first)?.businessCode, 'TMJ01');
  });

  test('ada produk aktif, satu ARCHIVED, dan riwayat transaksi bernomor berurutan', () async {
    final products = InMemoryProductRepository(backend, backend.requireSession);
    final transactions = InMemoryTransactionRepository(backend, backend.requireSession);

    expect((await products.watchProducts().first).length, 5);
    expect((await products.watchProducts(includeArchived: true).first).length, 6);
    final numbers = (await transactions.watchTransactions().first).map((t) => t.number).toList();
    expect(numbers, hasLength(5));
    expect(numbers.every((n) => RegExp(r'^TMJ01-\d{4}-\d{6}$').hasMatch(n)), isTrue);
  });

  test('ringkasan sync menampilkan 1 PENDING dan 1 FAILED', () async {
    final sync = InMemorySyncRepository(backend, backend.requireSession);
    final summary = await sync.watchSummary().first;
    expect(summary.pendingCount, 1);
    expect(summary.failedCount, 1);
    expect(summary.hasUnsynced, isTrue);
  });

  test('syncNow mengirim PENDING saja; retryFailed memproses FAILED', () async {
    final sync = InMemorySyncRepository(backend, backend.requireSession);

    await sync.syncNow();
    var summary = await sync.watchSummary().first;
    expect(summary.pendingCount, 0);
    expect(summary.failedCount, 1);

    await sync.retryFailed();
    summary = await sync.watchSummary().first;
    expect(summary.hasUnsynced, isFalse);
    expect(summary.lastSyncedAt, isNotNull);
  });

  test('offline atau issue menahan sync', () async {
    final sync = InMemorySyncRepository(backend, backend.requireSession)..isOffline = true;
    await sync.syncNow();
    expect((await sync.watchSummary().first).pendingCount, 1);
    expect((await sync.watchSummary().first).isOffline, isTrue);
  });

  test('login: password salah ditolak, logout mengosongkan sesi', () async {
    final auth = InMemoryAuthRepository(backend);
    await expectLater(auth.login(identifier: 'a@b.c', password: 'salah'), throwsA(isA<UnauthorizedException>()));

    await auth.logout();
    expect(await auth.watchSession().first, isNull);
    await auth.login(identifier: 'a@b.c', password: 'rahasia1');
    expect((await auth.watchSession().first)?.businessCode, 'TMJ01');
  });

  test('transaksi FAILED membawa kode error server', () async {
    final transactions = InMemoryTransactionRepository(backend, backend.requireSession);
    final failed = (await transactions.watchTransactions().first).where((t) => t.syncStatus == SyncStatus.failed);
    expect(failed.single.syncErrorCode, 'INSUFFICIENT_STOCK');
  });
}
