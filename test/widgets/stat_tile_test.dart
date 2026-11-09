import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('StatTile shows the value in primary text by default', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const StatTile(label: 'Precisión', value: '0,91')),
    );
    expect(_color(tester, 'Precisión'), AppColors.textSecondary);
    expect(_color(tester, '0,91'), AppColors.textPrimary);
  });

  testWidgets('StatTile shows the value in the given color', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const StatTile(
          label: 'Bloqueadas',
          value: '42',
          valueColor: AppColors.statusBlock,
        ),
      ),
    );
    expect(_color(tester, '42'), AppColors.statusBlock);
  });
}
