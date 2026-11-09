import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('SignalChip shows its label', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const SignalChip(label: 'Dispositivo nuevo')),
    );
    expect(_color(tester, 'Dispositivo nuevo'), AppColors.textSecondary);
  });
}
