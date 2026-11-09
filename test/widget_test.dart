import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('starts on the sign-in screen in Spanish', (tester) async {
    await pumpApp(tester);

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.textContaining('Detén el fraude'), findsOneWidget);
    expect(find.text('MonedaSegura'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
