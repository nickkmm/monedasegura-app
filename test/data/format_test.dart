import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/format.dart';

void main() {
  group('numbers', () {
    test('formatInt uses dot thousands', () {
      expect(formatInt(12480), '12.480');
      expect(formatInt(999), '999');
      expect(formatInt(1000), '1.000');
    });

    test('formatCop has a dollar, a space and no decimals', () {
      expect(formatCop(3250000), '\$ 3.250.000');
    });

    test('formatDecimal uses a decimal comma and rounds', () {
      expect(formatDecimal(0.674, digits: 2), '0,67');
      expect(formatDecimal(0.5189), '0,52');
    });

    test('formatTrimmed uses a decimal comma and drops trailing zeros', () {
      expect(formatTrimmed(4.1), '4,1');
      expect(formatTrimmed(412), '412');
      expect(formatTrimmed(3), '3');
      expect(formatTrimmed(2.5), '2,5');
      expect(formatTrimmed(2.50), '2,5');
      expect(formatTrimmed(1.234), '1,23');
    });

    test('formatScore has 2 digits, or an em dash when null', () {
      expect(formatScore(0.674), '0,67');
      expect(formatScore(null), '—');
    });

    test('formatPercent takes a ratio', () {
      expect(formatPercent(37 / 12480, digits: 2), '0,30 %');
      expect(formatPercent(0.0296, digits: 2), '2,96 %');
    });
  });

  group('dates', () {
    final date = DateTime(2026, 10, 25, 9, 41);

    test('formatDateTime', () {
      expect(formatDateTime(date), '25 oct 2026, 09:41');
    });

    test('formatMonthYear', () {
      expect(formatMonthYear(DateTime(2023, 3, 14)), 'mar 2023');
    });

    test('formatDayMonth', () {
      expect(formatDayMonth(date), '25 oct');
    });

    test('formatHm and formatHms pad to 2 digits', () {
      expect(formatHm(DateTime(2026, 10, 25, 2, 0)), '02:00');
      expect(formatHms(DateTime(2026, 10, 25, 9, 52, 14)), '09:52:14');
    });

    test('every month has its Spanish abbreviation', () {
      const months = [
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
      for (var i = 0; i < months.length; i++) {
        expect(formatMonthYear(DateTime(2026, i + 1)), '${months[i]} 2026');
      }
    });
  });

  group('formatAgo', () {
    final now = DateTime(2026, 10, 25, 9, 45);
    String ago(Duration elapsed) => formatAgo(now.subtract(elapsed), now);

    test('under 1 min, and a time after now, read as 1 min', () {
      expect(ago(const Duration(seconds: 30)), 'hace 1 min');
      expect(formatAgo(now.add(const Duration(minutes: 5)), now), 'hace 1 min');
    });

    test('minutes, hours, days and months', () {
      expect(ago(const Duration(minutes: 4)), 'hace 4 min');
      expect(ago(const Duration(minutes: 60)), 'hace 1 h');
      expect(ago(const Duration(hours: 3)), 'hace 3 h');
      expect(ago(const Duration(days: 1)), 'hace 1 d');
      expect(ago(const Duration(days: 9)), 'hace 9 d');
      expect(ago(const Duration(days: 59)), 'hace 59 d');
      expect(ago(const Duration(days: 60)), 'hace 2 meses');
      expect(ago(const Duration(days: 70)), 'hace 2 meses');
    });
  });

  group('formatDayAgo', () {
    final now = DateTime(2026, 10, 25, 9, 45);
    String dayAgo(Duration elapsed) => formatDayAgo(now.subtract(elapsed), now);

    test('same day, at 4 min and 3 h, reads hoy', () {
      expect(dayAgo(const Duration(minutes: 4)), 'hoy');
      expect(dayAgo(const Duration(hours: 3)), 'hoy');
    });

    test('a time after now reads hoy', () {
      expect(formatDayAgo(now.add(const Duration(days: 2)), now), 'hoy');
    });

    test('previous day reads ayer, by calendar date', () {
      expect(dayAgo(const Duration(days: 1)), 'ayer');
      expect(
        formatDayAgo(
          DateTime(2026, 10, 24, 23, 50),
          DateTime(2026, 10, 25, 0, 10),
        ),
        'ayer',
      );
    });

    test('days and months', () {
      expect(dayAgo(const Duration(days: 9)), 'hace 9 d');
      expect(dayAgo(const Duration(days: 12)), 'hace 12 d');
      expect(dayAgo(const Duration(days: 60)), 'hace 2 meses');
      expect(dayAgo(const Duration(days: 70)), 'hace 2 meses');
    });
  });
}
