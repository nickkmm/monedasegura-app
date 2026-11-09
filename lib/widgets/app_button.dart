import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Gallery button (Figma "Button" `3:101`).
///
/// [label] is the Spanish text. [onPressed] is called on tap; `null`
/// disables the button (40 % opacity, no hover, basic cursor). [variant]
/// picks the colors, [icon] adds a 16 px icon before the label, [expand]
/// makes the button full width and [height] defaults to 40 (44 on sign-in).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.height = 40,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const double _iconSize = 16;

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hover = _hover && enabled;

    final (
      Color? background,
      Color foreground,
      BoxBorder? border,
    ) = switch (widget.variant) {
      AppButtonVariant.primary => (
        hover ? AppColors.bgInverse : AppColors.accent,
        AppColors.textInverse,
        null,
      ),
      AppButtonVariant.secondary => (
        hover ? AppColors.bgHover : AppColors.bgSurface,
        AppColors.textPrimary,
        Border.all(color: AppColors.borderStrong),
      ),
      AppButtonVariant.ghost => (
        hover ? AppColors.bgHover : null,
        hover ? AppColors.textPrimary : AppColors.textSecondary,
        null,
      ),
      AppButtonVariant.danger => (
        hover
            ? AppColors.statusBlock.withValues(alpha: 0.88)
            : AppColors.statusBlock,
        AppColors.textInverse,
        null,
      ),
    };

    Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _iconSize, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: AppTextStyles.bodyStrong.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
    if (!enabled) button = Opacity(opacity: 0.4, child: button);
    return button;
  }
}
