import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Labeled horizontal bar (Figma "Feature bar" `21:1204`). Its width comes
/// from the parent.
///
/// [label] is shown on the left and [valueLabel] on the right, above a
/// track filled to [fraction] (0 to 1, clamped) of its width.
class FeatureBar extends StatelessWidget {
  const FeatureBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
  });

  final String label;
  final String valueLabel;
  final double fraction;

  static const double _gap = 6;
  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              valueLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        Container(
          height: _height,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.bgSubtle,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
