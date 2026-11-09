import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_theme.dart';

/// Wraps [child] in the app theme and the Spanish (Colombia) locale.
Widget harness(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('es', 'CO'),
    supportedLocales: const [Locale('es', 'CO')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Sets a 1440 x 900 desktop view for the rest of the test.
Future<void> setDesktopView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Loads the Inter font, so text measures as in the app. The default test
/// font draws every glyph as a square, which overflows tight cells such as
/// the models screen's status pills and feature bars.
Future<void> loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}
