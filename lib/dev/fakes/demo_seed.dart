import 'package:clock/clock.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/inputs.dart';
import 'fake_backend.dart';
import 'in_memory_product_repository.dart';
import 'in_memory_transaction_repository.dart';

/// Sesi toko demo (Toko Maju Jaya, kode TMJ01 sesuai mockup).
const AuthSession kDemoSession = AuthSession(
  userId: 'demo-user',
  userName: 'Budi Santoso',
  businessId: 'demo-biz',
  businessCode: 'TMJ01',
  businessName: 'Toko Maju Jaya',
);

/// Isi [backend] dengan data contoh: sudah login, beberapa produk (termasuk satu ARCHIVED),
/// riwayat transaksi berurutan, satu transaksi PENDING, dan satu FAILED supaya semua
/// kondisi UI bisa dilihat tanpa backend.
Future<void> seedDemoData(FakeBackend backend) async {
  backend.session = kDemoSession;
  final products = InMemoryProductRepository(backend, () => kDemoSession);
  final transactions = InMemoryTransactionRepository(backend, () => kDemoSession);

  Future<String> product(String name, String unit, int cost, int sell, int stock, {String? barcode}) async {
    final p = await products.create(
      ProductInput(name: name, unit: unit, costPrice: cost, sellingPrice: sell, skuBarcode: barcode),
      initialStock: stock,
    );
    return p.id;
  }

  final kopi = await product('Kopi Susu Gula Aren 250ml', 'pcs', 8500, 15000, 25, barcode: '8992753123456');
  final minyak = await product('Minyak Goreng 1L', 'pcs', 14500, 17000, 40, barcode: '8999999000011');
  final beras = await product('Beras Pandan Wangi 5kg', 'pack', 62000, 70000, 12, barcode: '8999999000028');
  final gula = await product('Gula Pasir 1kg', 'kg', 15000, 18000, 30);
  final mie = await product('Mie Instan Goreng', 'dus', 95000, 110000, 3, barcode: '8999999000035');
  final lama = await product('Teh Botol Lama', 'pcs', 4000, 6000, 0);
  await products.archive(lama);

  Future<void> trx(int daysAgo, TransactionType type, Map<String, int> lines, {String? notes}) async {
    final when = clock.now().subtract(Duration(days: daysAgo));
    await withClock(Clock.fixed(when), () async {
      await transactions.createTransaction(
        NewTransaction(
          type: type,
          notes: notes,
          items: [for (final e in lines.entries) NewTransactionItem(productId: e.key, quantity: e.value)],
        ),
      );
    });
  }

  await trx(3, TransactionType.stockIn, {kopi: 10, minyak: 20}, notes: 'Restock mingguan');
  await trx(2, TransactionType.stockOut, {minyak: 5});
  await trx(1, TransactionType.stockOut, {kopi: 3, gula: 2}, notes: 'Pelanggan tetap');
  backend.markAllSynced(kDemoSession.businessId);

  // Satu transaksi menunggu sinkronisasi (PENDING) dan satu ditolak server (FAILED).
  await trx(0, TransactionType.stockIn, {beras: 4});
  await trx(0, TransactionType.stockOut, {mie: 2}, notes: 'Dijual grosir');
  backend.markTransactionFailed(backend.transactions.last.id, 'INSUFFICIENT_STOCK');
}
