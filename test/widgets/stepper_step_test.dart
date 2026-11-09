import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('AppStepper shows checks and colors its connectors', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const AppStepper(
          steps: [
            ('Borrador', StepperStepState.done),
            ('Sombra', StepperStepState.done),
            ('Aprobación', StepperStepState.current),
            ('Activa', StepperStepState.pending),
          ],
        ),
      ),
    );
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons, hasLength(2));
    for (final icon in icons) {
      expect(icon.icon, AppIcons.check);
      expect(icon.color, AppColors.textInverse);
    }
    final connectors = tester
        .widgetList<Container>(
          find.byWidgetPredicate((w) => w is Container && w.color != null),
        )
        .map((c) => c.color)
        .toList();
    expect(connectors, [
      AppColors.bgInverse,
      AppColors.bgInverse,
      AppColors.borderStrong,
    ]);
    expect(
      tester.widget<Text>(find.text('Activa')).style?.color,
      AppColors.textTertiary,
    );
    expect(
      tester.widget<Text>(find.text('Aprobación')).style?.color,
      AppColors.textPrimary,
    );
  });
}
