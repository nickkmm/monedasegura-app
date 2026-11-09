import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Avatar (Figma "Avatar" `3:149`): a circle with centered initials.
///
/// [initials] is the text, [background] the circle color and [size] its
/// diameter.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.background = AppColors.bgInverse,
    this.size = 32,
  });

  final String initials;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppTextStyles.badge.copyWith(color: AppColors.textInverse),
      ),
    );
  }
}
