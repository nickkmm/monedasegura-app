import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material 3 theme built on the prototype tokens.
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: MsColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: MsColors.accent,
        onPrimary: MsColors.textInverse,
        surface: MsColors.bgSurface,
        onSurface: MsColors.textPrimary,
        error: MsColors.block,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: MsText.family,
    scaffoldBackgroundColor: MsColors.bgCanvas,
    splashFactory: NoSplash.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: MsColors.accent,
    ),
  );
}
