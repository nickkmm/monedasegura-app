import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

const _options = [(7, '7 días'), (30, '30 días'), (90, '90 días')];

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  testWidgets('tapping an option reports its value', (tester) async {
    await setDesktopView(tester);
    int? changed;
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<int>(
          options: _options,
          selected: 7,
          onChanged: (v) => changed = v,
        ),
      ),
    );
    expect(_labelColor(tester, '7 días'), AppColors.textPrimary);
    expect(_labelColor(tester, '30 días'), AppColors.textSecondary);
    await tester.tap(find.text('90 días'));
    expect(changed, 90);
  });

  testWidgets('a null onChanged ignores taps', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const AppSegmentedControl<int>(
          options: _options,
          selected: 7,
          onChanged: null,
        ),
      ),
    );
    await tester.tap(find.text('30 días'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_labelColor(tester, '7 días'), AppColors.textPrimary);
    expect(_labelColor(tester, '30 días'), AppColors.textSecondary);
  });

  testWidgets('shows a click cursor only when tappable', (tester) async {
    await setDesktopView(tester);
    MouseCursor cursor() => tester
        .widget<MouseRegion>(
          find
              .descendant(
                of: find.byType(AppSegmentedControl<int>),
                matching: find.byType(MouseRegion),
              )
              .first,
        )
        .cursor;
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<int>(
          options: _options,
          selected: 7,
          onChanged: (_) {},
        ),
      ),
    );
    expect(cursor(), SystemMouseCursors.click);
    await tester.pumpWidget(
      harness(
        const AppSegmentedControl<int>(
          options: _options,
          selected: 7,
          onChanged: null,
        ),
      ),
    );
    expect(cursor(), SystemMouseCursors.basic);
  });
}
