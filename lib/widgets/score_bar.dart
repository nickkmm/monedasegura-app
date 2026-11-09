import 'package:flutter/widgets.dart';

import '../data/format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Score bar (Figma "Score bar" `4:318`): a short track filled by the score
/// and the score text.
///
/// [score] is the model score from 0 to 1 (clamped), or `null` when there
/// is none: the fill is then 8 px and the text `—`. Below 0.6 it is green,
/// from 0.6 to below 0.9 amber and from 0.9 red. [suffix] is appended to
/// the text, e.g. `' · modelo v5'`.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.score, this.suffix = ''});

  final double? score;
  final String suffix;

  static const double _trackWidth = 64;
  static const double _trackHeight = 6;
  static const double _nullFill = 8;

  @override
  Widget build(BuildContext context) {
    final value = score?.clamp(0.0, 1.0);
    final color = switch (value) {
      null => AppColors.statusApprove,
      < 0.6 => AppColors.statusApprove,
      < 0.9 => AppColors.statusReview,
      _ => AppColors.statusBlock,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _trackWidth,
          height: _trackHeight,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.bgSubtle,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Container(
            width: value == null ? _nullFill : value * _trackWidth,
            height: _trackHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatScore(score) + suffix,
          style: AppTextStyles.badge.copyWith(color: color),
        ),
      ],
    );
  }
}
