import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppButton),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  return container.decoration! as BoxDecoration;
}

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  testWidgets('each variant shows its default colors', (tester) async {
    await setDesktopView(tester);
    final expected = {
      AppButtonVariant.primary: (AppColors.accent, null, AppColors.textInverse),
      AppButtonVariant.secondary: (
        AppColors.bgSurface,
        Border.all(color: AppColors.borderStrong),
        AppColors.textPrimary,
      ),
      AppButtonVariant.ghost: (null, null, AppColors.textSecondary),
      AppButtonVariant.danger: (
        AppColors.statusBlock,
        null,
        AppColors.textInverse,
      ),
    };
    for (final MapEntry(key: variant, value: colors) in expected.entries) {
      await tester.pumpWidget(
        harness(
          AppButton(label: 'Guardar', onPressed: () {}, variant: variant),
        ),
      );
      expect(find.text('Guardar'), findsOneWidget);
      final decoration = _decoration(tester);
      expect(decoration.color, colors.$1, reason: '$variant background');
      expect(decoration.border, colors.$2, reason: '$variant border');
      expect(_labelColor(tester, 'Guardar'), colors.$3, reason: '$variant');
    }
  });

  testWidgets('hovering the primary button darkens it', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(AppButton(label: 'Guardar', onPressed: () {})),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(AppButton)));
    await tester.pump();
    expect(_decoration(tester).color, AppColors.bgInverse);
  });

  testWidgets('tapping an enabled button calls onPressed', (tester) async {
    await setDesktopView(tester);
    var taps = 0;
    await tester.pumpWidget(
      harness(AppButton(label: 'Guardar', onPressed: () => taps++)),
    );
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('a disabled button is dimmed and ignores taps', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const AppButton(label: 'Guardar', onPressed: null)),
    );
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Guardar'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.4);
  });
}
