const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _twoDigits(int n) => n.toString().padLeft(2, '0');

String formatInt(int value) {
  final digits = value.abs().toString();
  final grouped = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return grouped.toString();
}

String formatCop(int amount) => '\$ ${formatInt(amount)}';

String formatDecimal(double v, {int digits = 2}) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

String formatScore(double? score) =>
    score == null ? '—' : formatDecimal(score, digits: 2);

/// Takes a ratio: 0.0296 reads `2,96 %`.
String formatPercent(double ratio, {int digits = 2}) =>
    '${formatDecimal(ratio * 100, digits: digits)} %';

String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String formatHm(DateTime d) => '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';

String formatHms(DateTime d) => '${formatHm(d)}:${_twoDigits(d.second)}';

String formatDateTime(DateTime d) =>
    '${formatDayMonth(d)} ${d.year}, ${formatHm(d)}';

String _agoInDays(int days) =>
    days < 60 ? 'hace $days d' : 'hace ${days ~/ 30} meses';

String formatAgo(DateTime t, DateTime now) {
  final elapsed = now.difference(t);
  if (elapsed.inMinutes < 1) return 'hace 1 min';
  if (elapsed.inMinutes < 60) return 'hace ${elapsed.inMinutes} min';
  if (elapsed.inHours < 24) return 'hace ${elapsed.inHours} h';
  return _agoInDays(elapsed.inDays);
}

String formatDayAgo(DateTime t, DateTime now) {
  // UTC dates have no DST changes, so the difference is whole calendar days.
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'hoy';
  if (days == 1) return 'ayer';
  return _agoInDays(days);
}
