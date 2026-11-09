import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Finder _fill(Color color) => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).color == color,
);

void main() {
  testWidgets('ScoreBar colors a mid score amber with a proportional fill', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const ScoreBar(score: 0.67)));
    expect(_color(tester, '0,67'), AppColors.statusReview);
    final fill = tester.getSize(_fill(AppColors.statusReview));
    expect(fill.width, closeTo(42.88, 1));
  });

  testWidgets('ScoreBar colors high and low scores', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const ScoreBar(score: 0.96)));
    expect(_color(tester, '0,96'), AppColors.statusBlock);
    await tester.pumpWidget(harness(const ScoreBar(score: 0.3)));
    expect(_color(tester, '0,30'), AppColors.statusApprove);
  });

  testWidgets('ScoreBar shows a dash without a score', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const ScoreBar(score: null)));
    expect(find.text('—'), findsOneWidget);
    expect(_color(tester, '—'), AppColors.statusApprove);
  });

  testWidgets('ScoreBar appends the suffix', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const ScoreBar(score: 0.67, suffix: ' · modelo v5')),
    );
    expect(find.text('0,67 · modelo v5'), findsOneWidget);
  });
}
