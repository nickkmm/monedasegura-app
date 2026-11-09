import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Row of text tabs on a bottom border; the active tab has a 2 px dark
/// underline.
class MsTabs extends StatelessWidget {
  const MsTabs({
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
        border: Border(bottom: BorderSide(color: MsColors.borderDefault)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: MsSpace.lg),
            MsTab(
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

class MsTab extends StatelessWidget {
  const MsTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: MsSpace.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? MsColors.bgInverse : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: MsText.bodyStrong.copyWith(
              color: active ? MsColors.textPrimary : MsColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
