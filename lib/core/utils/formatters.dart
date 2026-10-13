/// Nilai ringkas: bulat tanpa desimal, selain itu 1 desimal. Null menjadi '-'.
String scoreText(double? value) {
  if (value == null) return '-';
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

/// Selisih nilai dengan tanda: +25, -5, 0. Null menjadi '-'.
String deltaText(double? value) {
  if (value == null) return '-';
  return value > 0 ? '+${scoreText(value)}' : scoreText(value);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Contoh: 13 Okt 2026, 14:05 (waktu lokal perangkat).
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour:$minute';
}