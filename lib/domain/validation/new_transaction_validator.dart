import '../entities/inputs.dart';

const int kMaxNotesLength = 500;

/// Validasi transaksi baru. Kunci: `items` (daftar) atau `items[i]` (baris), `notes`.
Map<String, String> validateNewTransaction(NewTransaction input) {
  final errors = <String, String>{};
  if (input.items.isEmpty) {
    errors['items'] = 'Tambahkan minimal 1 produk.';
  }
  for (var i = 0; i < input.items.length; i++) {
    if (input.items[i].quantity < 1) {
      errors['items[$i]'] = 'Jumlah minimal 1.';
    }
  }
  if ((input.notes?.length ?? 0) > kMaxNotesLength) {
    errors['notes'] = 'Catatan maksimal $kMaxNotesLength karakter.';
  }
  return errors;
}

/// Gabungkan item dengan productId sama (kuantitas dijumlah), urutan kemunculan pertama dipertahankan.
List<NewTransactionItem> mergeTransactionItems(List<NewTransactionItem> items) {
  final totals = <String, int>{};
  for (final item in items) {
    totals.update(item.productId, (qty) => qty + item.quantity, ifAbsent: () => item.quantity);
  }
  return [for (final entry in totals.entries) NewTransactionItem(productId: entry.key, quantity: entry.value)];
}
