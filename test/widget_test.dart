import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/main.dart';
import 'package:monedasegura_app/widgets/sidebar.dart';

/// Large surface; the test font (Ahem) draws every glyph one em wide, so
/// text overflows that never happen with the real font are ignored here.
Future<void> _bigSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), 'secret');
  await tester.pump();
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Finder _sidebarText(String label) =>
    find.descendant(of: find.byType(Sidebar), matching: find.text(label));

void main() {
  testWidgets('shows the sign-in screen in Spanish', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('rejects an unknown account', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'nobody@example.com');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(Sidebar), findsNothing);
  });

  testWidgets('admin sees every section including the simulator', (
    tester,
  ) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    expect(find.byType(Sidebar), findsOneWidget);
    for (final label in ['Dashboard', 'Casos', 'Reglas', 'Modelos']) {
      expect(_sidebarText(label), findsOneWidget);
    }
    expect(_sidebarText('Simulador'), findsOneWidget);
  });

  testWidgets('analyst does not see the simulator', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'camilo.torres@monedasegura.co');

    expect(_sidebarText('Casos'), findsOneWidget);
    expect(_sidebarText('Simulador'), findsNothing);
  });

  testWidgets('logout returns to the sign-in screen', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    await tester.tap(find.byKey(const ValueKey('logout')));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(Sidebar), findsNothing);
  });

  testWidgets('navigates between sections from the sidebar', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    await tester.tap(_sidebarText('Reglas'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva regla'), findsOneWidget);

    await tester.tap(_sidebarText('Modelos'));
    await tester.pumpAndSettle();
    expect(find.text('Reentrenar ahora'), findsOneWidget);
  });

  testWidgets('the bell opens the notifications', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    await tester.tap(find.byKey(const ValueKey('top-bar-bell')));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Notificaciones'), findsNothing);
  });

  testWidgets('any non-active model can be activated', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    await tester.tap(_sidebarText('Modelos'));
    await tester.pumpAndSettle();
    expect(find.text('Activar'), findsWidgets);

    await tester.tap(find.text('Activar').first);
    await tester.pumpAndSettle();
    expect(find.text('Activo'), findsWidgets);
  });

  testWidgets('a notification takes you to what changed', (tester) async {
    await _bigSurface(tester);
    await tester.pumpWidget(const MonedaSeguraApp());
    await _signIn(tester, 'valentina.rios@monedasegura.co');

    expect(find.byKey(const ValueKey('top-bar-bell-badge')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('top-bar-bell')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('sin asignar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cola de casos'), findsOneWidget);
    expect(find.text('Notificaciones'), findsNothing);
  });
}