import 'package:flutter/widgets.dart';

import '../data/models/models.dart';
import '../theme/app_icons.dart';
import 'routes.dart';

/// The sidebar destinations, in sidebar order.
enum NavDestination {
  dashboard(
    label: 'Dashboard',
    icon: AppIcons.dashboard,
    route: AppRoutes.dashboard,
    permission: PermissionCode.DASHBOARD_READ,
  ),
  cases(
    label: 'Casos',
    icon: AppIcons.inbox,
    route: AppRoutes.cases,
    permission: PermissionCode.CASE_READ,
  ),
  rules(
    label: 'Reglas',
    icon: AppIcons.sliders,
    route: AppRoutes.rules,
    permission: PermissionCode.RULE_READ,
  ),
  models(
    label: 'Modelos',
    icon: AppIcons.cpu,
    route: AppRoutes.models,
    permission: PermissionCode.MODEL_READ,
  ),
  simulator(
    label: 'Simulador',
    icon: AppIcons.play,
    route: AppRoutes.simulator,
    permission: PermissionCode.SIMULATOR_RUN,
  );

  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
    required this.permission,
  });

  final String label;
  final IconData icon;
  final String route;
  final PermissionCode permission;
}
