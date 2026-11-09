import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('LegendItem shows the label and a dot in its color', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const LegendItem(label: 'Bloquear', color: AppColors.statusBlock),
      ),
    );
    expect(_color(tester, 'Bloquear'), AppColors.textSecondary);
    final dot = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == AppColors.statusBlock,
    );
    expect(dot, findsOneWidget);
  });
}
