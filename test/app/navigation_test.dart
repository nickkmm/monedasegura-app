import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/nav_destination.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/cases/case_detail_screen.dart';
import 'package:monedasegura_app/screens/login/login_page.dart';
import 'package:monedasegura_app/screens/rules/rule_editor_screen.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';
const _lauraCardenas = 'laura.cardenas@monedasegura.co';

String _title(WidgetTester tester) =>
    tester.widget<TopBar>(find.byType(TopBar)).title;

BuildContext _pageContext(WidgetTester tester) {
  final shell = find.byType(AppShell);
  return tester.element(
    shell.evaluate().isNotEmpty ? shell : find.byType(LoginPage),
  );
}

String? _routeName(WidgetTester tester) =>
    ModalRoute.of(_pageContext(tester))!.settings.name;

bool _canPop(WidgetTester tester) =>
    Navigator.of(_pageContext(tester)).canPop();

Future<void> _push(WidgetTester tester, String name) async {
  Navigator.of(_pageContext(tester)).pushNamed(name);
  await tester.pumpAndSettle();
}

Color? _navBackground(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.widgetWithText(NavItem, label),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  return (container.decoration! as BoxDecoration).color;
}

// The shell's own scroll view, the one around the sidebar.
Finder get _horizontalScrollView => find.ancestor(
  of: find.byType(AppSidebar),
  matching: find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  ),
);

void main() {
  // Opening the models and rules screens lays out their tables, feature bars
  // and status badges.
  setUpAll(loadInterFont);

  testWidgets('the sidebar shows only what the permissions allow', (
    tester,
  ) async {
    await pumpApp(tester, signInAs: _camilo, initialRoute: AppRoutes.dashboard);
    for (final label in ['Dashboard', 'Casos', 'Reglas', 'Modelos']) {
      expect(find.widgetWithText(NavItem, label), findsOneWidget);
    }
    expect(find.text('Simulador'), findsNothing);
    expect(find.byType(NavItem), findsNWidgets(4));
  });

  group('guards', () {
    testWidgets('a missing permission redirects to the first destination', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signInAs: _camilo,
        initialRoute: AppRoutes.dashboard,
      );
      await _push(tester, AppRoutes.simulator);
      expect(_title(tester), 'Dashboard');
      expect(_routeName(tester), AppRoutes.dashboard);
    });

    testWidgets('/rules/new needs RULE_WRITE and /rules/<id> RULE_READ', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signInAs: _lauraCardenas,
        initialRoute: AppRoutes.dashboard,
      );
      await _push(tester, AppRoutes.newRule);
      expect(_title(tester), 'Dashboard');
      expect(_routeName(tester), AppRoutes.dashboard);

      await _push(tester, AppRoutes.ruleEditor('abc'));
      expect(_title(tester), 'Regla');
      expect(_routeName(tester), '/rules/abc');
      expect(
        tester.widget<RuleEditorScreen>(find.byType(RuleEditorScreen)).ruleId,
        'abc',
      );
    });

    testWidgets('/rules/new opens a new rule', (tester) async {
      await pumpApp(
        tester,
        signInAs: _valentina,
        initialRoute: AppRoutes.dashboard,
      );
      await _push(tester, AppRoutes.newRule);
      expect(_title(tester), 'Regla');
      expect(_routeName(tester), AppRoutes.newRule);
      expect(
        tester.widget<RuleEditorScreen>(find.byType(RuleEditorScreen)).ruleId,
        isNull,
      );
    });

    testWidgets('an unknown path redirects to the first destination', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signInAs: _valentina,
        initialRoute: AppRoutes.cases,
      );
      for (final name in [
        '/nope',
        '/cases/a/b',
        '/cases/',
        '/rules/',
        '/',
        'dashboard',
        'http://[',
      ]) {
        await _push(tester, name);
        expect(tester.takeException(), isNull, reason: name);
        expect(_title(tester), 'Dashboard', reason: name);
        expect(_routeName(tester), AppRoutes.dashboard, reason: name);
      }
    });

    testWidgets('an id with bad percent-encoding does not throw', (
      tester,
    ) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/cases/%ff');
      expect(tester.takeException(), isNull);
      expect(_title(tester), 'Caso');
    });

    testWidgets('signed out, every route shows the login', (tester) async {
      for (final name in ['/dashboard', '/cases/abc', '/nope', '/']) {
        await pumpApp(tester, initialRoute: name);
        expect(find.byType(LoginPage), findsOneWidget, reason: name);
        expect(find.byType(TopBar), findsNothing, reason: name);
        expect(_routeName(tester), AppRoutes.login, reason: name);
        expect(_canPop(tester), isFalse, reason: name);
        // A new navigator for the next start route.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('/login shows the login even when signed in', (tester) async {
      final store = await pumpApp(tester, signInAs: _valentina);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(store.currentUser, isNotNull);
    });
  });

  group('start route', () {
    testWidgets('a deep link gives one page', (tester) async {
      await pumpApp(tester, signInAs: _camilo, initialRoute: '/cases/abc');
      expect(
        tester.widget<CaseDetailScreen>(find.byType(CaseDetailScreen)).caseId,
        'abc',
      );
      expect(_title(tester), 'Caso');
      expect(_navBackground(tester, 'Casos'), AppColors.navActive);
      expect(_canPop(tester), isFalse);
    });

    testWidgets('a redirected start gives one page', (tester) async {
      await pumpApp(tester, signInAs: _camilo, initialRoute: '/simulator');
      expect(_title(tester), 'Dashboard');
      expect(_routeName(tester), AppRoutes.dashboard);
      expect(_canPop(tester), isFalse);
    });
  });

  testWidgets('tapping each sidebar item opens its screen and marks it', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    final titles = {
      'Dashboard': 'Dashboard',
      'Casos': 'Cola de casos',
      'Reglas': 'Reglas',
      'Modelos': 'Modelos',
      'Simulador': 'Simulador',
    };
    for (final MapEntry(key: label, value: title) in titles.entries) {
      await tester.tap(find.widgetWithText(NavItem, label));
      await tester.pumpAndSettle();
      expect(_title(tester), title);
      expect(_navBackground(tester, label), AppColors.navActive);
      expect(_canPop(tester), isFalse);
    }
  });

  testWidgets('logging out returns to the login', (tester) async {
    final store = await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.cases,
    );
    await _push(tester, AppRoutes.caseDetail('abc'));
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(store.currentUser, isNull);
    expect(tester.takeException(), isNull);
    expect(_canPop(tester), isFalse);
  });

  group('firstAllowedRoute', () {
    testWidgets('returns the first destination of a seed user', (tester) async {
      final store = await pumpApp(tester);
      expect(firstAllowedRoute(store.users.first), AppRoutes.dashboard);
    });

    test('returns the login for a user with no permissions', () {
      const user = AppUser(
        id: 'u',
        fullName: 'Sin Roles',
        email: 'sin.roles@monedasegura.co',
        active: true,
        roles: [],
      );
      expect(firstAllowedRoute(user), AppRoutes.login);
    });
  });

  testWidgets('a narrow window scrolls the shell horizontally', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    expect(_horizontalScrollView, findsNothing);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_horizontalScrollView, findsOneWidget);
  });

  test('destinations keep the sidebar order, routes and permissions', () {
    expect(
      [for (final d in NavDestination.values) (d.route, d.permission)],
      [
        ('/dashboard', PermissionCode.DASHBOARD_READ),
        ('/cases', PermissionCode.CASE_READ),
        ('/rules', PermissionCode.RULE_READ),
        ('/models', PermissionCode.MODEL_READ),
        ('/simulator', PermissionCode.SIMULATOR_RUN),
      ],
    );
  });
}
