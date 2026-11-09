import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Selectable card (Figma "Option card" `21:1177`). Its width comes from
/// the parent.
///
/// [title] and [subtitle] are the Spanish texts. [selected] gives it the
/// dark colors, or the BLOCK colors when [danger] is also true. [onTap] is
/// called on tap; `null` makes the card ignore taps.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool danger;
  final VoidCallback? onTap;

  static const double _minHeight = 64;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color border, Color titleColor) = switch ((
      selected,
      danger,
    )) {
      (true, true) => (
        AppColors.statusBlockBg,
        AppColors.statusBlock,
        AppColors.statusBlock,
      ),
      (true, false) => (
        AppColors.bgInverse,
        AppColors.bgInverse,
        AppColors.textInverse,
      ),
      (false, _) => (
        AppColors.bgSurface,
        AppColors.borderDefault,
        AppColors.textPrimary,
      ),
    };

    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyStrong.copyWith(color: titleColor),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
