import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// The models content: the production model, the decision thresholds, the
/// version registry and the feature importance. Shows only what it is given
/// and reports the retrain tap up.
class ModelsPage extends StatelessWidget {
  const ModelsPage({
    super.key,
    required this.models,
    required this.activeModel,
    required this.reviewThreshold,
    required this.blockThreshold,
    required this.now,
    required this.onRetrain,
  });

  /// Newest first.
  final List<ModelVersion> models;
  final ModelVersion? activeModel;
  final double reviewThreshold;
  final double blockThreshold;
  final DateTime now;

  /// Null when the user cannot retrain.
  final VoidCallback? onRetrain;

  static const double _sideWidth = 360;

  /// The RETIRED version trained most recently before [active].
  ModelVersion? _baseline(ModelVersion active) {
    ModelVersion? baseline;
    for (final model in models) {
      if (model.status != ModelStatus.RETIRED) continue;
      if (!model.trainedAt.isBefore(active.trainedAt)) continue;
      if (baseline == null || model.trainedAt.isAfter(baseline.trainedAt)) {
        baseline = model;
      }
    }
    return baseline;
  }

  @override
  Widget build(BuildContext context) {
    final active = activeModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ProductionCard(
                  model: active,
                  baseline: active == null ? null : _baseline(active),
                  now: now,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(
                width: _sideWidth,
                child: _ThresholdsCard(
                  review: reviewThreshold,
                  block: blockThreshold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _VersionsCard(models: models, onRetrain: onRetrain),
              ),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(
                width: _sideWidth,
                child: _FeatureCard(model: active),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A card heading with its caption 2 px below.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          caption,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ProductionCard extends StatelessWidget {
  const _ProductionCard({
    required this.model,
    required this.baseline,
    required this.now,
  });

  final ModelVersion? model;
  final ModelVersion? baseline;
  final DateTime now;

  static const double _padding = 28;
  static const double _gap = 20;
  static const double _versionGap = 6;

  String _decimalNote(double Function(ModelMetrics m) metric) {
    final base = baseline;
    if (base == null) return '—';
    // Rounded first, so float noise never reads "-0,00".
    final delta = (metric(model!.metrics) - metric(base.metrics)) * 100;
    final rounded = delta.round() / 100;
    final sign = rounded >= 0 ? '+' : '-';
    return '$sign${formatDecimal(rounded.abs())} vs. anterior';
  }

  String _fraudsNote() {
    final base = baseline;
    if (base == null) return '—';
    final delta = model!.fraudsSeen - base.fraudsSeen;
    final sign = delta >= 0 ? '+' : '-';
    return '$sign${formatInt(delta.abs())} vs. anterior';
  }

  @override
  Widget build(BuildContext context) {
    final m = model;
    final header = Text(
      'Modelo en producción',
      style: AppTextStyles.label.copyWith(color: AppColors.onInverseMuted),
    );
    final versionStyle = AppTextStyles.display.copyWith(
      color: AppColors.textInverse,
    );
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.bgInverse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: m == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: _gap),
                Text('Sin modelo activo', style: versionStyle),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [header, StatusPill.model(ModelStatus.ACTIVE)],
                ),
                const SizedBox(height: _gap),
                Text(m.version, style: versionStyle),
                const SizedBox(height: _versionGap),
                Text(
                  'Entrenado ${formatDayAgo(m.trainedAt, now)} a las '
                  '${formatHm(m.trainedAt)} · '
                  '${m.trigger.label.toLowerCase()} · '
                  '${formatInt(m.trainingRows)} transacciones',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.onInverseMuted,
                  ),
                ),
                const SizedBox(height: _gap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MetricTile(
                        label: 'PR-AUC',
                        value: formatDecimal(m.metrics.prAuc),
                        note: _decimalNote((x) => x.prAuc),
                        onInverse: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MetricTile(
                        label: 'Recall',
                        value: formatDecimal(m.metrics.recall),
                        note: _decimalNote((x) => x.recall),
                        onInverse: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MetricTile(
                        label: 'Precisión',
                        value: formatDecimal(m.metrics.precision),
                        note: _decimalNote((x) => x.precision),
                        onInverse: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MetricTile(
                        label: 'Fraudes vistos',
                        value: formatInt(m.fraudsSeen),
                        note: _fraudsNote(),
                        onInverse: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ThresholdsCard extends StatelessWidget {
  const _ThresholdsCard({required this.review, required this.block});

  final double review;
  final double block;

  static const double _barHeight = 10;
  static const double _barRadius = 5;
  static const double _segmentGap = 3;

  Widget _segment(double fraction, Color color) {
    return Expanded(
      flex: (fraction * 1000).round(),
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_barRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textTertiary,
    );
    final reviewText = formatDecimal(review);
    final blockText = formatDecimal(block);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            title: 'Umbrales de decisión',
            caption: 'Según el puntaje de riesgo del modelo',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _segment(review, AppColors.statusApprove),
              const SizedBox(width: _segmentGap),
              _segment(block - review, AppColors.statusReview),
              const SizedBox(width: _segmentGap),
              _segment(1 - block, AppColors.statusBlock),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // "0" and "1" sit at the ends; each threshold sits under the
          // segment boundary it names.
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: tickStyle),
                  Text('1', style: tickStyle),
                ],
              ),
              Align(
                alignment: Alignment(review * 2 - 1, 0),
                child: Text(reviewText, style: tickStyle),
              ),
              Align(
                alignment: Alignment(block * 2 - 1, 0),
                child: Text(blockText, style: tickStyle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ThresholdRow(
            color: AppColors.statusApprove,
            label: 'Aprobar',
            value: '< $reviewText',
          ),
          const SizedBox(height: AppSpacing.md),
          _ThresholdRow(
            color: AppColors.statusReview,
            label: 'Revisar',
            value: '$reviewText – $blockText',
          ),
          const SizedBox(height: AppSpacing.md),
          _ThresholdRow(
            color: AppColors.statusBlock,
            label: 'Bloquear',
            value: '≥ $blockText',
          ),
        ],
      ),
    );
  }
}

/// One legend row of the thresholds card: dot and label, then the range.
class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VersionsCard extends StatelessWidget {
  const _VersionsCard({required this.models, required this.onRetrain});

  final List<ModelVersion> models;
  final VoidCallback? onRetrain;

  static const double _headerHeight = 30;
  static const double _rowHeight = 57;
  static const double _rowPadding = 12;
  static const double _trainedWidth = 130;
  static const double _originWidth = 150;
  static const double _metricWidth = 70;
  static const double _statusWidth = 110;

  String _origin(ModelVersion model) {
    if (model.trigger == ModelTrigger.SCHEDULED) return model.trigger.label;
    final name = model.trainedBy?.fullName.trim();
    if (name == null || name.isEmpty) return model.trigger.label;
    final words = name.split(RegExp(r'\s+'));
    if (words.length == 1) return '${model.trigger.label} · ${words.first}';
    return '${model.trigger.label} · ${words.first} ${words.last[0]}.';
  }

  Widget _row(ModelVersion model) {
    final secondary = AppTextStyles.body.copyWith(
      color: AppColors.textSecondary,
    );
    final primary = AppTextStyles.body.copyWith(color: AppColors.textPrimary);
    Widget cell(double width, Widget child) =>
        SizedBox(width: width, child: child);
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              model.version,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          cell(
            _trainedWidth,
            Text(
              '${formatDayMonth(model.trainedAt)} · '
              '${formatHm(model.trainedAt)}',
              style: secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          cell(
            _originWidth,
            Text(
              _origin(model),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          cell(
            _metricWidth,
            Text(formatDecimal(model.metrics.prAuc), style: primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          cell(
            _metricWidth,
            Text(formatDecimal(model.metrics.recall), style: primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          cell(
            _statusWidth,
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill.model(model.status),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final retrain = onRetrain;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _CardTitle(
                  title: 'Versiones',
                  caption: 'Reentrenamiento automático cada noche a las 02:00',
                ),
              ),
              if (retrain != null)
                AppButton(label: 'Reentrenar ahora', onPressed: retrain),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // "Versión" takes the space the fixed columns leave, so the table
          // fits the card at 1440 px.
          const TableHeaderRow(
            height: _headerHeight,
            horizontalPadding: _rowPadding,
            radius: AppRadius.sm,
            cells: [
              TableHeaderCell(label: 'Versión', flex: true),
              TableHeaderCell(label: 'Entrenado', width: _trainedWidth),
              TableHeaderCell(label: 'Origen', width: _originWidth),
              TableHeaderCell(label: 'PR-AUC', width: _metricWidth),
              TableHeaderCell(label: 'Recall', width: _metricWidth),
              TableHeaderCell(label: 'Estado', width: _statusWidth),
            ],
          ),
          for (final model in models) _row(model),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.model});

  final ModelVersion? model;

  @override
  Widget build(BuildContext context) {
    final m = model;
    final entries = m == null
        ? <MapEntry<String, double>>[]
        : (m.metrics.featureImportance.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)));
    final max = entries.isEmpty ? 0.0 : entries.first.value;
    final fractions = [
      for (final entry in entries) max == 0 ? 0.0 : entry.value / max,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            title: 'Variables más influyentes',
            caption: 'Importancia relativa en la versión activa',
          ),
          if (m == null) ...[
            const SizedBox(height: AppSpacing.lg),
            const EmptyState(
              icon: AppIcons.cpu,
              title: 'Sin modelo activo',
              hint: 'Reentrena para tener una versión en producción.',
            ),
          ] else
            for (var i = 0; i < entries.length; i++) ...[
              const SizedBox(height: AppSpacing.lg),
              FeatureBar(
                label: featureLabel(entries[i].key),
                valueLabel: '${(fractions[i] * 100).round()} %',
                fraction: fractions[i],
              ),
            ],
        ],
      ),
    );
  }
}
