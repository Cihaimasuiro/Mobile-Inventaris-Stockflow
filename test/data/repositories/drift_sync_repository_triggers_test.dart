import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/data/repositories/drift_sync_repository.dart';

import 'fake_sync_server.dart';

/// Menunggu sampai [condition] benar (jam nyata; pemicu memakai Timer).
Future<void> eventually(FutureOr<bool> Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Kondisi tidak terpenuhi dalam $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late FakeSyncServer server;
  late TestDevice d;

  setUp(() async {
    server = FakeSyncServer();
    d = await TestDevice.create(server);
    addTearDown(d.dispose);
  });

  test('start(): baris PENDING baru memicu sinkronisasi otomatis setelah debounce', () async {
    final repo = DriftSyncRepository(
      db: d.db,
      session: d.session,
      engine: d.engine,
      tickInterval: const Duration(minutes: 10),
      debounce: const Duration(milliseconds: 20),
    );
    addTearDown(repo.dispose);
    repo.start();

    final id = await d.newProduct();

    await eventually(() => server.products.containsKey(id));
  });

  test('koneksi kembali mengabaikan backoff dan langsung mencoba lagi', () async {
    final restored = StreamController<void>.broadcast();
    addTearDown(restored.close);
    final repo = DriftSyncRepository(
      db: d.db,
      session: d.session,
      engine: d.engine,
      tickInterval: const Duration(minutes: 10),
      debounce: const Duration(minutes: 10),
      connectivityRestored: restored.stream,
    );
    addTearDown(repo.dispose);
    final id = await d.newProduct();

    server.failWith = const NetworkException();
    repo.start();
    await eventually(() async => (await repo.watchSummary().first).isOffline);
    expect(server.products, isEmpty, reason: 'sedang offline dan menunggu backoff beberapa detik');

    restored.add(null);

    await eventually(() => server.products.containsKey(id));
    await eventually(() async => !(await repo.watchSummary().first).isOffline);
  });

  test('issue (mis. perlu login ulang) menghentikan pemicu otomatis', () async {
    final repo = DriftSyncRepository(
      db: d.db,
      session: d.session,
      engine: d.engine,
      tickInterval: const Duration(milliseconds: 30),
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(repo.dispose);
    await d.newProduct();
    server.failWith = const UnauthorizedException();

    repo.start();
    await eventually(() async => (await repo.watchSummary().first).issue != null);
    final pullsAtIssue = server.pullCalls;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(server.pullCalls, pullsAtIssue, reason: 'ticker tidak boleh terus menembak saat butuh tindakan pengguna');
    expect(server.products, isEmpty);
  });
}
