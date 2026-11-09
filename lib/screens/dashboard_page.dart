import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/case_row.dart';
import '../widgets/data_display.dart';
import '../widgets/kpi_card.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_icon.dart';
import '../widgets/page_frame.dart';
import '../widgets/table_parts.dart';

/// Dashboard: KPIs, decisions per hour, active model and recent cases.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.activeModel,
    required this.recentCases,
    required this.onOpenCase,
    this.onSeeAllCases,
  });

  final ModelVersion? activeModel;
  final List<FraudCase> recentCases;
  final ValueChanged<String> onOpenCase;

  /// Null hides the shortcut (the user cannot read cases).
  final VoidCallback? onSeeAllCases;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Dashboard',
      subtitle: 'Hoy · actualizado hace 12 s',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KpiCard(
                  label: 'Transacciones hoy',
                  value: formatCount(12480),
                  delta: '+8,2 % vs. ayer',
                  deltaColor: MsColors.accent,
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              const Expanded(
                child: KpiCard(
                  label: 'Bloqueadas',
                  value: '37',
                  delta: '0,30 % del total',
                  deltaColor: MsColors.block,
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              const Expanded(
                child: KpiCard(
                  label: 'En revisión',
                  value: '214',
                  delta: '58 sin asignar',
                  deltaColor: MsColors.review,
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              const Expanded(
                child: KpiCard(
                  label: 'Latencia p95',
                  value: '182 ms',
                  delta: 'Objetivo < 500 ms',
                  deltaColor: MsColors.approve,
                ),
              ),
            ],
          ),
          const SizedBox(height: MsSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 2, child: _DecisionsChartCard()),
              const SizedBox(width: MsSpace.lg),
              Expanded(child: _ActiveModelCard(model: activeModel)),
            ],
          ),
          const SizedBox(height: MsSpace.xl),
          MsCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MsSpace.xl,
                    MsSpace.lg,
                    MsSpace.lg,
                    MsSpace.sm,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Casos recientes', style: MsText.heading),
                      ),
                      if (onSeeAllCases != null)
                        MsButton(
                          label: 'Ver la cola',
                          variant: MsButtonVariant.ghost,
                          onPressed: onSeeAllCases,
                        ),
                    ],
                  ),
                ),
                MinWidthScroll(
                  minWidth: CaseRow.minWidth,
                  child: Column(
                    children: [
                      for (var i = 0; i < recentCases.length; i++)
                        CaseRow(
                          fraudCase: recentCases[i],
                          showBorder: i < recentCases.length - 1,
                          onTap: () => onOpenCase(recentCases[i].id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionsChartCard extends StatelessWidget {
  const _DecisionsChartCard();

  @override
  Widget build(BuildContext context) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Decisiones por hora', style: MsText.heading),
                    SizedBox(height: MsSpace.xxs),
                    Text('Últimas 24 horas', style: MsText.caption),
                  ],
                ),
              ),
              const LegendItem(label: 'Aprobadas', color: MsColors.bgInverse),
              const SizedBox(width: MsSpace.lg),
              const LegendItem(label: 'Revisión', color: MsColors.review),
              const SizedBox(width: MsSpace.lg),
              const LegendItem(label: 'Bloqueadas', color: MsColors.block),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < hourlyDecisions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _HourBar(hourlyDecisions[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: MsSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in const [
                '00:00',
                '06:00',
                '12:00',
                '18:00',
                '23:00',
              ])
                Text(
                  t,
                  style: MsText.caption.copyWith(color: MsColors.textTertiary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One stacked bar: block on top, review in the middle, approve at the bottom.
class _HourBar extends StatelessWidget {
  const _HourBar(this.data);

  final HourlyDecisions data;

  Widget _segment(double height, Color color) => Container(
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _segment(data.block, MsColors.block),
        const SizedBox(height: 2),
        _segment(data.review, MsColors.review),
        const SizedBox(height: 2),
        _segment(data.approve, MsColors.bgInverse),
      ],
    );
  }
}

class _ActiveModelCard extends StatelessWidget {
  const _ActiveModelCard({required this.model});

  final ModelVersion? model;

  @override
  Widget build(BuildContext context) {
    final m = model;
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const MsIcon(MsIconName.cpu, color: MsColors.textSecondary),
              const SizedBox(width: MsSpace.sm),
              const Expanded(
                child: Text('Modelo activo', style: MsText.heading),
              ),
              Text(m?.name ?? '—', style: MsText.heading),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          Row(
            children: [
              Expanded(
                child: DetailField(
                  label: 'PR-AUC',
                  value: m == null ? '—' : formatDecimal(m.prAuc),
                ),
              ),
              Expanded(
                child: DetailField(
                  label: 'Recall',
                  value: m == null ? '—' : formatDecimal(m.recall),
                ),
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          DetailField(
            label: 'Entrenado',
            value: m == null
                ? '—'
                : '${m.trainedAt} · ${m.origin.toLowerCase()}',
          ),
          const SizedBox(height: MsSpace.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MsSpace.md,
              vertical: MsSpace.sm,
            ),
            decoration: BoxDecoration(
              color: MsColors.reviewBg,
              borderRadius: BorderRadius.circular(MsRadius.md),
            ),
            child: Row(
              children: [
                const MsIcon(MsIconName.zap, size: 16, color: MsColors.review),
                const SizedBox(width: MsSpace.sm),
                Expanded(
                  child: Text(
                    '3 decisiones degradadas hoy (solo reglas)',
                    style: MsText.caption.copyWith(color: MsColors.review),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
