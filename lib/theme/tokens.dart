import 'package:flutter/material.dart';

/// Design tokens copied from the Figma prototype variables.
class MsColors {
  const MsColors._();

  static const textPrimary = Color(0xFF161B26);
  static const textSecondary = Color(0xFF545B69);
  static const textTertiary = Color(0xFF8B919D);
  static const textInverse = Color(0xFFFFFFFF);

  static const accent = Color(0xFF2B59C3);
  static const accentSubtle = Color(0xFFE8EEFA);

  static const bgInverse = Color(0xFF14213D);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgCanvas = Color(0xFFF3F4F6);
  static const bgHover = Color(0xFFEEF0F3);
  static const bgSubtle = Color(0xFFE9EBEF);

  static const borderDefault = Color(0xFFDFE2E8);
  static const borderStrong = Color(0xFFC5CAD3);
  static const borderFocus = Color(0xFF2B59C3);

  static const approve = Color(0xFF2F7D55);
  static const approveBg = Color(0xFFE5F2EA);
  static const review = Color(0xFFB86E00);
  static const reviewBg = Color(0xFFFBF0DC);
  static const block = Color(0xFFB42318);
  static const blockBg = Color(0xFFFBE6E3);

  static const navBg = Color(0xFF14213D);
  static const navHover = Color(0xFF1D2C4D);
  static const navActive = Color(0xFF27385E);
  static const navText = Color(0xFFC3CBDA);
  static const navTextActive = Color(0xFFFFFFFF);
  static const navTextMuted = Color(0xFF7F8AA3);

  /// Light green used for positive deltas on the dark model card.
  static const onDarkPositive = Color(0xFF8CD9B2);
}

class MsSpace {
  const MsSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class MsRadius {
  const MsRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double full = 999;
}

/// Text styles of the Figma type scale (Inter).
class MsText {
  const MsText._();

  static const String family = 'Inter';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.85,
    color: MsColors.textPrimary,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.33,
    color: MsColors.textPrimary,
  );
  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.075,
    color: MsColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: MsColors.textPrimary,
  );
  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: MsColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: MsColors.textSecondary,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    color: MsColors.textTertiary,
  );
  static const badge = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: MsColors.textPrimary,
  );
  static const metric = TextStyle(
    fontFamily: family,
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    color: MsColors.textPrimary,
  );
}

class MsShadow {
  const MsShadow._();

  /// Shadow sm: #1212140F, offset (0, 1), blur 2.
  static const sm = [
    BoxShadow(color: Color(0x0F121214), offset: Offset(0, 1), blurRadius: 2),
  ];
}
