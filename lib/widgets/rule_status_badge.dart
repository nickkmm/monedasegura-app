import 'package:flutter/widgets.dart';

import '../data/labels.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Rule version status badge (Figma "Badge/Rule status" `3:145`), with the
/// same geometry as the verdict badge.
///
/// [status] picks the Spanish label and colors.
class RuleStatusBadge extends StatelessWidget {
  const RuleStatusBadge({super.key, required this.status});

  final RuleStatus status;

  static const double _height = 24;
  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final (Color foreground, Color background) = switch (status) {
      RuleStatus.DRAFT => (AppColors.textSecondary, AppColors.bgSubtle),
      RuleStatus.SHADOW => (AppColors.accent, AppColors.accentSubtle),
      RuleStatus.PENDING_APPROVAL => (
        AppColors.statusReview,
        AppColors.statusReviewBg,
      ),
      RuleStatus.ACTIVE => (AppColors.statusApprove, AppColors.statusApproveBg),
      RuleStatus.RETIRED => (AppColors.textTertiary, AppColors.bgSubtle),
    };

    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTextStyles.badge.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
