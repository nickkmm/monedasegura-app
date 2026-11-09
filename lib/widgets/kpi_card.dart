import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ms_card.dart';

/// Dashboard KPI: caption label, Metric value and a colored delta line.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final String label;
  final String value;
  final String delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MsText.caption),
          const SizedBox(height: MsSpace.sm),
          Text(value, style: MsText.metric),
          const SizedBox(height: MsSpace.sm),
          Text(delta, style: MsText.badge.copyWith(color: deltaColor)),
        ],
      ),
    );
  }
}
