import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ms_icon.dart';

enum MsButtonVariant { primary, secondary, ghost, danger }

/// Button of the gallery: 40 px high (44 on the sign-in form), radius 10.
class MsButton extends StatefulWidget {
  const MsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MsButtonVariant.primary,
    this.fullWidth = false,
    this.height = 40,
    this.icon,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final MsButtonVariant variant;
  final bool fullWidth;
  final double height;
  final MsIconName? icon;

  @override
  State<MsButton> createState() => _MsButtonState();
}

class _MsButtonState extends State<MsButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hover = _hover && enabled;

    Color background;
    Color foreground;
    Border? border;
    switch (widget.variant) {
      case MsButtonVariant.primary:
        background = hover ? MsColors.bgInverse : MsColors.accent;
        foreground = MsColors.textInverse;
      case MsButtonVariant.secondary:
        background = hover ? MsColors.bgHover : MsColors.bgSurface;
        foreground = MsColors.textPrimary;
        border = Border.all(color: MsColors.borderStrong);
      case MsButtonVariant.ghost:
        background = hover ? MsColors.bgHover : Colors.transparent;
        foreground = hover ? MsColors.textPrimary : MsColors.textSecondary;
      case MsButtonVariant.danger:
        background = MsColors.block;
        foreground = MsColors.textInverse;
    }
    final opacity = !enabled
        ? 0.5
        : (widget.variant == MsButtonVariant.danger && hover ? 0.88 : 1.0);

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          MsIcon(widget.icon!, size: 16, color: foreground),
          const SizedBox(width: MsSpace.sm),
        ],
        Text(
          widget.label,
          style: MsText.bodyStrong.copyWith(color: foreground),
        ),
      ],
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: opacity,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: MsSpace.lg),
            decoration: BoxDecoration(
              color: background,
              border: border,
              borderRadius: BorderRadius.circular(MsRadius.md),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
