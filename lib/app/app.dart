import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'routes.dart';

/// Root widget. User-facing text is Spanish; code and identifiers are English.
class MonedaSeguraApp extends StatelessWidget {
  const MonedaSeguraApp({
    super.key,
    required this.store,
    this.initialRoute = AppRoutes.login,
  });

  final AppStore store;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        title: 'MonedaSegura',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAppTheme(),
        initialRoute: initialRoute,
        // Guards the full name once, so '/cases/abc' does not become a stack.
        onGenerateInitialRoutes: (name) => [
          onGenerateRoute(RouteSettings(name: name), store)!,
        ],
        onGenerateRoute: (settings) => onGenerateRoute(settings, store),
      ),
    );
  }
}
