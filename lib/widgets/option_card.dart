import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Selectable card with a title and a code. Used for simulator scenarios and
/// case labels. [danger] gives the selected state the BLOCK colors.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    required this.code,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final String code;
  final bool selected;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = MsColors.bgSurface;
    Color border = MsColors.borderDefault;
    Color titleColor = MsColors.textPrimary;
    if (selected && danger) {
      background = MsColors.blockBg;
      border = MsColors.block;
      titleColor = MsColors.block;
    } else if (selected) {
      background = MsColors.bgInverse;
      border = MsColors.bgInverse;
      titleColor = MsColors.textInverse;
    }
    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: MsSpace.lg,
            vertical: MsSpace.xs,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(MsRadius.md),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MsText.bodyStrong.copyWith(color: titleColor)),
              const SizedBox(height: MsSpace.xxs),
              Text(
                code,
                style: MsText.caption.copyWith(color: MsColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
