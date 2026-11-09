import 'package:flutter/painting.dart';

/// Spacing scale in logical pixels.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii in logical pixels.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double full = 999;
}

abstract final class AppShadows {
  /// Figma "MS/Shadow sm".
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F121214), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Input focus ring: rgba(48, 69, 232, 0.12), 4 px, no blur.
  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x1F3045E8), spreadRadius: 4),
  ];
}
