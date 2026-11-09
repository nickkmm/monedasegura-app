import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Toggle (Figma "Toggle" `3:155`): a 36 x 20 track with a 16 px knob.
///
/// [value] is the current state. [onChanged] receives `!value` on tap;
/// `null` makes the toggle ignore taps.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 36;
  static const double _height = 20;
  static const double _knob = 16;
  static const double _inset = (_height - _knob) / 2;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      toggled: value,
      child: MouseRegion(
        cursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged(!value),
          child: Container(
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(_inset),
            decoration: BoxDecoration(
              color: value ? AppColors.bgInverse : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
