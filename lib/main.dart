import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/mock_data.dart';
import 'data/models.dart';
import 'screens/console_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MonedaSeguraApp());
}

/// Named routes of the app.
class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const console = '/console';
}

/// Root widget. User-facing text is Spanish; code and identifiers are English.
///
/// Holds the signed-in user (in memory only) and the two top-level routes:
/// the sign-in screen and the console.
class MonedaSeguraApp extends StatefulWidget {
  const MonedaSeguraApp({super.key});

  @override
  State<MonedaSeguraApp> createState() => _MonedaSeguraAppState();
}

class _MonedaSeguraAppState extends State<MonedaSeguraApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  AppUser? _user;

  /// Prototype sign-in: a demo account with any non-empty password.
  String? _signIn(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final matches = demoUsers.where((u) => u.email == normalized);
    if (matches.isEmpty) return 'Correo o contraseña incorrectos.';
    _user = matches.first;
    _navigator.currentState?.pushReplacementNamed(AppRoutes.console);
    return null;
  }

  void _signOut() {
    _user = null;
    _navigator.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final user = _user;
    // The console needs a session; anything else shows the sign-in screen.
    if (settings.name == AppRoutes.console && user != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ConsoleScreen(user: user, onLogout: _signOut),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.login),
      builder: (_) => LoginScreen(onSignIn: _signIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonedaSegura',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
