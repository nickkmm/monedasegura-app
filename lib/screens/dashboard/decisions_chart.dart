import 'package:flutter/widgets.dart';

import '../../data/models/models.dart';
import '../../theme/app_colors.dart';

/// Stacked bars of decisions per hour: block on top, review in the middle,
/// approve at the bottom. The tallest hour fills [height].
class DecisionsChart extends StatelessWidget {
  const DecisionsChart({super.key, required this.hourly});

  final List<HourBucket> hourly;

  static const double height = 130;
  static const double _columnGap = 6;

  @override
  Widget build(BuildContext context) {
    var maxTotal = 0;
    for (final b in hourly) {
      final total = b.approve + b.review + b.block;
      if (total > maxTotal) maxTotal = total;
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < hourly.length; i++) ...[
            if (i > 0) const SizedBox(width: _columnGap),
            Expanded(
              key: Key('hour-column-$i'),
              child: _HourColumn(bucket: hourly[i], maxTotal: maxTotal),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({required this.bucket, required this.maxTotal});

  final HourBucket bucket;
  final int maxTotal;

  static const double _segmentGap = 2;
  static const double _radius = 2;

  @override
  Widget build(BuildContext context) {
    final segments = [
      (bucket.block, AppColors.statusBlock),
      (bucket.review, AppColors.statusReview),
      (bucket.approve, AppColors.bgInverse),
    ].where((s) => s.$1 > 0).toList();
    if (segments.isEmpty || maxTotal == 0) return const SizedBox.shrink();

    final available =
        DecisionsChart.height - _segmentGap * (segments.length - 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(height: _segmentGap),
          Container(
            height: available * segments[i].$1 / maxTotal,
            decoration: BoxDecoration(
              color: segments[i].$2,
              borderRadius: BorderRadius.circular(_radius),
            ),
          ),
        ],
      ],
    );
  }
}
