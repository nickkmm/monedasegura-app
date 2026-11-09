import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login_screen.dart';

void main() {
  runApp(const MonedaSeguraApp());
}

/// Root widget. User-facing text is Spanish; code and identifiers are English.
class MonedaSeguraApp extends StatelessWidget {
  const MonedaSeguraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonedaSegura',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4453C9),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
