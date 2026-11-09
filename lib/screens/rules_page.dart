import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_icon.dart';
import '../widgets/ms_tabs.dart';
import '../widgets/page_frame.dart';
import '../widgets/progress_feedback.dart';
import '../widgets/rule_row.dart';
import '../widgets/table_parts.dart';

/// Tabs of the rules list, in display order.
enum RuleTab { all, active, shadow, pending, draft }

/// Rules of [all] whose latest version belongs to [tab].
List<Rule> rulesForTab(List<Rule> all, RuleTab tab) {
  switch (tab) {
    case RuleTab.all:
      return all;
    case RuleTab.active:
      return all.where((r) => r.latest.status == RuleStatus.active).toList();
    case RuleTab.shadow:
      return all.where((r) => r.latest.status == RuleStatus.shadow).toList();
    case RuleTab.pending:
      return all
          .where((r) => r.latest.status == RuleStatus.pendingApproval)
          .toList();
    case RuleTab.draft:
      return all.where((r) => r.latest.status == RuleStatus.draft).toList();
  }
}

/// Rules list. The host owns the rules and the selected tab.
class RulesPage extends StatelessWidget {
  const RulesPage({
    super.key,
    required this.rules,
    required this.canWrite,
    required this.tab,
    required this.onTabChanged,
    required this.onOpenRule,
    required this.onNewRule,
  });

  final List<Rule> rules;

  /// The user has `RULE_WRITE`.
  final bool canWrite;
  final RuleTab tab;
  final ValueChanged<RuleTab> onTabChanged;
  final ValueChanged<String> onOpenRule;
  final VoidCallback onNewRule;

  @override
  Widget build(BuildContext context) {
    final visible = rulesForTab(rules, tab);
    final labels = [
      'Todas · ${rules.length}',
      'Activas · ${rulesForTab(rules, RuleTab.active).length}',
      'En shadow · ${rulesForTab(rules, RuleTab.shadow).length}',
      'Pendientes · ${rulesForTab(rules, RuleTab.pending).length}',
      'Borradores · ${rulesForTab(rules, RuleTab.draft).length}',
    ];
    return PageFrame(
      title: 'Reglas',
      subtitle: 'Deciden qué transacciones se revisan y cuáles se bloquean',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: MsTabs(
                  labels: labels,
                  selectedIndex: tab.index,
                  onSelected: (i) => onTabChanged(RuleTab.values[i]),
                ),
              ),
              if (canWrite) ...[
                const SizedBox(width: MsSpace.lg),
                MsButton(
                  label: 'Nueva regla',
                  icon: MsIconName.plus,
                  onPressed: onNewRule,
                ),
              ],
            ],
          ),
          const SizedBox(height: MsSpace.xl),
          MsCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: MinWidthScroll(
              minWidth: RuleRow.minWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TableHeader(
                    children: [
                      HeaderCell('Regla', width: 300),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Versión', width: 56),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Acción', width: 96),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Estado', width: 130),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Coinc. 7 d', width: 90, right: true),
                      SizedBox(width: MsSpace.lg),
                      HeaderCell('Precisión', width: 80, right: true),
                      Spacer(),
                      HeaderCell('Actualizada'),
                      SizedBox(width: MsSpace.lg),
                      SizedBox(width: 20),
                    ],
                  ),
                  if (visible.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: EmptyState(
                        icon: MsIconName.sliders,
                        title: 'No hay reglas en esta pestaña',
                        hint: 'Cambia de pestaña o crea una regla nueva.',
                      ),
                    )
                  else
                    for (var i = 0; i < visible.length; i++)
                      RuleRow(
                        rule: visible[i],
                        showBorder: i < visible.length - 1,
                        onTap: () => onOpenRule(visible[i].code),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MsSpace.lg),
          const Row(
            children: [
              Text(
                'Ciclo de vida:',
                style: TextStyle(
                  fontFamily: MsText.family,
                  fontSize: 12,
                  height: 16 / 12,
                  color: MsColors.textTertiary,
                ),
              ),
              SizedBox(width: MsSpace.sm),
              RuleStatusBadge(status: RuleStatus.draft),
              _Arrow(),
              RuleStatusBadge(status: RuleStatus.shadow),
              _Arrow(),
              RuleStatusBadge(status: RuleStatus.pendingApproval),
              _Arrow(),
              RuleStatusBadge(status: RuleStatus.active),
              _Arrow(),
              RuleStatusBadge(status: RuleStatus.retired),
            ],
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MsSpace.sm),
      child: Text(
        '→',
        style: MsText.caption.copyWith(color: MsColors.textTertiary),
      ),
    );
  }
}
