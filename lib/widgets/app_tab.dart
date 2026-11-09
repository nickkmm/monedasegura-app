import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Tab (Figma "Tab" `4:323`).
///
/// [label] is the Spanish text. [active] gives it the dark text and the
/// 2 px bottom border. [onTap] is called on tap.
class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  static const double _height = 40;
  static const double _underline = 2;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: _height,
          // The inactive tab reserves the underline's height so the labels
          // stay aligned.
          padding: EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
            bottom: active ? 0 : _underline,
          ),
          alignment: Alignment.center,
          decoration: active
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.bgInverse,
                      width: _underline,
                    ),
                  ),
                )
              : null,
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of [AppTab]s on a 1 px bottom border across the full width.
///
/// [labels] are the tab texts, [selectedIndex] the active tab and
/// [onSelected] receives the index of the tapped tab.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            AppTab(
              label: labels[i],
              active: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}
