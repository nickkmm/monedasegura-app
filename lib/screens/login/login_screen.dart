import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../app/routes.dart';
import 'login_page.dart';

/// The simulated sign-in: owns the typed credentials and the error message.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Escribe tu correo y tu contraseña.');
      return;
    }
    final user = AppScope.read(context).signIn(_email.text, _password.text);
    if (user == null) {
      setState(() => _error = 'Correo o contraseña incorrectos.');
      return;
    }
    Navigator.of(context).pushReplacementNamed(firstAllowedRoute(user));
  }

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      emailController: _email,
      passwordController: _password,
      error: _error,
      loading: false,
      onSubmit: _submit,
    );
  }
}
