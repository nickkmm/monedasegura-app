import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/app.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';

import 'harness.dart';

final kTestNow = DateTime(2026, 10, 25, 9, 45);

/// Pumps the whole app at the desktop view and returns its store.
///
/// Creates a seeded store at [kTestNow] when [store] is null, and signs in
/// with the email [signInAs] and the demo password when given.
Future<AppStore> pumpApp(
  WidgetTester tester, {
  AppStore? store,
  String? signInAs,
  String initialRoute = AppRoutes.login,
}) async {
  await setDesktopView(tester);
  final appStore = store ?? AppStore.seeded(clock: () => kTestNow);
  if (signInAs != null) appStore.signIn(signInAs, MockSeed.demoPassword);
  await tester.pumpWidget(
    MonedaSeguraApp(store: appStore, initialRoute: initialRoute),
  );
  await tester.pumpAndSettle();
  return appStore;
}
