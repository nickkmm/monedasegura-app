import 'package:flutter/widgets.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/models/models.dart';
import '../../widgets/widgets.dart';
import 'rules_page.dart';

/// The rules list: owns the selected tab, reads the store and navigates.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  /// The status each tab after "Todas" filters on, in tab order.
  static const List<RuleStatus> _tabStatuses = [
    RuleStatus.ACTIVE,
    RuleStatus.SHADOW,
    RuleStatus.PENDING_APPROVAL,
    RuleStatus.DRAFT,
  ];

  int tab = 0;

  List<RuleView> _withStatus(List<RuleView> rules, RuleStatus status) =>
      rules.where((view) => view.latest.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final rules = store.rules;

    return AppShell(
      active: NavDestination.rules,
      title: 'Reglas',
      subtitle: 'Deciden qué transacciones se revisan y cuáles se bloquean',
      child: RulesPage(
        tabLabels: [
          'Todas · ${rules.length}',
          'Activas · ${_withStatus(rules, RuleStatus.ACTIVE).length}',
          'En shadow · ${_withStatus(rules, RuleStatus.SHADOW).length}',
          'Pendientes · '
              '${_withStatus(rules, RuleStatus.PENDING_APPROVAL).length}',
          'Borradores · ${_withStatus(rules, RuleStatus.DRAFT).length}',
        ],
        tab: tab,
        rows: tab == 0 ? rules : _withStatus(rules, _tabStatuses[tab - 1]),
        now: store.now,
        canCreate: store.can(PermissionCode.RULE_WRITE),
        onTabSelected: (index) => setState(() => tab = index),
        onNewRule: () => Navigator.of(context).pushNamed(AppRoutes.newRule),
        onOpenRule: (view) =>
            Navigator.of(context).pushNamed(AppRoutes.ruleEditor(view.rule.id)),
      ),
    );
  }
}
