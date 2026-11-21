import 'package:intl/intl.dart';

final NumberFormat _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// `15000` -> `Rp15.000`. Uang selalu rupiah bulat.
String formatRupiah(int amount) => _rupiah.format(amount);
