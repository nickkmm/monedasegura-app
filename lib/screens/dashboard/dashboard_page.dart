import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import 'decisions_chart.dart';

/// The dashboard content: KPIs, decisions per hour, the active model and the
/// recent cases. Shows only what it is given and reports taps up.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.metrics,
    required this.openCases,
    required this.unassignedCases,
    required this.activeModel,
    required this.recentCases,
    required this.now,
    required this.canOpenModels,
    required this.onOpenQueue,
    required this.onOpenCase,
    required this.onOpenModels,
  });

  final DashboardMetrics metrics;
  final int openCases;
  final int unassignedCases;
  final ModelVersion? activeModel;
  final List<CaseView> recentCases;
  final DateTime now;
  final bool canOpenModels;
  final VoidCallback onOpenQueue;
  final ValueChanged<CaseView> onOpenCase;
  final VoidCallback onOpenModels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(
          metrics: metrics,
          openCases: openCases,
          unassignedCases: unassignedCases,
        ),
        const SizedBox(height: AppSpacing.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _DecisionsCard(hourly: metrics.hourly)),
              const SizedBox(width: AppSpacing.lg),
              _ModelCard(
                model: activeModel,
                degraded: (metrics.degradedRate * metrics.decisions).round(),
                now: now,
                onTap: canOpenModels ? onOpenModels : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _RecentCasesCard(
          cases: recentCases,
          now: now,
          onOpenQueue: onOpenQueue,
          onOpenCase: onOpenCase,
        ),
      ],
    );
  }
}

BoxDecoration get _cardDecoration => BoxDecoration(
  color: AppColors.bgSurface,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  border: Border.all(color: AppColors.borderDefault),
);

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.metrics,
    required this.openCases,
    required this.unassignedCases,
  });

  final DashboardMetrics metrics;
  final int openCases;
  final int unassignedCases;

  static const int _latencyTarget = 500;

  String get _decisionsDelta {
    if (metrics.previousDecisions == 0) return '— vs. ayer';
    final ratio = metrics.decisions / metrics.previousDecisions - 1;
    final sign = ratio >= 0 ? '+' : '';
    return '$sign${formatPercent(ratio, digits: 1)} vs. ayer';
  }

  @override
  Widget build(BuildContext context) {
    final blocked = metrics.verdicts[Verdict.BLOCK] ?? 0;
    final blockedRatio = metrics.decisions == 0
        ? 0.0
        : blocked / metrics.decisions;
    final latency = metrics.latencyP95;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: KpiCard(
            label: 'Transacciones hoy',
            value: formatInt(metrics.decisions),
            delta: _decisionsDelta,
            deltaColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: KpiCard(
            label: 'Bloqueadas',
            value: formatInt(blocked),
            delta: '${formatPercent(blockedRatio, digits: 2)} del total',
            deltaColor: AppColors.statusBlock,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: KpiCard(
            label: 'En revisión',
            value: formatInt(openCases),
            delta: '$unassignedCases sin asignar',
            deltaColor: AppColors.statusReview,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: KpiCard(
            label: 'Latencia p95',
            value: '$latency ms',
            delta: 'Objetivo < $_latencyTarget ms',
            deltaColor: latency >= _latencyTarget
                ? AppColors.statusBlock
                : AppColors.statusApprove,
          ),
        ),
      ],
    );
  }
}

class _DecisionsCard extends StatelessWidget {
  const _DecisionsCard({required this.hourly});

  final List<HourBucket> hourly;

  static const _axisLabels = ['00:00', '06:00', '12:00', '18:00', '23:00'];

  @override
  Widget build(BuildContext context) {
    final axisStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textTertiary,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decisiones por hora',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Últimas 24 horas',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const LegendItem(label: 'Aprobadas', color: AppColors.bgInverse),
              const SizedBox(width: AppSpacing.lg),
              const LegendItem(
                label: 'Revisión',
                color: AppColors.statusReview,
              ),
              const SizedBox(width: AppSpacing.lg),
              const LegendItem(
                label: 'Bloqueadas',
                color: AppColors.statusBlock,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DecisionsChart(hourly: hourly),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _axisLabels) Text(label, style: axisStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.degraded,
    required this.now,
    required this.onTap,
  });

  final ModelVersion? model;
  final int degraded;
  final DateTime now;

  /// Null when the user cannot open the models screen.
  final VoidCallback? onTap;

  static const double _width = 340;
  static const double _icon = 20;

  Widget _metricRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.onInverseBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.onInverseMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = model;
    final card = Container(
      width: _width,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.bgInverse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.cpu,
                size: _icon,
                color: AppColors.textInverse,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Modelo activo',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            m?.version ?? 'Sin modelo activo',
            style: AppTextStyles.title.copyWith(color: AppColors.textInverse),
          ),
          const SizedBox(height: AppSpacing.md),
          _metricRow(
            'PR-AUC',
            m == null ? '—' : formatDecimal(m.metrics.prAuc),
          ),
          const SizedBox(height: AppSpacing.md),
          _metricRow(
            'Recall',
            m == null ? '—' : formatDecimal(m.metrics.recall),
          ),
          const SizedBox(height: AppSpacing.md),
          _metricRow(
            'Entrenado',
            m == null
                ? '—'
                : '${formatDayAgo(m.trainedAt, now)} ${formatHm(m.trainedAt)}'
                      ' · ${m.trigger.label.toLowerCase()}',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.onInverseFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.zap,
                  size: _icon,
                  color: AppColors.onInverseMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$degraded decisiones degradadas hoy (solo reglas)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onInverseMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: tap, child: card),
    );
  }
}

class _RecentCasesCard extends StatelessWidget {
  const _RecentCasesCard({
    required this.cases,
    required this.now,
    required this.onOpenQueue,
    required this.onOpenCase,
  });

  final List<CaseView> cases;
  final DateTime now;
  final VoidCallback onOpenQueue;
  final ValueChanged<CaseView> onOpenCase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Casos recientes',
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Ver la cola',
                  variant: AppButtonVariant.ghost,
                  onPressed: onOpenQueue,
                ),
              ],
            ),
          ),
          if (cases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: EmptyState(
                  icon: AppIcons.inbox,
                  title: 'No hay casos abiertos',
                  hint:
                      'Los casos nuevos aparecen aquí apenas el sistema los '
                      'marca.',
                ),
              ),
            )
          else
            // The rows fill the card, or scroll sideways when their cells
            // need more width than it has.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final c in cases)
                          CaseRow(
                            caseView: c,
                            now: now,
                            onTap: () => onOpenCase(c),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
