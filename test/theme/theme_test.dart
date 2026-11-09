import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/theme/app_text_styles.dart';
import 'package:monedasegura_app/theme/app_theme.dart';

import '../helpers/harness.dart';

void _expectStyle(
  TextStyle style, {
  required double size,
  required FontWeight weight,
  required double height,
  required double letterSpacing,
}) {
  expect(style.fontFamily, 'Inter');
  expect(style.color, AppColors.textPrimary);
  expect(style.fontSize, size);
  expect(style.fontWeight, weight);
  expect(style.height, height);
  expect(style.letterSpacing, letterSpacing);
}

void main() {
  test('AppColors match the Figma variables', () {
    expect(AppColors.textPrimary, const Color(0xFF161B26));
    expect(AppColors.textSecondary, const Color(0xFF545B69));
    expect(AppColors.textTertiary, const Color(0xFF8B919D));
    expect(AppColors.textInverse, const Color(0xFFFFFFFF));
    expect(AppColors.accent, const Color(0xFF2B59C3));
    expect(AppColors.accentSubtle, const Color(0xFFE8EEFA));
    expect(AppColors.bgInverse, const Color(0xFF14213D));
    expect(AppColors.bgSurface, const Color(0xFFFFFFFF));
    expect(AppColors.bgCanvas, const Color(0xFFF3F4F6));
    expect(AppColors.bgSubtle, const Color(0xFFE9EBEF));
    expect(AppColors.bgHover, const Color(0xFFEEF0F3));
    expect(AppColors.borderDefault, const Color(0xFFDFE2E8));
    expect(AppColors.borderStrong, const Color(0xFFC5CAD3));
    expect(AppColors.borderFocus, const Color(0xFF2B59C3));
    expect(AppColors.statusApprove, const Color(0xFF2F7D55));
    expect(AppColors.statusApproveBg, const Color(0xFFE5F2EA));
    expect(AppColors.statusReview, const Color(0xFFB86E00));
    expect(AppColors.statusReviewBg, const Color(0xFFFBF0DC));
    expect(AppColors.statusBlock, const Color(0xFFB42318));
    expect(AppColors.statusBlockBg, const Color(0xFFFBE6E3));
    expect(AppColors.navBg, const Color(0xFF14213D));
    expect(AppColors.navHover, const Color(0xFF1D2C4D));
    expect(AppColors.navActive, const Color(0xFF27385E));
    expect(AppColors.navText, const Color(0xFFC3CBDA));
    expect(AppColors.navTextActive, const Color(0xFFFFFFFF));
    expect(AppColors.navTextMuted, const Color(0xFF7F8AA3));
    expect(AppColors.onInverseMuted, const Color(0xB8FFFFFF));
    expect(AppColors.onInverseBorder, const Color(0x29FFFFFF));
    expect(AppColors.onInverseFill, const Color(0x1FFFFFFF));
    expect(AppColors.onInverseTile, const Color(0x14FFFFFF));
    expect(AppColors.onInverseDelta, const Color(0xFF8CD9B2));
  });

  test('AppTextStyles match the Figma text styles', () {
    _expectStyle(
      AppTextStyles.hero,
      size: 44,
      weight: FontWeight.w600,
      height: 52 / 44,
      letterSpacing: -1.1,
    );
    _expectStyle(
      AppTextStyles.display,
      size: 34,
      weight: FontWeight.w600,
      height: 40 / 34,
      letterSpacing: -0.85,
    );
    _expectStyle(
      AppTextStyles.metric,
      size: 30,
      weight: FontWeight.w500,
      height: 36 / 30,
      letterSpacing: -0.6,
    );
    _expectStyle(
      AppTextStyles.title,
      size: 22,
      weight: FontWeight.w600,
      height: 28 / 22,
      letterSpacing: -0.33,
    );
    _expectStyle(
      AppTextStyles.heading,
      size: 15,
      weight: FontWeight.w600,
      height: 22 / 15,
      letterSpacing: -0.075,
    );
    _expectStyle(
      AppTextStyles.body,
      size: 14,
      weight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: 0,
    );
    _expectStyle(
      AppTextStyles.bodyStrong,
      size: 14,
      weight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: 0,
    );
    _expectStyle(
      AppTextStyles.caption,
      size: 12,
      weight: FontWeight.w400,
      height: 16 / 12,
      letterSpacing: 0,
    );
    _expectStyle(
      AppTextStyles.badge,
      size: 12,
      weight: FontWeight.w500,
      height: 16 / 12,
      letterSpacing: 0,
    );
    _expectStyle(
      AppTextStyles.label,
      size: 11,
      weight: FontWeight.w600,
      height: 14 / 11,
      letterSpacing: 0,
    );
  });

  test('AppSpacing, AppRadius and AppShadows hold the Figma values', () {
    expect(
      [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ],
      [2, 4, 8, 12, 16, 24, 32, 48],
    );
    expect(
      [AppRadius.sm, AppRadius.md, AppRadius.lg, AppRadius.full],
      [6, 10, 14, 999],
    );
    expect(AppShadows.sm.single.color, const Color(0x0F121214));
    expect(AppShadows.sm.single.offset, const Offset(0, 1));
    expect(AppShadows.sm.single.blurRadius, 2);
    expect(AppShadows.focusRing.single.color, const Color(0x1F3045E8));
    expect(AppShadows.focusRing.single.spreadRadius, 4);
    expect(AppShadows.focusRing.single.blurRadius, 0);
  });

  test('buildAppTheme uses the canvas, the accent and Inter', () {
    final theme = buildAppTheme();

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.bgCanvas);
    expect(theme.colorScheme.primary, AppColors.accent);
    expect(theme.colorScheme.surface, AppColors.bgSurface);
    expect(theme.colorScheme.error, AppColors.statusBlock);
    expect(theme.dividerColor, AppColors.borderDefault);
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(theme.textTheme.titleLarge!.fontFamily, 'Inter');
    expect(theme.textTheme.displaySmall!.fontSize, 34);
    expect(theme.textTheme.headlineSmall!.fontSize, 22);
    expect(theme.textTheme.titleMedium!.fontSize, 15);
    expect(theme.textTheme.bodyMedium!.fontSize, 14);
    expect(theme.textTheme.bodySmall!.fontSize, 12);
    expect(theme.textTheme.labelLarge!.fontWeight, FontWeight.w500);
    expect(theme.textTheme.labelSmall!.fontSize, 11);
  });

  test('AppIcons has 20 distinct icons of size 20', () {
    expect(AppIcons.size, 20);
    expect(AppIcons.all.length, 20);
    expect(AppIcons.all.toSet().length, 20);
  });

  testWidgets('harness applies the app theme on a desktop view', (
    tester,
  ) async {
    await setDesktopView(tester);
    await tester.pumpWidget(harness(const Icon(AppIcons.shield)));

    final context = tester.element(find.byIcon(AppIcons.shield));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bgCanvas);
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(Localizations.localeOf(context), const Locale('es', 'CO'));
    expect(tester.view.physicalSize, const Size(1440, 900));
    expect(tester.view.devicePixelRatio, 1);
  });
}
