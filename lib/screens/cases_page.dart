import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/case_row.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_icon.dart';
import '../widgets/ms_tabs.dart';
import '../widgets/page_frame.dart';
import '../widgets/progress_feedback.dart';
import '../widgets/table_parts.dart';

/// Tabs of the queue, in display order.
enum CaseTab { all, unassigned, mine, resolved }

/// Cases of [all] that belong to [tab] for the user named [me].
List<FraudCase> casesForTab(List<FraudCase> all, CaseTab tab, String me) {
  switch (tab) {
    case CaseTab.all:
      return all.where((c) => c.status != CaseStatus.resolved).toList();
    case CaseTab.unassigned:
      return all
          .where((c) => c.status != CaseStatus.resolved && c.assignedTo == null)
          .toList();
    case CaseTab.mine:
      return all
          .where((c) => c.status != CaseStatus.resolved && c.assignedTo == me)
          .toList();
    case CaseTab.resolved:
      return all.where((c) => c.status == CaseStatus.resolved).toList();
  }
}

/// Case queue. The host owns the data, the tab, the filter and the search.
class CasesPage extends StatelessWidget {
  const CasesPage({
    super.key,
    required this.cases,
    required this.currentUserName,
    required this.tab,
    required this.onTabChanged,
    required this.verdictFilter,
    required this.onVerdictFilterTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenCase,
  });

  final List<FraudCase> cases;
  final String currentUserName;
  final CaseTab tab;
  final ValueChanged<CaseTab> onTabChanged;

  /// Null shows every verdict.
  final Verdict? verdictFilter;
  final VoidCallback onVerdictFilterTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onOpenCase;

  List<FraudCase> _visible() {
    final query = searchController.text.trim().toLowerCase();
    return casesForTab(cases, tab, currentUserName).where((c) {
      if (verdictFilter != null && c.verdict != verdictFilter) return false;
      if (query.isEmpty) return true;
      return c.customerName.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query) ||
          c.type.toLowerCase().contains(query);
    }).toList();
  }

  String _verdictChipLabel() {
    switch (verdictFilter) {
      case null:
        return 'Veredicto: todos';
      case Verdict.block:
        return 'Veredicto: bloqueada';
      case Verdict.review:
        return 'Veredicto: en revisión';
      case Verdict.approve:
        return 'Veredicto: aprobada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible();
    final tabLabels = [
      'Todos · ${casesForTab(cases, CaseTab.all, currentUserName).length}',
      'Sin asignar · '
          '${casesForTab(cases, CaseTab.unassigned, currentUserName).length}',
      'Asignados a mí · '
          '${casesForTab(cases, CaseTab.mine, currentUserName).length}',
      'Resueltos hoy · '
          '${casesForTab(cases, CaseTab.resolved, currentUserName).length}',
    ];
    return PageFrame(
      title: 'Cola de casos',
      subtitle: 'Transacciones marcadas para revisión',
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: MsTabs(
                  labels: tabLabels,
                  selectedIndex: tab.index,
                  onSelected: (i) => onTabChanged(CaseTab.values[i]),
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              FilterChipButton(
                label: _verdictChipLabel(),
                onTap: onVerdictFilterTap,
              ),
              const SizedBox(width: MsSpace.sm),
              const FilterChipButton(label: 'Score ≥ 0,60'),
              const SizedBox(width: MsSpace.md),
              const MsButton(
                label: 'Filtros',
                variant: MsButtonVariant.secondary,
                icon: MsIconName.filter,
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          MsCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: MinWidthScroll(
              minWidth: CaseRow.minWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TableHeader(
                    children: [
                      HeaderCell('ID', width: 112),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Cliente', width: 200),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Monto', width: 140),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Tipo', width: 150),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Score', width: 120),
                      SizedBox(width: MsSpace.xl),
                      HeaderCell('Veredicto'),
                      Spacer(),
                      HeaderCell('Antigüedad', width: 84, right: true),
                      SizedBox(width: MsSpace.lg),
                      SizedBox(width: 20),
                    ],
                  ),
                  if (visible.isEmpty)
                    const SizedBox(
                      height: 220,
                      child: EmptyState(
                        icon: MsIconName.inbox,
                        title: 'No hay casos para mostrar',
                        hint: 'Cambia la pestaña, el filtro o la búsqueda.',
                      ),
                    )
                  else
                    for (var i = 0; i < visible.length; i++)
                      CaseRow(
                        fraudCase: visible[i],
                        showBorder: i < visible.length - 1,
                        onTap: () => onOpenCase(visible[i].id),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MsSpace.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mostrando ${visible.length} de ${cases.length} · '
                  'ordenados por riesgo',
                  style: MsText.caption,
                ),
              ),
              const MsButton(
                label: 'Anterior',
                variant: MsButtonVariant.secondary,
                onPressed: null,
              ),
              const SizedBox(width: MsSpace.sm),
              const MsButton(
                label: 'Siguiente',
                variant: MsButtonVariant.secondary,
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
