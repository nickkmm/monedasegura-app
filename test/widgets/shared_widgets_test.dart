import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/prototype_labels.dart';
import 'package:monedasegura_app/data/models.dart';
import 'package:monedasegura_app/widgets/badges.dart';
import 'package:monedasegura_app/widgets/ms_button.dart';
import 'package:monedasegura_app/widgets/ms_segmented.dart';
import 'package:monedasegura_app/widgets/ms_tabs.dart';
import 'package:monedasegura_app/widgets/option_card.dart';
import 'package:monedasegura_app/widgets/score_bar.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('formatters', () {
    test('use Spanish separators', () {
      expect(formatCop(3250000), '\$ 3.250.000');
      expect(formatScore(0.67), '0,67');
      expect(formatScore(null), '—');
      expect(formatDecimal(4.1, 1), '4,1');
      expect(formatCount(12480), '12.480');
      expect(initialsOf('Andrés Pérez'), 'AP');
    });
  });

  group('MsButton', () {
    testWidgets('calls onPressed when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(MsButton(label: 'Guardar', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Guardar'));
      expect(taps, 1);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const MsButton(label: 'Guardar', onPressed: null)),
      );
      await tester.tap(find.text('Guardar'), warnIfMissed: false);
      expect(find.text('Guardar'), findsOneWidget);
    });
  });

  group('badges', () {
    testWidgets('verdict badges show Spanish labels', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final v in Verdict.values) VerdictBadge(verdict: v),
              const VerdictBadge(verdict: Verdict.approve, degraded: true),
            ],
          ),
        ),
      );
      for (final v in Verdict.values) {
        expect(find.text(verdictLabel(v)), findsOneWidget);
      }
      expect(find.text('Degradada'), findsOneWidget);
    });

    testWidgets('rule status badges show Spanish labels', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final s in RuleStatus.values) RuleStatusBadge(status: s),
            ],
          ),
        ),
      );
      for (final s in RuleStatus.values) {
        expect(find.text(ruleStatusLabel(s)), findsOneWidget);
      }
    });

    testWidgets('status pill shows its label', (tester) async {
      await tester.pumpWidget(
        _host(const StatusPill(label: 'Activo', tone: StatusTone.success)),
      );
      expect(find.text('Activo'), findsOneWidget);
    });
  });

  group('ScoreBar', () {
    test('colors follow the score levels', () {
      expect(ScoreBar.colorFor(0.2), isNot(ScoreBar.colorFor(0.7)));
      expect(ScoreBar.colorFor(0.7), isNot(ScoreBar.colorFor(0.95)));
    });

    testWidgets('shows the formatted score or a dash', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [ScoreBar(score: 0.67), ScoreBar(score: null)],
          ),
        ),
      );
      expect(find.text('0,67'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('OptionCard, MsSegmented and MsTabs', () {
    testWidgets('OptionCard reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          OptionCard(
            title: 'Fraude',
            code: 'CONFIRMED_FRAUD',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Fraude'));
      expect(taps, 1);
    });

    testWidgets('MsSegmented reports the chosen value', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _host(
          MsSegmented<String>(
            options: const [('a', 'Uno'), ('b', 'Dos')],
            value: 'a',
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await tester.tap(find.text('Dos'));
      expect(chosen, 'b');
    });

    testWidgets('MsTabs reports the selected index', (tester) async {
      int? index;
      await tester.pumpWidget(
        _host(
          MsTabs(
            labels: const ['Abiertos', 'Resueltos'],
            selectedIndex: 0,
            onSelected: (i) => index = i,
          ),
        ),
      );
      await tester.tap(find.text('Resueltos'));
      expect(index, 1);
    });
  });
}
