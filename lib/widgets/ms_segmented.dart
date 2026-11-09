import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Segmented control: a subtle track holding one segment per option; the
/// selected one is a white pill with shadow sm.
class MsSegmented<T> extends StatelessWidget {
  const MsSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Value and Spanish label of each segment.
  final List<(T, String)> options;
  final T value;

  /// Null makes the control read-only.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: MsColors.bgSubtle,
        borderRadius: BorderRadius.circular(MsRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null ? null : () => onChanged!(option.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MsSpace.lg,
                  vertical: MsSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: option.$1 == value ? MsColors.bgSurface : null,
                  borderRadius: BorderRadius.circular(MsRadius.sm),
                  boxShadow: option.$1 == value ? MsShadow.sm : null,
                ),
                child: Text(
                  option.$2,
                  style: MsText.bodyStrong.copyWith(
                    color: option.$1 == value
                        ? MsColors.textPrimary
                        : MsColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
