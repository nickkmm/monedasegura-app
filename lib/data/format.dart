import 'models/models.dart';

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

/// Decimal comma, at most 2 decimals and no trailing zeros: 4.1 reads `4,1`
/// and 412 reads `412`.
String formatTrimmed(num v) {
  final fixed = v.toStringAsFixed(2);
  final trimmed = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
  return trimmed.replaceAll('.', ',');
}

String formatScore(double? score) =>
    score == null ? '—' : formatDecimal(score, digits: 2);

/// Takes a ratio: 0.0296 reads `2,96 %`.
String formatPercent(double ratio, {int digits = 2}) =>
    '${formatDecimal(ratio * 100, digits: digits)} %';

const _copFeatures = {'amount', 'spend_24h'};

/// A rule condition's value for reading: `Sí`, `$ 2.000.000`, `0,6`, `a, b`.
String formatConditionValue(String feature, Object value) => switch (value) {
  bool v => v ? 'Sí' : 'No',
  num v when _copFeatures.contains(feature) => formatCop(v.round()),
  // `300,00` reads `300` and `0,60` reads `0,6`.
  num v => formatDecimal(v.toDouble()).replaceFirst(RegExp(r',?0+$'), ''),
  List<Object?> v => v.join(', '),
  _ => value.toString(),
};

/// A rule condition's value as typed: `true`, `2000000`, `0.6`, `a, b`.
String conditionValueText(Object value) => switch (value) {
  num v when v == v.truncate() => v.toInt().toString(),
  num v => v.toString(),
  List<Object?> v => v.join(', '),
  _ => value.toString(),
};

final _numberText = RegExp(r'^(\d{1,3}(\.\d{3})*|\d+)(,\d+)?$');

/// Reads the typed [text] of a condition on [feature] with [op], by the
/// feature's type in [featureCatalog]: `sí` reads `true`, `1.000.000` reads
/// `1000000`, `0,6` reads `0.6` and `WEB, APP` under `in` reads a list.
/// Text that doesn't parse comes back as is, so the condition is incomplete.
Object parseConditionValue(String feature, ConditionOp op, String text) {
  final trimmed = text.trim();
  String? type;
  for (final definition in featureCatalog) {
    if (definition.name == feature) type = definition.type;
  }
  switch (type) {
    case 'boolean':
      return switch (trimmed.toLowerCase()) {
        'sí' || 'si' || 'true' => true,
        'no' || 'false' => false,
        _ => text,
      };
    case 'number' || 'integer':
      if (!_numberText.hasMatch(trimmed)) return text;
      final parts = trimmed.replaceAll('.', '').split(',');
      return parts.length == 1
          ? int.parse(parts.first)
          : double.parse('${parts.first}.${parts.last}');
    case 'string':
      if (op != ConditionOp.inList) return trimmed.isEmpty ? text : trimmed;
      final items = [
        for (final item in trimmed.split(','))
          if (item.trim().isNotEmpty) item.trim(),
      ];
      return items.isEmpty ? text : items;
  }
  return text;
}

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
