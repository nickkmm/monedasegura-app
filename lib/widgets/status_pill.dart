import 'package:flutter/widgets.dart';

import '../data/labels.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum StatusTone { success, accent, neutral, warning, danger }

/// Status pill (Figma "Status pill" `21:1235`).
///
/// [tone] picks the colors and [label] is the Spanish text.
/// [StatusPill.model] shows a model version status.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.tone, required this.label});

  StatusPill.model(ModelStatus status, {super.key})
    : tone = switch (status) {
        ModelStatus.ACTIVE => StatusTone.success,
        ModelStatus.CANDIDATE => StatusTone.accent,
        ModelStatus.RETIRED => StatusTone.neutral,
      },
      label = status.label;

  final StatusTone tone;
  final String label;

  static const double _dot = 6;
  static const double _horizontalPadding = 10;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final (Color foreground, Color background) = switch (tone) {
      StatusTone.success => (
        AppColors.statusApprove,
        AppColors.statusApproveBg,
      ),
      StatusTone.accent => (AppColors.accent, AppColors.accentSubtle),
      StatusTone.neutral => (AppColors.textSecondary, AppColors.bgSubtle),
      StatusTone.warning => (AppColors.statusReview, AppColors.statusReviewBg),
      StatusTone.danger => (AppColors.statusBlock, AppColors.statusBlockBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: AppSpacing.xs,
      ),
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
          const SizedBox(width: _gap),
          Text(label, style: AppTextStyles.badge.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
