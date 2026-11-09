import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/main.dart';

void main() {
  testWidgets('shows the sign-in screen in Spanish', (tester) async {
    await tester.pumpWidget(const MonedaSeguraApp());

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
