import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('shows the initials in a 32 x 32 circle', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const AppAvatar(initials: 'VR')));
    expect(find.text('VR'), findsOneWidget);
    expect(tester.getSize(find.byType(AppAvatar)), const Size(32, 32));
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppAvatar),
        matching: find.byType(Container),
      ),
    );
    expect((container.decoration! as BoxDecoration).shape, BoxShape.circle);
  });
}
