import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

final _now = DateTime(2026, 10, 25, 9, 45);
final _seed = MockSeed.build(_now);

RuleView _rule(String code) =>
    _seed.rules.firstWhere((r) => r.rule.code == code);

void main() {
  // The default test font draws every glyph as a square, which makes the
  // "Pendiente" badge wider than its 130 px cell; measure with Inter.
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await loader.load();
  });

  testWidgets('shows the latest version of a pending rule', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(RuleRow(rule: _rule('NIGHT_TRANSFER'), now: _now)),
    );
    for (final text in [
      'NIGHT_TRANSFER',
      r'Transferencia de noche ≥ $ 2.000.000',
      'v2',
      'Revisar',
      'Pendiente',
      '61',
      '0,52',
      'hoy · Laura Méndez',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('compact shows only the date, untruncated, in its column', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 976,
          child: RuleRow(rule: _rule('VELOCITY_5M'), now: _now, compact: true),
        ),
      ),
    );
    final date = find.text('hace 2 meses');
    expect(date, findsOneWidget);
    expect(find.text('hace 2 meses · Laura Méndez'), findsNothing);
    expect(tester.getSize(date).width, RuleRow.compactDateWidth);
    expect(tester.renderObject<RenderParagraph>(date).didExceedMaxLines, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a draft shows dashes for hits and precision', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(RuleRow(rule: _rule('ATO_PASSWORD_RESET'), now: _now)),
    );
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('tapping calls onTap and hovering highlights the row', (
    tester,
  ) async {
    await setDesktopView(tester);
    var taps = 0;
    await tester.pumpWidget(
      harness(
        RuleRow(rule: _rule('NIGHT_TRANSFER'), now: _now, onTap: () => taps++),
      ),
    );
    await tester.tap(find.byType(RuleRow));
    expect(taps, 1);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(RuleRow)));
    await tester.pump();
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(RuleRow),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          )
          .first,
    );
    expect((container.decoration! as BoxDecoration).color, AppColors.bgHover);
  });
}
