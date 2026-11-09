import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Caption label over a Body Strong value.
class DetailField extends StatelessWidget {
  const DetailField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: MsText.caption),
        const SizedBox(height: MsSpace.xxs),
        Text(value, style: MsText.bodyStrong),
      ],
    );
  }
}

/// Canvas tile with a label and a colored Title-size value (simulator stats).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = MsColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MsSpace.lg,
        vertical: MsSpace.md,
      ),
      decoration: BoxDecoration(
        color: MsColors.bgCanvas,
        borderRadius: BorderRadius.circular(MsRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MsText.caption),
          const SizedBox(height: MsSpace.xxs),
          Text(value, style: MsText.title.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

/// Tile with label, Title value and a delta line (backtest and model metrics).
/// [onDark] restyles it for the dark production-model card.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    this.onDark = false,
    this.deltaColor,
  });

  final String label;
  final String value;
  final String delta;
  final bool onDark;

  /// Overrides the delta color (e.g. a negative change).
  final Color? deltaColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = onDark
        ? const Color(0xB8FFFFFF)
        : MsColors.textSecondary;
    final valueColor = onDark ? Colors.white : MsColors.textPrimary;
    final resolvedDeltaColor =
        deltaColor ??
        (onDark ? MsColors.onDarkPositive : MsColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MsSpace.lg,
        vertical: MsSpace.md,
      ),
      decoration: BoxDecoration(
        color: onDark ? const Color(0x14FFFFFF) : MsColors.bgCanvas,
        borderRadius: BorderRadius.circular(MsRadius.md),
        border: onDark ? Border.all(color: const Color(0x29FFFFFF)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MsText.caption.copyWith(color: labelColor)),
          const SizedBox(height: MsSpace.xxs),
          Text(value, style: MsText.title.copyWith(color: valueColor)),
          const SizedBox(height: MsSpace.xxs),
          Text(delta, style: MsText.badge.copyWith(color: resolvedDeltaColor)),
        ],
      ),
    );
  }
}

/// Labeled horizontal bar; [value] (0–1) sets the filled length.
class FeatureBar extends StatelessWidget {
  const FeatureBar({super.key, required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: MsText.body)),
            Text('$percent %', style: MsText.caption),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: MsColors.bgSubtle,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: MsColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small grey chip with a signal, e.g. `amount_vs_avg_30d × 4,1`.
class SignalChip extends StatelessWidget {
  const SignalChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MsSpace.sm,
        vertical: MsSpace.xs,
      ),
      decoration: BoxDecoration(
        color: MsColors.bgSubtle,
        borderRadius: BorderRadius.circular(MsRadius.sm),
      ),
      child: Text(label, style: MsText.caption),
    );
  }
}

/// 8 px colored dot with a caption (chart legend).
class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: MsSpace.sm),
        Text(label, style: MsText.caption),
      ],
    );
  }
}
