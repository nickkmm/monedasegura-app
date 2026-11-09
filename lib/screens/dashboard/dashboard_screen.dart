import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/format.dart';
import '../../data/models/models.dart';
import '../../widgets/widgets.dart';
import 'dashboard_page.dart';

/// Today's KPIs, decisions per hour, the active model and the recent cases.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _subtitle(DateTime updatedAt, DateTime now) {
    final seconds = now.difference(updatedAt).inSeconds;
    final ago = seconds < 60 ? 'hace $seconds s' : formatAgo(updatedAt, now);
    return 'Hoy · actualizado $ago';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = store.now;
    final metrics = store.metrics;
    return AppShell(
      active: NavDestination.dashboard,
      title: 'Dashboard',
      subtitle: _subtitle(metrics.to, now),
      child: DashboardPage(
        metrics: metrics,
        openCases: store.openCaseCount,
        unassignedCases: store.unassignedCaseCount,
        activeModel: store.activeModel,
        recentCases: store.recentCases,
        now: now,
        canOpenModels: store.can(PermissionCode.MODEL_READ),
        onOpenQueue: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.cases),
        onOpenCase: (c) =>
            Navigator.of(context).pushNamed(AppRoutes.caseDetail(c.id)),
        onOpenModels: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.models),
      ),
    );
  }
}
