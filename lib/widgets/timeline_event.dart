import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Entry of a history timeline (Figma "Timeline event" `21:1214`): a dot,
/// a title and a meta line. Its width comes from the parent.
///
/// [title] says what happened and [meta] who and when.
class TimelineEvent extends StatelessWidget {
  const TimelineEvent({super.key, required this.title, required this.meta});

  final String title;
  final String meta;

  static const double _dot = 10;
  static const double _dotCenter = 10;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _dotCenter - _dot / 2),
          child: Container(
            width: _dot,
            height: _dot,
            decoration: const BoxDecoration(
              color: AppColors.bgInverse,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                meta,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
