import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppTextField),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  return container.decoration! as BoxDecoration;
}

Widget _field({String? errorText, ValueChanged<String>? onChanged}) {
  return SizedBox(
    width: 320,
    child: AppTextField(
      label: 'Correo',
      hintText: 'nombre@banco.co',
      errorText: errorText,
      onChanged: onChanged,
    ),
  );
}

void main() {
  testWidgets('shows the label and the hint', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(_field()));
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('nombre@banco.co'), findsOneWidget);
    final border = _decoration(tester).border! as Border;
    expect(border.top.color, AppColors.borderDefault);
    expect(border.top.width, 1);
  });

  testWidgets('focus shows the accent border and the ring', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(_field()));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final decoration = _decoration(tester);
    final border = decoration.border! as Border;
    expect(border.top.width, 1.5);
    expect(border.top.color, AppColors.borderFocus);
    expect(decoration.boxShadow, AppShadows.focusRing);
  });

  testWidgets('errorText shows the message in red', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(_field(errorText: 'X')));
    expect(
      tester.widget<Text>(find.text('X')).style?.color,
      AppColors.statusBlock,
    );
    final border = _decoration(tester).border! as Border;
    expect(border.top.color, AppColors.statusBlock);
    expect(border.top.width, 1);
  });

  testWidgets('typing calls onChanged', (tester) async {
    await setDesktopView(tester);
    String? typed;
    await tester.pumpWidget(harness(_field(onChanged: (v) => typed = v)));
    await tester.enterText(find.byType(TextField), 'ana@banco.co');
    expect(typed, 'ana@banco.co');
  });
}
