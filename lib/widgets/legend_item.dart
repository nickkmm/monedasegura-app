import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Chart legend entry (Figma "Legend item" `32:1382`).
///
/// [color] fills the dot and [label] is the Spanish text next to it.
class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
