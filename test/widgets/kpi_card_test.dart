import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('KpiCard shows its texts and the delta color', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const KpiCard(
          label: 'Transacciones hoy',
          value: '12.480',
          delta: '+8,2 % vs. ayer',
          deltaColor: AppColors.accent,
        ),
      ),
    );
    expect(find.text('Transacciones hoy'), findsOneWidget);
    expect(find.text('12.480'), findsOneWidget);
    expect(_color(tester, '+8,2 % vs. ayer'), AppColors.accent);
  });
}
