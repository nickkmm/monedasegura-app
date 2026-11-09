import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(OptionCard),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('uses the color set of each state', (tester) async {
    await setDesktopView(tester);
    final cases = {
      (false, false): (
        AppColors.bgSurface,
        AppColors.borderDefault,
        AppColors.textPrimary,
      ),
      (true, false): (
        AppColors.bgInverse,
        AppColors.bgInverse,
        AppColors.textInverse,
      ),
      (true, true): (
        AppColors.statusBlockBg,
        AppColors.statusBlock,
        AppColors.statusBlock,
      ),
    };
    for (final MapEntry(key: (selected, danger), value: colors)
        in cases.entries) {
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 280,
            child: OptionCard(
              title: 'Fraude confirmado',
              subtitle: 'No la hizo el cliente',
              selected: selected,
              danger: danger,
            ),
          ),
        ),
      );
      final decoration = _decoration(tester);
      final border = decoration.border! as Border;
      expect(decoration.color, colors.$1);
      expect(border.top.color, colors.$2);
      expect(border.top.width, 1.5);
      expect(
        tester.widget<Text>(find.text('Fraude confirmado')).style?.color,
        colors.$3,
      );
      expect(
        tester.widget<Text>(find.text('No la hizo el cliente')).style?.color,
        AppColors.textTertiary,
      );
      expect(tester.getSize(find.byType(OptionCard)).width, 280);
    }
  });

  testWidgets('tapping calls onTap', (tester) async {
    await setDesktopView(tester);
    var taps = 0;
    await tester.pumpWidget(
      harness(
        OptionCard(
          title: 'Legítima',
          subtitle: 'La hizo el cliente',
          selected: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(OptionCard));
    expect(taps, 1);
  });
}
