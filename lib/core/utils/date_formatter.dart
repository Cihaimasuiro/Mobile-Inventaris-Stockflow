import 'package:clock/clock.dart';

const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime local) => '${_two(local.hour)}:${_two(local.minute)}';

/// `18 Nov 2026, 09:43` (waktu lokal HP). Tanpa `intl` locale init supaya aman di tes dan offline.
String formatFullDateTime(DateTime moment) {
  final l = moment.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}, ${_clock(l)}';
}

/// Waktu untuk daftar riwayat: `09:43` (hari ini), `Kemarin, 16:20`, atau `18 Nov 2026, 09:43`.
String formatTransactionTime(DateTime moment, {DateTime? now}) {
  final l = moment.toLocal();
  final today = (now ?? clock.now()).toLocal();
  final day = DateTime(l.year, l.month, l.day);
  final diff = DateTime(today.year, today.month, today.day).difference(day).inDays;
  if (diff == 0) return _clock(l);
  if (diff == 1) return 'Kemarin, ${_clock(l)}';
  return formatFullDateTime(moment);
}
