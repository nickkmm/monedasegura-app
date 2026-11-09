import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('AppCard renders its child on the card surface', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const AppCard(child: Text('Contenido'))));

    expect(find.text('Contenido'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.bgSurface);
    expect(decoration.border, Border.all(color: AppColors.borderDefault));
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.lg));
    expect(container.padding, const EdgeInsets.all(AppSpacing.xl));
  });
}
