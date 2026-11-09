import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('MetricTile uses light colors by default', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const MetricTile(label: 'AUC', value: '0,94', note: '+0,02')),
    );
    expect(_color(tester, 'AUC'), AppColors.textSecondary);
    expect(_color(tester, '0,94'), AppColors.textPrimary);
    expect(_color(tester, '+0,02'), AppColors.textSecondary);
  });

  testWidgets('MetricTile uses dark-card colors on inverse', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const ColoredBox(
          color: AppColors.bgInverse,
          child: MetricTile(
            label: 'AUC',
            value: '0,94',
            note: '+0,02',
            onInverse: true,
          ),
        ),
      ),
    );
    expect(_color(tester, 'AUC'), AppColors.onInverseMuted);
    expect(_color(tester, '0,94'), AppColors.textInverse);
    expect(_color(tester, '+0,02'), AppColors.onInverseDelta);
    final tile = tester.widget<Container>(
      find.ancestor(of: find.text('AUC'), matching: find.byType(Container)),
    );
    final decoration = tile.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.onInverseTile);
    expect((decoration.border! as Border).top.color, AppColors.onInverseBorder);
  });
}
