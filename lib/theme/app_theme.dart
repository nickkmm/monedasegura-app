import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.bgCanvas,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent).copyWith(
      primary: AppColors.accent,
      surface: AppColors.bgSurface,
      error: AppColors.statusBlock,
    ),
    dividerColor: AppColors.borderDefault,
    splashFactory: NoSplash.splashFactory,
    textTheme: const TextTheme(
      displaySmall: AppTextStyles.display,
      headlineSmall: AppTextStyles.title,
      titleMedium: AppTextStyles.heading,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.bodyStrong,
      labelSmall: AppTextStyles.label,
    ),
  );
}
