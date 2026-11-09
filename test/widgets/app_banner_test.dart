import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('AppBanner shows the leading widget and the message', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const AppBanner(message: 'x', leading: Text('L'))),
    );
    expect(find.text('L'), findsOneWidget);
    expect(_color(tester, 'x'), AppColors.accent);
  });

  testWidgets('AppBanner works without a leading widget', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const AppBanner(message: 'x')));
    expect(find.text('x'), findsOneWidget);
  });
}
