import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Segmented control (Figma "Segment" `21:1184`, container `9:969`).
///
/// [options] are the value and Spanish label of each segment and
/// [selected] is the selected value. [onChanged] receives the value of the
/// tapped segment; `null` renders the control read-only.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  static const double _padding = 3;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MouseRegion(
      cursor: onChanged == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: AppColors.bgSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: value == selected ? AppColors.bgSurface : null,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: value == selected ? AppShadows.sm : null,
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: value == selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
