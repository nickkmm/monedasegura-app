import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/nav_destination.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

const _user = AppUser(
  id: 'u',
  fullName: 'Valentina Ríos',
  email: 'valentina.rios@monedasegura.co',
  active: true,
  roles: [RoleCode.ADMIN],
);

Widget _navItem({bool active = false, VoidCallback? onTap}) => SizedBox(
  width: 208,
  child: NavItem(
    icon: AppIcons.inbox,
    label: 'Casos',
    active: active,
    onTap: onTap ?? () {},
  ),
);

void _expectNavColors(
  WidgetTester tester, {
  required Color? background,
  required Color foreground,
}) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(NavItem),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  expect((container.decoration! as BoxDecoration).color, background);
  expect(tester.widget<Icon>(find.byIcon(AppIcons.inbox)).color, foreground);
  expect(tester.widget<Text>(find.text('Casos')).style?.color, foreground);
}

Future<TestGesture> _hover(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(NavItem)));
  await tester.pump();
  return gesture;
}

void main() {
  group('NavItem', () {
    testWidgets('default colors', (tester) async {
      await setDesktopView(tester);
      await tester.pumpWidget(harness(_navItem()));
      _expectNavColors(tester, background: null, foreground: AppColors.navText);
      expect(tester.getSize(find.byType(NavItem)), const Size(208, 36));
    });

    testWidgets('hover colors', (tester) async {
      await setDesktopView(tester);
      await tester.pumpWidget(harness(_navItem()));
      final gesture = await _hover(tester);
      _expectNavColors(
        tester,
        background: AppColors.navHover,
        foreground: AppColors.navTextActive,
      );

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      _expectNavColors(tester, background: null, foreground: AppColors.navText);
    });

    testWidgets('active colors win over hover', (tester) async {
      await setDesktopView(tester);
      await tester.pumpWidget(harness(_navItem(active: true)));
      _expectNavColors(
        tester,
        background: AppColors.navActive,
        foreground: AppColors.navTextActive,
      );

      await _hover(tester);
      _expectNavColors(
        tester,
        background: AppColors.navActive,
        foreground: AppColors.navTextActive,
      );
    });

    testWidgets('a tap calls onTap', (tester) async {
      await setDesktopView(tester);
      var taps = 0;
      await tester.pumpWidget(harness(_navItem(onTap: () => taps++)));
      await tester.tap(find.byType(NavItem));
      expect(taps, 1);
    });
  });

  testWidgets('TopBar shows its texts at height 72', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const TopBar(title: 'Dashboard', subtitle: 'Hoy')),
    );
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Buscar transacción, cliente…'), findsOneWidget);
    expect(find.byIcon(AppIcons.search), findsOneWidget);
    expect(find.byIcon(AppIcons.bell), findsOneWidget);
    expect(tester.getSize(find.byType(TopBar)).height, 72);
    expect(tester.takeException(), isNull);
  });

  group('AppSidebar', () {
    testWidgets('works alone and renders exactly the given destinations', (
      tester,
    ) async {
      await setDesktopView(tester);
      final navigated = <NavDestination>[];
      var logouts = 0;
      await tester.pumpWidget(
        harness(
          AppSidebar(
            active: NavDestination.cases,
            user: _user,
            destinations: const [NavDestination.rules, NavDestination.cases],
            onNavigate: navigated.add,
            onLogout: () => logouts++,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MonedaSegura'), findsOneWidget);
      expect(find.text('Operación'), findsOneWidget);
      expect(tester.getSize(find.byType(AppSidebar)).width, 240);
      expect(
        [
          for (final item in tester.widgetList<NavItem>(find.byType(NavItem)))
            (item.label, item.active),
        ],
        [('Reglas', false), ('Casos', true)],
      );
      expect(find.text('Valentina Ríos'), findsOneWidget);
      expect(find.text('Administradora'), findsOneWidget);
      expect(find.text('VR'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavItem, 'Reglas'));
      expect(navigated, [NavDestination.rules]);

      expect(tester.getSize(find.byIcon(AppIcons.logout)).width, 20);
      await tester.tap(find.byTooltip('Cerrar sesión'));
      expect(logouts, 1);
    });
  });
}
