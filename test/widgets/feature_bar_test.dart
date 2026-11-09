import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Finder _box(Color color) => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).color == color,
);

void main() {
  testWidgets('FeatureBar fills the given fraction of the track', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 300,
          child: FeatureBar(
            label: 'amount_zscore',
            valueLabel: '0,42',
            fraction: 0.5,
          ),
        ),
      ),
    );
    expect(_color(tester, 'amount_zscore'), AppColors.textPrimary);
    expect(_color(tester, '0,42'), AppColors.textSecondary);
    final track = tester.getSize(_box(AppColors.bgSubtle));
    final fill = tester.getSize(_box(AppColors.accent));
    expect(track.width, 300);
    expect(fill.width, track.width / 2);
  });
}
