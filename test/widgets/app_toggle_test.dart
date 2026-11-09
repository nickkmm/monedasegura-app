import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

final _knob = find.descendant(
  of: find.byType(AppToggle),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).shape == BoxShape.circle,
  ),
);

double _knobCenterX(WidgetTester tester) =>
    tester.getCenter(_knob).dx - tester.getTopLeft(find.byType(AppToggle)).dx;

void main() {
  testWidgets('tapping reports the opposite value', (tester) async {
    await setDesktopView(tester);
    bool? reported;
    await tester.pumpWidget(
      harness(AppToggle(value: false, onChanged: (v) => reported = v)),
    );
    await tester.tap(find.byType(AppToggle));
    expect(reported, isTrue);

    await tester.pumpWidget(
      harness(AppToggle(value: true, onChanged: (v) => reported = v)),
    );
    await tester.tap(find.byType(AppToggle));
    expect(reported, isFalse);
  });

  testWidgets('the knob sits right when on and left when off', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(AppToggle(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppToggle)), const Size(36, 20));
    expect(_knobCenterX(tester), 26);

    await tester.pumpWidget(
      harness(AppToggle(value: false, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(_knobCenterX(tester), 10);
  });

  testWidgets('a null onChanged ignores taps', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const AppToggle(value: false, onChanged: null)),
    );
    await tester.tap(find.byType(AppToggle));
    await tester.pumpAndSettle();
    expect(_knobCenterX(tester), 10);
  });

  testWidgets('shows a click cursor only when tappable', (tester) async {
    await setDesktopView(tester);
    MouseCursor cursor() => tester
        .widget<MouseRegion>(
          find
              .descendant(
                of: find.byType(AppToggle),
                matching: find.byType(MouseRegion),
              )
              .first,
        )
        .cursor;
    await tester.pumpWidget(
      harness(AppToggle(value: false, onChanged: (_) {})),
    );
    expect(cursor(), SystemMouseCursors.click);
    await tester.pumpWidget(
      harness(const AppToggle(value: false, onChanged: null)),
    );
    expect(cursor(), SystemMouseCursors.basic);
  });
}
