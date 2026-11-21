import '../entities/inputs.dart';

const int kMaxProductNameLength = 120;
const int kMaxBarcodeLength = 64;

/// Trim; string kosong menjadi `null` (produk tanpa barcode).
String? normalizeBarcode(String? raw) {
  final trimmed = raw?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Validasi master produk. Kunci peta = nama field input. Kosong = valid.
/// Dipakai form UI, repository asli, dan fake (satu sumber aturan).
Map<String, String> validateProductInput(ProductInput input, {int initialStock = 0}) {
  final errors = <String, String>{};
  final name = input.name.trim();
  if (name.isEmpty) {
    errors['name'] = 'Nama produk wajib diisi.';
  } else if (name.length > kMaxProductNameLength) {
    errors['name'] = 'Nama produk maksimal $kMaxProductNameLength karakter.';
  }
  if (input.unit.trim().isEmpty) errors['unit'] = 'Satuan wajib diisi.';
  if (input.sellingPrice < 0) errors['sellingPrice'] = 'Harga jual tidak boleh negatif.';
  if (input.costPrice < 0) errors['costPrice'] = 'Harga modal tidak boleh negatif.';
  if (initialStock < 0) errors['initialStock'] = 'Stok awal tidak boleh negatif.';
  final barcode = normalizeBarcode(input.skuBarcode);
  if (barcode != null && barcode.length > kMaxBarcodeLength) {
    errors['skuBarcode'] = 'Barcode maksimal $kMaxBarcodeLength karakter.';
  }
  return errors;
}
