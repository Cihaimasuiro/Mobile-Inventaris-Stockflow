import 'package:stokflow/dev/fakes/fake_backend.dart';
import 'package:stokflow/dev/fakes/in_memory_product_repository.dart';
import 'package:stokflow/dev/fakes/in_memory_transaction_repository.dart';
import 'package:stokflow/domain/entities/auth_session.dart';
import 'package:stokflow/domain/entities/enums.dart';
import 'package:stokflow/domain/repositories/product_repository.dart';
import 'package:stokflow/domain/repositories/transaction_repository.dart';

import '../../contract/repository_contract.dart';

class _FakeHarness implements ContractHarness {
  final FakeBackend backend = FakeBackend();

  @override
  ProductRepository products(AuthSession session) => InMemoryProductRepository(backend, () => session);

  @override
  TransactionRepository transactions(AuthSession session) => InMemoryTransactionRepository(backend, () => session);

  @override
  Future<void> setBusinessStatus(AuthSession session, BusinessStatus status) async =>
      backend.setBusinessStatus(session.businessId, status);

  @override
  Future<void> markAllSynced(AuthSession session) async => backend.markAllSynced(session.businessId);

  @override
  Future<void> dispose() async {}
}

void main() => runRepositoryContract('InMemory (fake untuk B)', () async => _FakeHarness());
