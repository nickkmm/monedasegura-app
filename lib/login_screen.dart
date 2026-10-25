import 'package:flutter/material.dart';

/// Placeholder sign-in screen. Wiring to `POST /auth/login`
/// (monedasegura-infra/docs/api/decision-api.yaml) comes later.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MonedaSegura',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Iniciar sesión'),
                const SizedBox(height: 24),
                const TextField(
                  decoration: InputDecoration(labelText: 'Correo'),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 24),
                const FilledButton(onPressed: null, child: Text('Entrar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
