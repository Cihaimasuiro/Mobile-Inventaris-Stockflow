import 'dart:async';

import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_transaction.dart';

/// Penyimpan data in-memory bersama untuk semua fake repository (khusus dev dan tes).
/// Mencerminkan entitas PRD bagian 13. TIDAK dipakai di build produksi.
class FakeBackend {
  FakeBackend({this.ids = const UuidV4Generator()});

  final IdGenerator ids;

  /// Sesi aktif; `null` = belum login.
  AuthSession? session;

  final Map<String, BusinessStatus> _businessStatus = {};
  final List<Product> products = [];
  final List<StockTransaction> transactions = [];

  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  /// Beri tahu semua stream `watch*` bahwa data berubah.
  void notify() => _changes.add(null);

  BusinessStatus statusOf(String businessId) => _businessStatus[businessId] ?? BusinessStatus.active;

  void setBusinessStatus(String businessId, BusinessStatus status) {
    _businessStatus[businessId] = status;
    notify();
  }

  AuthSession requireSession() => session ?? (throw StateError('Belum login (FakeBackend.session null).'));

  /// Stream yang langsung emit nilai sekarang saat di-listen, lalu setiap ada perubahan.
  Stream<T> watch<T>(T Function() read) {
    late StreamController<T> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Product? findProduct(String businessId, String id) {
    for (final p in products) {
      if (p.businessId == businessId && p.id == id) return p;
    }
    return null;
  }

  void replaceProduct(Product updated) {
    final index = products.indexWhere((p) => p.id == updated.id);
    products[index] = updated;
  }

  /// Simulasi push sukses: baris bisnis ini menjadi SYNCED. Baris FAILED ikut berubah
  /// kecuali [includeFailed] false (sync sungguhan hanya mengirim PENDING).
  void markAllSynced(String businessId, {bool includeFailed = true}) {
    bool eligible(SyncStatus s) => s == SyncStatus.pending || (includeFailed && s == SyncStatus.failed);
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      if (p.businessId == businessId && eligible(p.syncStatus)) {
        products[i] = p.copyWith(syncStatus: SyncStatus.synced, syncErrorCode: null);
      }
    }
    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      if (t.businessId == businessId && eligible(t.syncStatus)) {
        transactions[i] = _withSync(t, SyncStatus.synced, null);
      }
    }
    notify();
  }

  /// Simulasi penolakan server untuk satu transaksi.
  void markTransactionFailed(String transactionId, String errorCode) {
    final index = transactions.indexWhere((t) => t.id == transactionId);
    transactions[index] = _withSync(transactions[index], SyncStatus.failed, errorCode);
    notify();
  }

  /// FAILED -> PENDING untuk bisnis ini.
  void retryFailed(String businessId) {
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      if (p.businessId == businessId && p.syncStatus == SyncStatus.failed) {
        products[i] = p.copyWith(syncStatus: SyncStatus.pending, syncErrorCode: null);
      }
    }
    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      if (t.businessId == businessId && t.syncStatus == SyncStatus.failed) {
        transactions[i] = _withSync(t, SyncStatus.pending, null);
      }
    }
    notify();
  }

  StockTransaction _withSync(StockTransaction t, SyncStatus status, String? errorCode) => StockTransaction(
    id: t.id,
    businessId: t.businessId,
    number: t.number,
    type: t.type,
    notes: t.notes,
    createdBy: t.createdBy,
    transactionAt: t.transactionAt,
    createdAt: t.createdAt,
    syncStatus: status,
    syncErrorCode: errorCode,
    items: t.items,
  );
}
