/// Server simulasi untuk tes sync. Mengodekan ASUMSI kontrak target (KONTRAK BERSAMA v1, 7.2-7.3)
/// supaya terukur dan mudah diganti bila hasil capture backend berbeda:
/// idempoten per id, hasil per item, nomor bentrok dinomori ulang, `updated_at` produk naik
/// saat stok berubah, dan stok produk yang sudah ada tidak ditimpa oleh push.
library;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:stokflow/core/errors/app_exception.dart';
import 'package:stokflow/core/storage/app_database.dart';
import 'package:stokflow/core/utils/transaction_number.dart';
import 'package:stokflow/data/datasources/remote/sync_remote.dart';
import 'package:stokflow/data/repositories/drift_product_repository.dart';
import 'package:stokflow/data/repositories/drift_transaction_repository.dart';
import 'package:stokflow/data/repositories/sync_engine.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/entities/inputs.dart';
import 'package:stokflow/domain/entities/product.dart';

const testSession = AuthSession(
  userId: 'user-a',
  userName: 'Budi',
  businessId: 'biz-a',
  businessCode: 'TMJ01',
  businessName: 'Toko Maju Jaya',
);

class ServerProduct {
  ServerProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
    this.sku,
    this.unit = 'pcs',
    this.cost = 0,
    this.sell = 0,
    this.status = ProductStatus.active,
  });

  final String id;
  String? sku;
  String name;
  String unit;
  int cost;
  int sell;
  int stock;
  ProductStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
}

class ServerTransaction {
  ServerTransaction({
    required this.id,
    required this.number,
    required this.type,
    required this.at,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String number;
  final TransactionType type;
  final DateTime at;
  final DateTime createdAt;
  final List<TransactionItemPush> items;
}

class FakeSyncServer implements SyncRemote {
  FakeSyncServer({this.businessId = 'biz-a', this.pageSize = 100});

  final String businessId;
  int pageSize;
  final Map<String, ServerProduct> products = {};
  final List<ServerTransaction> transactions = [];

  /// Dilempar SEKALI pada panggilan jaringan berikutnya.
  Object? failWith;

  /// Gagal (NetworkException) saat meminta halaman pull ke-n (0-based).
  int? failOnPullPage;

  final List<ProductPush> pushedProducts = [];
  final List<TransactionPush> pushedTransactions = [];
  int pullCalls = 0;

  int stockOf(String id) => products[id]!.stock;

  void addProduct({required String id, required String name, required int stock, String? sku}) {
    final now = clock.now().toUtc();
    products[id] = ServerProduct(id: id, name: name, stock: stock, sku: sku, createdAt: now, updatedAt: now);
  }

  void setStock(String id, int stock) {
    products[id]!
      ..stock = stock
      ..updatedAt = clock.now().toUtc();
  }

  void addTransaction({required String id, required String number, required String productId, required int qty}) {
    final now = clock.now().toUtc();
    transactions.add(
      ServerTransaction(
        id: id,
        number: number,
        type: TransactionType.stockIn,
        at: now,
        createdAt: now,
        items: [TransactionItemPush(id: '$id-i', productId: productId, quantity: qty, unitCostSnapshot: 0)],
      ),
    );
    setStock(productId, stockOf(productId) + qty);
  }

  void _maybeFail() {
    final error = failWith;
    if (error != null) {
      failWith = null;
      throw error;
    }
  }

  @override
  Future<List<PushItemResult>> pushProducts(List<ProductPush> items) async {
    _maybeFail();
    pushedProducts.addAll(items);
    final results = <PushItemResult>[];
    for (final p in items) {
      final existing = products[p.id];
      if (existing != null) {
        existing
          ..name = p.name
          ..unit = p.unit
          ..cost = p.costPrice
          ..sell = p.sellingPrice
          ..sku = p.skuBarcode
          ..status = p.status
          ..updatedAt = clock.now().toUtc();
        results.add(PushItemResult.ok(p.id));
        continue;
      }
      final duplicate =
          p.skuBarcode != null && products.values.any((o) => o.status == ProductStatus.active && o.sku == p.skuBarcode);
      if (duplicate) {
        results.add(PushItemResult.failed(p.id, 'DUPLICATE_BARCODE'));
        continue;
      }
      products[p.id] = ServerProduct(
        id: p.id,
        name: p.name,
        sku: p.skuBarcode,
        unit: p.unit,
        cost: p.costPrice,
        sell: p.sellingPrice,
        stock: p.initialStock ?? 0,
        status: p.status,
        createdAt: p.createdAt,
        updatedAt: clock.now().toUtc(),
      );
      results.add(PushItemResult.ok(p.id));
    }
    return results;
  }

  @override
  Future<List<PushItemResult>> pushTransactions(List<TransactionPush> items) async {
    _maybeFail();
    pushedTransactions.addAll(items);
    final results = <PushItemResult>[];
    for (final t in items) {
      final existing = transactions.where((x) => x.id == t.id).firstOrNull;
      if (existing != null) {
        results.add(PushItemResult.ok(t.id, serverNumber: existing.number));
        continue;
      }
      if (t.items.any((i) => !products.containsKey(i.productId))) {
        results.add(PushItemResult.failed(t.id, 'PRODUCT_NOT_FOUND'));
        continue;
      }
      if (t.type == TransactionType.stockOut && t.items.any((i) => products[i.productId]!.stock < i.quantity)) {
        results.add(PushItemResult.failed(t.id, 'INSUFFICIENT_STOCK'));
        continue;
      }
      var number = t.number;
      if (transactions.any((x) => x.number == number)) {
        final parts = number.split('-');
        final prefix = transactionNumberPrefix(parts[0], int.parse(parts[1]));
        number = formatTransactionNumber(
          parts[0],
          int.parse(parts[1]),
          maxSequence(prefix, transactions.map((x) => x.number)) + 1,
        );
      }
      final sign = t.type == TransactionType.stockIn ? 1 : -1;
      for (final i in t.items) {
        setStock(i.productId, stockOf(i.productId) + sign * i.quantity);
      }
      transactions.add(
        ServerTransaction(
          id: t.id,
          number: number,
          type: t.type,
          at: t.transactionAt,
          createdAt: clock.now().toUtc(),
          items: t.items,
        ),
      );
      results.add(PushItemResult.ok(t.id, serverNumber: number));
    }
    return results;
  }

  @override
  Future<PullPage> pull({DateTime? since, String? cursor}) async {
    _maybeFail();
    pullCalls++;
    final page = cursor == null ? 0 : int.parse(cursor);
    if (failOnPullPage == page) throw const NetworkException();

    final changedProducts = products.values.where((p) => since == null || !p.updatedAt.isBefore(since)).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final changedTransactions = transactions.where((t) => since == null || !t.createdAt.isBefore(since)).toList();
    final start = page * pageSize;
    final more = changedProducts.length > start + pageSize || changedTransactions.length > start + pageSize;

    return PullPage(
      serverTime: clock.now().toUtc(),
      hasMore: more,
      nextCursor: more ? '${page + 1}' : null,
      products: [
        for (final p in changedProducts.skip(start).take(pageSize))
          PulledProduct(
            id: p.id,
            businessId: businessId,
            skuBarcode: p.sku,
            name: p.name,
            unit: p.unit,
            costPrice: p.cost,
            sellingPrice: p.sell,
            currentStock: p.stock,
            status: p.status,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
          ),
      ],
      transactions: [
        for (final t in changedTransactions.skip(start).take(pageSize))
          PulledTransaction(
            id: t.id,
            businessId: businessId,
            number: t.number,
            type: t.type,
            createdBy: 'server-user',
            transactionAt: t.at,
            createdAt: t.createdAt,
            items: [
              for (final i in t.items)
                PulledItem(
                  id: i.id,
                  productId: i.productId,
                  quantity: i.quantity,
                  unitCostSnapshot: i.unitCostSnapshot,
                ),
            ],
          ),
      ],
    );
  }
}

/// Satu "HP": database lokal sendiri, repository, dan engine, terhubung ke [server].
class TestDevice {
  TestDevice._(this.db, this.session, this.server);

  final AppDatabase db;
  final AuthSession session;
  final FakeSyncServer server;

  late final DriftProductRepository products = DriftProductRepository(db, session);
  late final DriftTransactionRepository transactions = DriftTransactionRepository(db, session);
  late final SyncEngine engine = SyncEngine(db: db, remote: server, session: session);

  static Future<TestDevice> create(FakeSyncServer server, {AuthSession session = testSession}) async {
    // Tes dua-HP membuka dua database in-memory terpisah di satu proses; peringatan drift tidak relevan.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    await db.businessDao.upsert(
      BusinessesCompanion.insert(
        id: session.businessId,
        code: session.businessCode,
        name: session.businessName,
        status: BusinessStatus.active,
        updatedAt: clock.now().toUtc(),
      ),
    );
    return TestDevice._(db, session, server);
  }

  Future<String> newProduct({String name = 'Kopi', int stock = 10, String? barcode}) async => (await products.create(
    ProductInput(name: name, unit: 'pcs', sellingPrice: 1000, costPrice: 500, skuBarcode: barcode),
    initialStock: stock,
  )).id;

  Future<String> move(String productId, TransactionType type, int qty) async => (await transactions.createTransaction(
    NewTransaction(
      type: type,
      items: [NewTransactionItem(productId: productId, quantity: qty)],
    ),
  )).id;

  Future<int> stock(String productId) async => (await products.watchProduct(productId).first)!.currentStock;

  Future<SyncStatus> trxStatus(String id) async => (await transactions.watchTransaction(id).first)!.syncStatus;

  Future<void> dispose() => db.close();
}

/// Input edit dari produk yang ada, dengan nama opsional diganti.
ProductInput inputFrom(Product p, {String? name}) => ProductInput(
  name: name ?? p.name,
  unit: p.unit,
  sellingPrice: p.sellingPrice,
  costPrice: p.costPrice,
  skuBarcode: p.skuBarcode,
);

/// Bungkus tes dengan jam tetap supaya waktu/tahun/nomor deterministik.
Future<T> withFixedClock<T>(Future<T> Function() body) => withClock(Clock.fixed(DateTime.utc(2026, 11, 19, 3)), body);
