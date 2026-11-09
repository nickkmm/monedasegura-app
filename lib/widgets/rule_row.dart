import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'ms_icon.dart';
import 'table_parts.dart';

/// One rule with its latest version: 64 px row.
class RuleRow extends StatelessWidget {
  const RuleRow({
    super.key,
    required this.rule,
    required this.onTap,
    this.showBorder = true,
  });

  final Rule rule;
  final VoidCallback onTap;
  final bool showBorder;

  /// Width needed by the fixed columns.
  static const double minWidth = 1040;

  @override
  Widget build(BuildContext context) {
    final v = rule.latest;
    final hits = v.hits7d == null ? '—' : formatCount(v.hits7d!);
    final precision = v.precision == null ? '—' : formatDecimal(v.precision!);
    return HoverRow(
      height: 64,
      onTap: onTap,
      showBorder: showBorder,
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MsText.bodyStrong,
                ),
                Text(
                  rule.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MsText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 56,
            child: Text(
              'v${v.number}',
              style: MsText.body.copyWith(color: MsColors.textSecondary),
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 96,
            child: Text(ruleActionLabel(v.action), style: MsText.body),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RuleStatusBadge(status: v.status),
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 90,
            child: Text(
              hits,
              textAlign: TextAlign.right,
              style: MsText.bodyStrong,
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 80,
            child: Text(
              precision,
              textAlign: TextAlign.right,
              style: MsText.bodyStrong,
            ),
          ),
          const Spacer(),
          Text(
            v.updatedLabel,
            style: MsText.caption.copyWith(color: MsColors.textTertiary),
          ),
          const SizedBox(width: MsSpace.lg),
          const MsIcon(MsIconName.chevron, color: MsColors.textTertiary),
        ],
      ),
    );
  }
}
