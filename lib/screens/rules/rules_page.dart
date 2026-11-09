import 'package:flutter/widgets.dart';

import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// Rules list page (Figma `9:632`): the toolbar, the table and the lifecycle
/// legend.
///
/// [tabLabels] and [tab] drive the tab bar, and [rows] are the rules of the
/// selected tab. [now] is the reference time for the rows' last change.
/// [canCreate] shows "Nueva regla". [onTabSelected], [onNewRule] and
/// [onOpenRule] report the user's actions.
class RulesPage extends StatelessWidget {
  const RulesPage({
    super.key,
    required this.tabLabels,
    required this.tab,
    required this.rows,
    required this.now,
    required this.canCreate,
    required this.onTabSelected,
    required this.onNewRule,
    required this.onOpenRule,
  });

  final List<String> tabLabels;
  final int tab;
  final List<RuleView> rows;
  final DateTime now;
  final bool canCreate;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onNewRule;
  final ValueChanged<RuleView> onOpenRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          tabLabels: tabLabels,
          tab: tab,
          canCreate: canCreate,
          onTabSelected: onTabSelected,
          onNewRule: onNewRule,
        ),
        const SizedBox(height: AppSpacing.xl),
        _RulesTable(rows: rows, now: now, onOpenRule: onOpenRule),
        const SizedBox(height: AppSpacing.xl),
        const _LifecycleLegend(),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.tabLabels,
    required this.tab,
    required this.canCreate,
    required this.onTabSelected,
    required this.onNewRule,
  });

  final List<String> tabLabels;
  final int tab;
  final bool canCreate;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onNewRule;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTabBar(
            labels: tabLabels,
            selectedIndex: tab,
            onSelected: onTabSelected,
          ),
        ),
        if (canCreate) ...[
          const SizedBox(width: AppSpacing.lg),
          AppButton(
            label: 'Nueva regla',
            icon: AppIcons.plus,
            onPressed: onNewRule,
          ),
        ],
      ],
    );
  }
}

class _RulesTable extends StatelessWidget {
  const _RulesTable({
    required this.rows,
    required this.now,
    required this.onOpenRule,
  });

  /// Below this card width "Actualizada" can't fit a date and an author, so
  /// it shows only the date. The card is this wide in a 1418 px window.
  static const double _fullLastChangeWidth = 1114;

  final List<RuleView> rows;
  final DateTime now;
  final ValueChanged<RuleView> onOpenRule;

  Widget _table({required bool compact}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TableHeaderRow(
            cells: [
              compact
                  ? const TableHeaderCell(label: 'Regla', flex: true)
                  : const TableHeaderCell(label: 'Regla', width: 300),
              const TableHeaderCell(label: 'Versión', width: 56),
              const TableHeaderCell(label: 'Acción', width: 96),
              const TableHeaderCell(label: 'Estado', width: 130),
              const TableHeaderCell(
                label: 'Coinc. 7 d',
                width: 90,
                align: TextAlign.right,
              ),
              const TableHeaderCell(
                label: 'Precisión',
                width: 80,
                align: TextAlign.right,
              ),
              TableHeaderCell(
                label: 'Actualizada',
                width: compact ? RuleRow.compactDateWidth : null,
                flex: !compact,
                align: TextAlign.right,
              ),
              const TableHeaderCell(width: AppIcons.size),
            ],
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Center(
                child: EmptyState(
                  icon: AppIcons.sliders,
                  title: 'No hay reglas en este estado',
                  hint: 'Cambia de pestaña o crea una regla nueva.',
                ),
              ),
            )
          else
            for (final rule in rows)
              RuleRow(
                rule: rule,
                now: now,
                compact: compact,
                onTap: () => onOpenRule(rule),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _table(compact: constraints.maxWidth < _fullLastChangeWidth),
    );
  }
}

class _LifecycleLegend extends StatelessWidget {
  const _LifecycleLegend();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: AppColors.textTertiary);
    const statuses = [
      RuleStatus.DRAFT,
      RuleStatus.SHADOW,
      RuleStatus.PENDING_APPROVAL,
      RuleStatus.ACTIVE,
      RuleStatus.RETIRED,
    ];

    return Row(
      spacing: AppSpacing.sm,
      children: [
        Text('Ciclo de vida:', style: style),
        for (var i = 0; i < statuses.length; i++) ...[
          if (i > 0) Text('→', style: style),
          RuleStatusBadge(status: statuses[i]),
        ],
      ],
    );
  }
}
