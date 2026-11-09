import 'package:flutter/widgets.dart';

import '../data/app_store.dart';
import '../data/models/models.dart';
import '../screens/cases/case_detail_screen.dart';
import '../screens/cases/case_queue_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/models/models_screen.dart';
import '../screens/rules/rule_editor_screen.dart';
import '../screens/rules/rules_screen.dart';
import '../screens/simulator/simulator_screen.dart';
import 'nav_destination.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String cases = '/cases';
  static String caseDetail(String id) => '$cases/$id';
  static const String rules = '/rules';
  static const String newRule = '/rules/new';
  static String ruleEditor(String id) => '$rules/$id';
  static const String models = '/models';
  static const String simulator = '/simulator';
}

/// The route of the first destination [user] can open, or the login if none.
String firstAllowedRoute(AppUser user) {
  for (final destination in NavDestination.values) {
    if (user.can(destination.permission)) return destination.route;
  }
  return AppRoutes.login;
}

/// Builds the page for [s], applying the guards: the login is always open,
/// signed out goes to the login, and a missing permission or an unknown path
/// goes to [firstAllowedRoute].
Route<dynamic>? onGenerateRoute(RouteSettings s, AppStore store) {
  final target = _match(s.name);
  if (target != null && target.permission == null) {
    return _page(s, target.screen);
  }

  final user = store.currentUser;
  if (user == null) {
    return _page(
      const RouteSettings(name: AppRoutes.login),
      const LoginScreen(),
    );
  }
  if (target != null && user.can(target.permission!)) {
    return _page(s, target.screen);
  }

  final fallback = firstAllowedRoute(user);
  return _page(RouteSettings(name: fallback), _match(fallback)!.screen);
}

/// The screen and required permission of [name], or `null` for an unknown
/// path. Only the login has no permission.
({Widget screen, PermissionCode? permission})? _match(String? name) {
  final uri = name == null ? null : Uri.tryParse(name);
  if (uri == null) return null;

  // Splits the raw path: decoding [Uri.pathSegments] can throw on bad bytes.
  return switch (uri.path.split('/')) {
    ['', 'login'] => (screen: const LoginScreen(), permission: null),
    ['', 'dashboard'] => (
      screen: const DashboardScreen(),
      permission: PermissionCode.DASHBOARD_READ,
    ),
    ['', 'cases'] => (
      screen: const CaseQueueScreen(),
      permission: PermissionCode.CASE_READ,
    ),
    ['', 'cases', final id] when id.isNotEmpty => (
      screen: CaseDetailScreen(caseId: id),
      permission: PermissionCode.CASE_READ,
    ),
    ['', 'rules'] => (
      screen: const RulesScreen(),
      permission: PermissionCode.RULE_READ,
    ),
    ['', 'rules', 'new'] => (
      screen: const RuleEditorScreen(ruleId: null),
      permission: PermissionCode.RULE_WRITE,
    ),
    ['', 'rules', final id] when id.isNotEmpty => (
      screen: RuleEditorScreen(ruleId: id),
      permission: PermissionCode.RULE_READ,
    ),
    ['', 'models'] => (
      screen: const ModelsScreen(),
      permission: PermissionCode.MODEL_READ,
    ),
    ['', 'simulator'] => (
      screen: const SimulatorScreen(),
      permission: PermissionCode.SIMULATOR_RUN,
    ),
    _ => null,
  };
}

Route<dynamic> _page(RouteSettings settings, Widget screen) {
  return PageRouteBuilder<dynamic>(
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => screen,
  );
}
