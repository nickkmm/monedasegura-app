import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

BoxDecoration? _tabDecoration(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.widgetWithText(AppTab, label),
      matching: find.byType(Container),
    ),
  );
  return container.decoration as BoxDecoration?;
}

void main() {
  const labels = ['Resumen', 'Condiciones', 'Historial'];

  testWidgets('tapping the third tab selects index 2', (tester) async {
    await setDesktopView(tester);
    int? selected;
    await tester.pumpWidget(
      harness(
        AppTabBar(
          labels: labels,
          selectedIndex: 0,
          onSelected: (i) => selected = i,
        ),
      ),
    );
    expect(find.byType(AppTab), findsNWidgets(3));
    await tester.tap(find.text('Historial'));
    expect(selected, 2);
  });

  testWidgets('only the selected tab has the 2 px underline', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(AppTabBar(labels: labels, selectedIndex: 1, onSelected: (_) {})),
    );
    final active = (_tabDecoration(tester, 'Condiciones')!.border! as Border);
    expect(active.bottom.width, 2);
    expect(active.bottom.color, AppColors.bgInverse);
    expect(_tabDecoration(tester, 'Resumen')?.border, isNull);
    expect(_tabDecoration(tester, 'Historial')?.border, isNull);
  });
}
