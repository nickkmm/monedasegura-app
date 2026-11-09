import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Sidebar row (Figma `4:23`): a 36 px full-width item with an icon and a
/// label.
///
/// [active] marks the current destination and wins over hover. [onTap] is
/// called on tap.
class NavItem extends StatefulWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  static const double _height = 36;

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color? background = widget.active
        ? AppColors.navActive
        : _hover
        ? AppColors.navHover
        : null;
    final foreground = widget.active || _hover
        ? AppColors.navTextActive
        : AppColors.navText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: _height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Icon(widget.icon, size: AppIcons.size, color: foreground),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
