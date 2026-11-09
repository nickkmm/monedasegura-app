import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

final _now = DateTime(2026, 10, 25, 9, 45);
final _seed = MockSeed.build(_now);

CaseView _case(String prefix) =>
    _seed.cases.firstWhere((c) => c.id.startsWith(prefix));

BoxDecoration _rowDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(CaseRow),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('shows the cells of a review case', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(CaseRow(caseView: _case('b204e7'), now: _now)),
    );
    for (final text in [
      '#B204E7',
      'Andrés P.',
      r'$ 3.250.000',
      'Compra en línea',
      '0,67',
      'En revisión',
      'hace 4 min',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('shows a blocked transfer and a case without score', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(CaseRow(caseView: _case('7f0b6a'), now: _now)),
    );
    expect(find.text('Transferencia'), findsOneWidget);
    expect(find.text('Bloqueada'), findsOneWidget);

    await tester.pumpWidget(
      harness(CaseRow(caseView: _case('09f35b'), now: _now)),
    );
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('tapping calls onTap once', (tester) async {
    await setDesktopView(tester);
    var taps = 0;
    await tester.pumpWidget(
      harness(
        CaseRow(caseView: _case('b204e7'), now: _now, onTap: () => taps++),
      ),
    );
    await tester.tap(find.byType(CaseRow));
    expect(taps, 1);
  });

  testWidgets('hovering highlights the row', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(CaseRow(caseView: _case('b204e7'), now: _now, onTap: () {})),
    );
    expect(_rowDecoration(tester).color, AppColors.bgSurface);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(CaseRow)));
    await tester.pump();
    expect(_rowDecoration(tester).color, AppColors.bgHover);
  });

  testWidgets('without onTap the row has no click cursor', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(CaseRow(caseView: _case('b204e7'), now: _now)),
    );
    final region = tester.widget<MouseRegion>(
      find
          .descendant(
            of: find.byType(CaseRow),
            matching: find.byType(MouseRegion),
          )
          .first,
    );
    expect(region.cursor, isNot(SystemMouseCursors.click));
  });
}
