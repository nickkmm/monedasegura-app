import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/models/models.dart';
import '../../widgets/widgets.dart';
import 'case_queue_page.dart';

/// The case queue: owns the selected tab, the verdict filter and the page.
class CaseQueueScreen extends StatefulWidget {
  const CaseQueueScreen({super.key});

  @override
  State<CaseQueueScreen> createState() => _CaseQueueScreenState();
}

class _CaseQueueScreenState extends State<CaseQueueScreen> {
  static const int _pageSize = 10;

  int tab = 0;
  Verdict? verdictFilter;
  int page = 0;

  void _openCase(CaseView caseView) {
    Navigator.of(context).pushNamed(AppRoutes.caseDetail(caseView.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final lists = [
      store.openCases,
      store.unassignedCases,
      store.myCases,
      store.resolvedToday,
    ];
    final filtered = [
      for (final view in lists[tab])
        if (verdictFilter == null || view.verdict == verdictFilter) view,
    ];
    final start = page * _pageSize;
    final rows = filtered.sublist(
      math.min(start, filtered.length),
      math.min(start + _pageSize, filtered.length),
    );

    return AppShell(
      active: NavDestination.cases,
      title: 'Cola de casos',
      subtitle:
          'Transacciones marcadas para revisión · '
          '${lists[0].length} abiertas',
      child: CaseQueuePage(
        tabLabels: [
          'Todos · ${lists[0].length}',
          'Sin asignar · ${lists[1].length}',
          'Asignados a mí · ${lists[2].length}',
          'Resueltos hoy · ${lists[3].length}',
        ],
        tab: tab,
        rows: rows,
        shownCount: rows.length,
        totalCount: filtered.length,
        verdictFilter: verdictFilter,
        hasPrevious: page > 0,
        hasNext: start + _pageSize < filtered.length,
        now: store.now,
        onTabSelected: (index) => setState(() {
          tab = index;
          page = 0;
        }),
        onVerdictFilter: (verdict) => setState(() {
          verdictFilter = verdict;
          page = 0;
        }),
        onPrevious: () => setState(() => page--),
        onNext: () => setState(() => page++),
        onOpenCase: _openCase,
      ),
    );
  }
}
