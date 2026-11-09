import 'package:flutter/painting.dart';

/// Color tokens from the Figma file variables.
abstract final class AppColors {
  static const Color textPrimary = Color(0xFF161B26);
  static const Color textSecondary = Color(0xFF545B69);
  static const Color textTertiary = Color(0xFF8B919D);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFF2B59C3);
  static const Color accentSubtle = Color(0xFFE8EEFA);

  static const Color bgInverse = Color(0xFF14213D);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgCanvas = Color(0xFFF3F4F6);
  static const Color bgSubtle = Color(0xFFE9EBEF);
  static const Color bgHover = Color(0xFFEEF0F3);

  static const Color borderDefault = Color(0xFFDFE2E8);
  static const Color borderStrong = Color(0xFFC5CAD3);
  static const Color borderFocus = Color(0xFF2B59C3);

  static const Color statusApprove = Color(0xFF2F7D55);
  static const Color statusApproveBg = Color(0xFFE5F2EA);
  static const Color statusReview = Color(0xFFB86E00);
  static const Color statusReviewBg = Color(0xFFFBF0DC);
  static const Color statusBlock = Color(0xFFB42318);
  static const Color statusBlockBg = Color(0xFFFBE6E3);

  static const Color navBg = Color(0xFF14213D);
  static const Color navHover = Color(0xFF1D2C4D);
  static const Color navActive = Color(0xFF27385E);
  static const Color navText = Color(0xFFC3CBDA);
  static const Color navTextActive = Color(0xFFFFFFFF);
  static const Color navTextMuted = Color(0xFF7F8AA3);

  /// Text, borders, fills and deltas on dark (inverse) cards.
  static const Color onInverseMuted = Color(0xB8FFFFFF);
  static const Color onInverseBorder = Color(0x29FFFFFF);
  static const Color onInverseFill = Color(0x1FFFFFFF);
  static const Color onInverseTile = Color(0x14FFFFFF);
  static const Color onInverseDelta = Color(0xFF8CD9B2);
}
