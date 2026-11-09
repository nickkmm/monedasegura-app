import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('EmptyState shows its icon, title and hint', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const EmptyState(
          icon: AppIcons.inbox,
          title: 'Sin casos',
          hint: 'No hay casos pendientes.',
        ),
      ),
    );
    expect(find.byIcon(AppIcons.inbox), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Sin casos')).style?.color,
      AppColors.textPrimary,
    );
    final hint = tester.widget<Text>(find.text('No hay casos pendientes.'));
    expect(hint.style?.color, AppColors.textSecondary);
    expect(hint.textAlign, TextAlign.center);
  });
}
