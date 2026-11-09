import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/screens/login/guilloche_painter.dart';
import 'package:monedasegura_app/screens/login/login_page.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';

Finder get _emailField => find.byType(TextField).first;
Finder get _passwordField => find.byType(TextField).last;

Future<void> _submit(
  WidgetTester tester, {
  String email = '',
  String password = '',
}) async {
  await tester.enterText(_emailField, email);
  await tester.enterText(_passwordField, password);
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void _expectDashboardForValentina(WidgetTester tester) {
  expect(find.byType(LoginPage), findsNothing);
  expect(tester.widget<TopBar>(find.byType(TopBar)).title, 'Dashboard');
  expect(find.byType(NavItem), findsNWidgets(5));
  for (final label in [
    'Dashboard',
    'Casos',
    'Reglas',
    'Modelos',
    'Simulador',
  ]) {
    expect(
      find.descendant(of: find.byType(NavItem), matching: find.text(label)),
      findsOneWidget,
    );
  }
  expect(find.text('Valentina Ríos'), findsOneWidget);
  expect(find.text('Administradora'), findsOneWidget);
}

Finder get _guilloche => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is GuillochePainter,
);

Finder get _horizontalScrollView => find.byWidgetPredicate(
  (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
);

void main() {
  testWidgets('a wrong password shows an error and stays on the login', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await _submit(tester, email: _valentina, password: 'wrong');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(store.currentUser, isNull);
  });

  testWidgets('empty fields ask for both without signing in', (tester) async {
    const message = 'Escribe tu correo y tu contraseña.';
    final store = await pumpApp(tester);
    final attempts = {
      'both empty': ('', ''),
      'only spaces in the email': ('   ', MockSeed.demoPassword),
      'missing password': (_valentina, ''),
    };
    for (final MapEntry(key: reason, value: fields) in attempts.entries) {
      await _submit(tester, email: fields.$1, password: fields.$2);
      expect(find.text(message), findsOneWidget, reason: reason);
      expect(store.currentUser, isNull, reason: reason);
    }
  });

  testWidgets('a password of only spaces is an incorrect password', (
    tester,
  ) async {
    await pumpApp(tester);
    await _submit(tester, email: _valentina, password: '   ');
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('the right credentials land on the dashboard', (tester) async {
    await pumpApp(tester);
    await _submit(tester, email: _valentina, password: MockSeed.demoPassword);
    _expectDashboardForValentina(tester);
  });

  testWidgets('pressing Enter in the password field signs in', (tester) async {
    await pumpApp(tester);
    await tester.enterText(_emailField, _valentina);
    await tester.enterText(_passwordField, MockSeed.demoPassword);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    _expectDashboardForValentina(tester);
  });

  testWidgets('the hero paints the guilloche', (tester) async {
    await pumpApp(tester);
    expect(_guilloche, findsOneWidget);
    expect(tester.getSize(_guilloche), const Size(760, 760));

    final ovals = <Paint>[];
    final circles = <double, Paint>{};
    expect(
      tester.renderObject(_guilloche),
      paints..everything((method, arguments) {
        if (method == #drawOval) ovals.add(arguments[1] as Paint);
        if (method == #drawCircle) {
          circles[arguments[1] as double] = arguments[2] as Paint;
        }
        return true;
      }),
    );
    expect(ovals, hasLength(24));
    expect(circles.keys, [59.5, 119.5, 179.5]);
    for (final paint in [...ovals, ...circles.values]) {
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, 1);
    }
    expect(ovals.first.color.a, closeTo(0.09, 0.001));
    expect(circles.values.first.color.a, closeTo(0.07, 0.001));
    expect(ovals.first.color.withValues(alpha: 1), AppColors.textInverse);
  });

  testWidgets('a narrow window scrolls horizontally instead of overflowing', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(_horizontalScrollView, findsNothing);

    tester.view.physicalSize = const Size(900, 700);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_horizontalScrollView, findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('loading disables the button and Enter', (tester) async {
    await _pumpLoadingPage(tester);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    expect(
      tester.widget<AppTextField>(find.byType(AppTextField).last).onSubmitted,
      isNull,
    );
  });
}

Future<void> _pumpLoadingPage(WidgetTester tester) async {
  final email = TextEditingController();
  final password = TextEditingController();
  addTearDown(email.dispose);
  addTearDown(password.dispose);
  await setDesktopView(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: LoginPage(
        emailController: email,
        passwordController: password,
        error: null,
        loading: true,
        onSubmit: () {},
      ),
    ),
  );
}
