import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('FilterPill shows its label', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const FilterPill(label: 'Score ≥ 0,60')));
    final text = tester.widget<Text>(find.text('Score ≥ 0,60'));
    expect(text.style?.color, AppColors.textSecondary);
  });

  testWidgets('FilterPill calls onTap when tapped', (tester) async {
    await setDesktopView(tester);
    var taps = 0;
    await tester.pumpWidget(
      harness(FilterPill(label: 'Veredicto: todos', onTap: () => taps++)),
    );
    await tester.tap(find.text('Veredicto: todos'));
    expect(taps, 1);
  });

  testWidgets('FilterPill without onTap builds', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const FilterPill(label: 'Solo lectura')));
    await tester.tap(find.text('Solo lectura'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FilterPill), findsOneWidget);
  });
}
