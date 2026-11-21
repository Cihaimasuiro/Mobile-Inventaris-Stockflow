/// Format nomor transaksi: `[KODE_TOKO]-[TAHUN]-[URUT6]`, mis. `TMJ01-2026-000004`.
///
/// Aturan lengkap: KONTRAK BERSAMA v1, bagian 6. Dipakai oleh repository asli DAN fake
/// supaya perilakunya identik.
library;

/// Lebar urutan (zero-pad). Lebih dari 999999 per tahun tetap valid (digit bertambah).
const int kTransactionSeqWidth = 6;

final RegExp _businessCodePattern = RegExp(r'^[A-Z0-9]{2,10}$');

/// Validasi klien untuk kode toko: huruf besar/angka, 2-10 karakter, tanpa `-`
/// (karena `-` memisah bagian nomor). Aturan server belum dikonfirmasi.
bool isValidBusinessCode(String code) => _businessCodePattern.hasMatch(code);

/// Prefix pencarian: `TMJ01-2026-`.
String transactionNumberPrefix(String businessCode, int year) => '$businessCode-$year-';

String formatTransactionNumber(String businessCode, int year, int seq) =>
    '${transactionNumberPrefix(businessCode, year)}${seq.toString().padLeft(kTransactionSeqWidth, '0')}';

/// Urutan tertinggi di antara [numbers] yang berawalan [prefix]. 0 jika tidak ada.
int maxSequence(String prefix, Iterable<String> numbers) {
  var max = 0;
  for (final number in numbers) {
    if (!number.startsWith(prefix)) continue;
    final seq = int.tryParse(number.substring(prefix.length));
    if (seq != null && seq > max) max = seq;
  }
  return max;
}
