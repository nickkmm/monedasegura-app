import 'package:flutter/widgets.dart';

import '../data/labels.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Decision verdict badge (Figma "Badge/Verdict" `3:129`).
///
/// [verdict] picks the Spanish label and colors. [VerdictBadge.degraded]
/// marks a rules-only decision ("Degradada").
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required Verdict this.verdict});

  const VerdictBadge.degraded({super.key}) : verdict = null;

  /// `null` for a degraded decision.
  final Verdict? verdict;

  static const double _height = 24;
  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final (
      String label,
      Color foreground,
      Color background,
    ) = switch (verdict) {
      Verdict.APPROVE => (
        Verdict.APPROVE.label,
        AppColors.statusApprove,
        AppColors.statusApproveBg,
      ),
      Verdict.REVIEW => (
        Verdict.REVIEW.label,
        AppColors.statusReview,
        AppColors.statusReviewBg,
      ),
      Verdict.BLOCK => (
        Verdict.BLOCK.label,
        AppColors.statusBlock,
        AppColors.statusBlockBg,
      ),
      null => (degradedLabel, AppColors.textSecondary, AppColors.bgSubtle),
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
          Text(label, style: AppTextStyles.badge.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
