/// Sentinel agar `copyWith` bisa membedakan "tidak diubah" dari "set ke null".
///
/// Contoh: `product.copyWith(skuBarcode: null)` menghapus barcode,
/// sedangkan `product.copyWith(name: 'X')` membiarkan barcode apa adanya.
const Object kUnset = Object();
