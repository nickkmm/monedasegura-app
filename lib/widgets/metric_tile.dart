import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Statistic tile with a note line (Figma "Metric tile" `21:1197`; dark
/// variant in the models card `21:1434`).
///
/// [label] names the metric, [value] is the formatted figure and [note] the
/// line under it. [onInverse] gives it the colors for a dark card.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    this.onInverse = false,
  });

  final String label;
  final String value;
  final String note;
  final bool onInverse;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color labelColor,
      Color valueColor,
      Color noteColor,
    ) = onInverse
        ? (
            AppColors.onInverseTile,
            AppColors.onInverseMuted,
            AppColors.textInverse,
            AppColors.onInverseDelta,
          )
        : (
            AppColors.bgCanvas,
            AppColors.textSecondary,
            AppColors.textPrimary,
            AppColors.textSecondary,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: onInverse ? Border.all(color: AppColors.onInverseBorder) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: labelColor)),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTextStyles.title.copyWith(color: valueColor)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.badge.copyWith(color: noteColor)),
        ],
      ),
    );
  }
}
