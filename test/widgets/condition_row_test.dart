import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

Widget _sized(Widget child) => SizedBox(width: 800, child: child);

void main() {
  testWidgets('read-only shows feature, operator and a COP amount', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        _sized(
          const ConditionRow(
            condition: Condition('amount', ConditionOp.gte, 2000000),
          ),
        ),
      ),
    );
    expect(find.text('amount'), findsOneWidget);
    expect(find.text('≥'), findsOneWidget);
    expect(find.text(r'$ 2.000.000'), findsOneWidget);
    expect(find.byIcon(AppIcons.close), findsNothing);
    expect(find.byIcon(AppIcons.chevronDown), findsNothing);
  });

  testWidgets('editable dropdowns show a chevron', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        _sized(
          const ConditionRow(
            condition: Condition('amount', ConditionOp.gte, 2000000),
            editable: true,
          ),
        ),
      ),
    );
    final chevrons = find.byIcon(AppIcons.chevronDown);
    expect(chevrons, findsNWidgets(2));
    for (final icon in tester.widgetList<Icon>(chevrons)) {
      expect(icon.size, AppIcons.size);
      expect(icon.color, AppColors.textTertiary);
    }
  });

  testWidgets('read-only formats bools, numbers and lists', (tester) async {
    await setDesktopView(tester);
    final expected = {
      const Condition('is_night', ConditionOp.eq, true): 'Sí',
      const Condition('is_night', ConditionOp.eq, false): 'No',
      const Condition('distance_km', ConditionOp.gt, 300): '300',
      const Condition('score', ConditionOp.gte, 0.6): '0,6',
      const Condition('channel', ConditionOp.inList, ['WEB', 'APP']):
          'WEB, APP',
    };
    for (final MapEntry(key: condition, value: text) in expected.entries) {
      await tester.pumpWidget(
        harness(_sized(ConditionRow(condition: condition))),
      );
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('editable reports value changes and removal', (tester) async {
    await setDesktopView(tester);
    var removed = 0;
    String? value;
    await tester.pumpWidget(
      harness(
        _sized(
          ConditionRow(
            condition: const Condition('amount', ConditionOp.gte, 2000000),
            editable: true,
            featureNames: const ['amount', 'is_night'],
            onFeatureChanged: (_) {},
            onOpChanged: (_) {},
            onValueChanged: (v) => value = v,
            onRemove: () => removed++,
          ),
        ),
      ),
    );
    expect(find.widgetWithText(TextField, '2000000'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.close));
    expect(removed, 1);

    await tester.enterText(find.byType(TextField), '3000000');
    expect(value, '3000000');
  });

  testWidgets('editable feature dropdown reports the selection', (
    tester,
  ) async {
    await setDesktopView(tester);
    String? feature;
    await tester.pumpWidget(
      harness(
        _sized(
          ConditionRow(
            condition: const Condition('amount', ConditionOp.gte, 2000000),
            editable: true,
            featureNames: const ['is_night'],
            onFeatureChanged: (f) => feature = f,
          ),
        ),
      ),
    );
    await tester.tap(find.text('amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('is_night').last);
    await tester.pumpAndSettle();
    expect(feature, 'is_night');
  });
}
