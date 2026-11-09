import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Text styles from the Figma file. `height` is line height / font size.
abstract final class AppTextStyles {
  /// Login headline.
  static const TextStyle hero = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 52 / 44,
    letterSpacing: -1.1,
  );

  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 40 / 34,
    letterSpacing: -0.85,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 36 / 30,
    letterSpacing: -0.6,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.33,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    letterSpacing: -0.075,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
  );

  /// Table headers and section labels.
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0,
  );
}
