import 'package:flutter/material.dart';

import '../data/prototype_labels.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'ms_icon.dart';
import 'score_bar.dart';
import 'table_parts.dart';

/// One case of the queue: 60 px row with id, customer, amount, type, score,
/// verdict, age and a chevron.
class CaseRow extends StatelessWidget {
  const CaseRow({
    super.key,
    required this.fraudCase,
    required this.onTap,
    this.showBorder = true,
  });

  final FraudCase fraudCase;
  final VoidCallback onTap;
  final bool showBorder;

  /// Width needed by the fixed columns.
  static const double minWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final c = fraudCase;
    return HoverRow(
      height: 60,
      onTap: onTap,
      showBorder: showBorder,
      child: Row(
        children: [
          SizedBox(width: 112, child: Text(c.id, style: MsText.caption)),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 200,
            child: Text(
              c.customerName,
              overflow: TextOverflow.ellipsis,
              style: MsText.bodyStrong,
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 140,
            child: Text(formatCop(c.amount), style: MsText.bodyStrong),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(
            width: 150,
            child: Text(
              c.type,
              overflow: TextOverflow.ellipsis,
              style: MsText.body.copyWith(color: MsColors.textSecondary),
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          SizedBox(width: 120, child: ScoreBar(score: c.score)),
          const SizedBox(width: MsSpace.xl),
          VerdictBadge(verdict: c.verdict),
          const Spacer(),
          SizedBox(
            width: 84,
            child: Text(
              c.ageLabel,
              textAlign: TextAlign.right,
              style: MsText.caption.copyWith(color: MsColors.textTertiary),
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          const MsIcon(MsIconName.chevron, color: MsColors.textTertiary),
        ],
      ),
    );
  }
}
