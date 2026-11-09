import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../theme/tokens.dart';

/// Model fraud probability. Low < 0.6, Mid 0.6–0.9 (REVIEW), High ≥ 0.9 (BLOCK).
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.score, this.text});

  /// Null when the decision was rules-only; shows an empty track and a dash.
  final double? score;

  /// Overrides the score text, e.g. `0,67 · modelo v5`.
  final String? text;

  static const double trackWidth = 64;

  static Color colorFor(double score) {
    if (score >= 0.9) return MsColors.block;
    if (score >= 0.6) return MsColors.review;
    return MsColors.approve;
  }

  @override
  Widget build(BuildContext context) {
    final value = score;
    final color = value == null ? MsColors.textTertiary : colorFor(value);
    final fill = value == null ? 0.0 : (value.clamp(0.0, 1.0) * trackWidth);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: trackWidth,
          height: 6,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: MsColors.bgSubtle,
            borderRadius: BorderRadius.circular(MsRadius.full),
          ),
          child: Container(
            width: fill,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(MsRadius.full),
            ),
          ),
        ),
        const SizedBox(width: MsSpace.sm),
        Text(
          text ?? formatScore(value),
          style: MsText.badge.copyWith(color: color),
        ),
      ],
    );
  }
}
