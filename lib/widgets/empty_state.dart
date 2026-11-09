import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Placeholder for a view without data (Figma "Empty state" `32:1442`).
///
/// [icon] is shown in a grey circle, above the [title] and the centered
/// [hint].
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  static const double _circle = 48;
  static const double _icon = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _circle,
          height: _circle,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.bgSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: _icon, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
