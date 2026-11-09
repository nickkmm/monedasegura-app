import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/app_scope.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';

const _valentinaEmail = 'valentina.rios@monedasegura.co';

AppStore _store() =>
    AppStore.seeded(clock: () => DateTime(2026, 10, 25, 9, 45));

void main() {
  testWidgets('a widget using of rebuilds when the store notifies', (
    tester,
  ) async {
    final store = _store();
    addTearDown(store.dispose);
    AppStore? seen;
    var builds = 0;

    await tester.pumpWidget(
      AppScope(
        store: store,
        child: Builder(
          builder: (context) {
            seen = AppScope.of(context);
            builds++;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen, same(store));
    expect(builds, 1);

    store.signIn(_valentinaEmail, MockSeed.demoPassword);
    await tester.pump();

    expect(builds, 2);
  });

  testWidgets('a widget using only read gets the store and does not rebuild', (
    tester,
  ) async {
    final store = _store();
    addTearDown(store.dispose);
    AppStore? seen;
    var builds = 0;

    await tester.pumpWidget(
      AppScope(
        store: store,
        child: Builder(
          builder: (context) {
            seen = AppScope.read(context);
            builds++;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen, same(store));
    expect(builds, 1);

    store.signIn(_valentinaEmail, MockSeed.demoPassword);
    await tester.pump();

    expect(builds, 1);
  });

  testWidgets('of and read assert without an AppScope', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    expect(() => AppScope.of(context), throwsAssertionError);
    expect(() => AppScope.read(context), throwsAssertionError);
  });
}
