import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/app_store.dart';
import '../../data/domain_error.dart';
import '../../data/models/models.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'rule_editor_page.dart';

/// Rule editor host: reads the rule from the store, owns the selected version
/// and performs every lifecycle action and navigation for [RuleEditorPage].
class RuleEditorScreen extends StatefulWidget {
  const RuleEditorScreen({super.key, this.ruleId});

  /// The rule to show, or `null` for a new rule.
  final String? ruleId;

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  /// The selected version number, or `null` for the latest.
  int? _selected;

  void _back() => Navigator.of(context).pushReplacementNamed(AppRoutes.rules);

  /// Runs [action] on the store; a [DomainError] only shows a message.
  void _act(void Function(AppStore store) action) {
    try {
      action(AppScope.read(context));
    } on DomainError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la acción.')),
      );
    }
  }

  AppShell _emptyShell(Widget child) => AppShell(
    active: NavDestination.rules,
    title: 'Regla',
    subtitle: '',
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final ruleId = widget.ruleId;
    if (ruleId == null) {
      return _emptyShell(
        const EmptyState(
          icon: AppIcons.plus,
          title: 'Nueva regla',
          hint: 'Disponible pronto.',
        ),
      );
    }

    final store = AppScope.of(context);
    final view = store.ruleById(ruleId);
    if (view == null) {
      return _emptyShell(
        Column(
          spacing: AppSpacing.lg,
          children: [
            const EmptyState(
              icon: AppIcons.sliders,
              title: 'No encontramos esta regla',
              hint: 'Puede que se haya descartado.',
            ),
            AppButton(
              label: 'Reglas',
              icon: AppIcons.back,
              variant: AppButtonVariant.ghost,
              onPressed: _back,
            ),
          ],
        ),
      );
    }

    final selected = _selected;
    final version =
        (selected == null ? null : view.version(selected)) ?? view.latest;
    final canApprove = store.canApprove(version);
    final approvers = store.approversFor(version);
    final approver = canApprove
        ? store.currentUser
        : approvers.isEmpty
        ? null
        : approvers.first;

    return AppShell(
      active: NavDestination.rules,
      title: '${view.rule.code} · v${version.version}',
      subtitle: view.rule.name,
      child: RuleEditorPage(
        view: view,
        version: version,
        now: store.now,
        creator: store.userById(version.createdBy.id),
        approver: approver,
        canWrite: store.can(PermissionCode.RULE_WRITE),
        canApprove: canApprove,
        onBack: _back,
        onSelectVersion: (n) => setState(() => _selected = n),
        onStartShadow: () =>
            _act((s) => s.startShadow(ruleId, version.version)),
        onRunBacktest: () =>
            _act((s) => s.runBacktest(ruleId, version.version)),
        onSubmit: () =>
            _act((s) => s.submitForApproval(ruleId, version.version)),
        onApprove: () => _act((s) => s.approve(ruleId, version.version)),
        onReject: (reason) =>
            _act((s) => s.reject(ruleId, version.version, reason)),
        onNewVersion: () => _act((s) {
          final created = s.createVersion(ruleId);
          setState(() => _selected = created.version);
        }),
      ),
    );
  }
}
