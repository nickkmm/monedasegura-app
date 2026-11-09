import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// The case queue: tabs, filters, the table of cases and the pagination.
///
/// Shows [rows] (the current page of the [tab] list, already filtered by
/// [verdictFilter]) and reports every interaction through its callbacks.
class CaseQueuePage extends StatelessWidget {
  const CaseQueuePage({
    super.key,
    required this.tabLabels,
    required this.tab,
    required this.rows,
    required this.shownCount,
    required this.totalCount,
    required this.verdictFilter,
    required this.hasPrevious,
    required this.hasNext,
    required this.now,
    required this.onTabSelected,
    required this.onVerdictFilter,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenCase,
  });

  final List<String> tabLabels;
  final int tab;
  final List<CaseView> rows;
  final int shownCount;
  final int totalCount;
  final Verdict? verdictFilter;
  final bool hasPrevious;
  final bool hasNext;
  final DateTime now;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<Verdict?> onVerdictFilter;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<CaseView> onOpenCase;

  @override
  Widget build(BuildContext context) {
    // The table rows are wider than the content area of a narrow window, so
    // the page takes at least its natural width and scrolls horizontally.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: IntrinsicWidth(child: _content()),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTabBar(
                labels: tabLabels,
                selectedIndex: tab,
                onSelected: onTabSelected,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            _VerdictFilter(value: verdictFilter, onChanged: onVerdictFilter),
            const SizedBox(width: AppSpacing.lg),
            const FilterPill(label: 'Score ≥ 0,60'),
            const SizedBox(width: AppSpacing.lg),
            AppButton(
              label: 'Filtros',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _CaseTable(rows: rows, now: now, onOpenCase: onOpenCase),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando $shownCount de $totalCount · ordenados por riesgo',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            AppButton(
              label: 'Anterior',
              variant: AppButtonVariant.ghost,
              onPressed: hasPrevious ? onPrevious : null,
            ),
            AppButton(
              label: 'Siguiente',
              variant: AppButtonVariant.ghost,
              onPressed: hasNext ? onNext : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// The verdict chip and its menu.
class _VerdictFilter extends StatelessWidget {
  const _VerdictFilter({required this.value, required this.onChanged});

  final Verdict? value;
  final ValueChanged<Verdict?> onChanged;

  String get _label => switch (value) {
    null => 'Veredicto: todos',
    Verdict.BLOCK => 'Veredicto: bloqueadas',
    Verdict.REVIEW => 'Veredicto: en revisión',
    Verdict.APPROVE => 'Veredicto: aprobadas',
  };

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final (label, verdict) in const [
          ('Todos', null),
          ('Bloqueadas', Verdict.BLOCK),
          ('En revisión', Verdict.REVIEW),
        ])
          MenuItemButton(
            onPressed: () => onChanged(verdict),
            child: Text(label),
          ),
      ],
      builder: (context, controller, _) => FilterPill(
        label: _label,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// The table card: the header and one [CaseRow] per case, or the empty state.
class _CaseTable extends StatelessWidget {
  const _CaseTable({
    required this.rows,
    required this.now,
    required this.onOpenCase,
  });

  final List<CaseView> rows;
  final DateTime now;
  final ValueChanged<CaseView> onOpenCase;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TableHeaderRow(
            cells: [
              TableHeaderCell(label: 'ID', width: 112),
              TableHeaderCell(label: 'Cliente', width: 200),
              TableHeaderCell(label: 'Monto', width: 140),
              TableHeaderCell(label: 'Tipo', width: 150),
              TableHeaderCell(label: 'Score', width: 100),
              TableHeaderCell(width: 44),
              TableHeaderCell(label: 'Veredicto', width: 100),
              TableHeaderCell(flex: true),
              TableHeaderCell(label: 'Antigüedad', align: TextAlign.right),
              TableHeaderCell(width: 20),
            ],
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: EmptyState(
                icon: AppIcons.inbox,
                title: 'No hay casos en esta vista',
                hint: 'Los casos nuevos aparecen aquí apenas el sistema los marca.',
              ),
            )
          else
            for (final row in rows)
              CaseRow(caseView: row, now: now, onTap: () => onOpenCase(row)),
        ],
      ),
    );
  }
}
