import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('TimelineEvent shows the title and the meta', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const TimelineEvent(
          title: 'Enviada a aprobación',
          meta: 'Ana Gómez · 3 nov',
        ),
      ),
    );
    expect(_color(tester, 'Enviada a aprobación'), AppColors.textPrimary);
    expect(_color(tester, 'Ana Gómez · 3 nov'), AppColors.textSecondary);
  });
}
