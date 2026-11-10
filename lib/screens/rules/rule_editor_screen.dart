import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/app_store.dart';
import '../../data/domain_error.dart';
import '../../data/format.dart';
import '../../data/models/models.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'rule_editor_page.dart';

/// Rule editor host: reads the rule from the store, owns the selected version
/// and the draft being edited, and performs every lifecycle action, save and
/// navigation for [RuleEditorPage].
class RuleEditorScreen extends StatefulWidget {
  const RuleEditorScreen({super.key, this.ruleId});

  /// The rule to show, or `null` for a new rule.
  final String? ruleId;

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  static const _emptyCondition = Condition('amount', ConditionOp.gte, '');

  /// The selected version number, or `null` for the latest.
  int? _selected;

  /// The edited conditions and action. An incomplete value stays as its text.
  List<Condition> _conditions = const [_emptyCondition];
  RuleAction _action = RuleAction.REVIEW;
  bool _dirty = false;

  /// Whether a save or create was tried, which shows incomplete conditions.
  bool _attempted = false;

  /// The version the buffer was seeded from, or `null` to seed it again.
  int? _seeded;

  final _code = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _codeError;
  String? _nameError;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _complete =>
      _conditions.isNotEmpty && _conditions.every(isValidCondition);

  void _seed(RuleVersion version) {
    _seeded = version.version;
    _conditions = version.conditions;
    _action = version.action;
    _dirty = false;
    _attempted = false;
  }

  void _edit(List<Condition> Function(List<Condition> conditions) change) {
    setState(() {
      _conditions = change([..._conditions]);
      _dirty = true;
    });
  }

  /// Replaces condition [index], reading its current text for the new
  /// feature or operator.
  void _replace(int index, {String? feature, ConditionOp? op, String? text}) {
    _edit((conditions) {
      final current = conditions[index];
      final newFeature = feature ?? current.feature;
      final newOp = op ?? current.op;
      final newText = text ?? conditionValueText(current.value);
      conditions[index] = Condition(
        newFeature,
        newOp,
        parseConditionValue(newFeature, newOp, newText),
      );
      return conditions;
    });
  }

  void _saveDraft(String ruleId, int version) {
    if (!_complete) {
      setState(() => _attempted = true);
      return;
    }
    _act((s) {
      s.updateDraft(ruleId, version, conditions: _conditions, action: _action);
      setState(() => _seeded = null);
    });
  }

  void _discardDraft(String ruleId, int version) {
    _act((s) {
      s.deleteDraft(ruleId, version);
      final remaining = s.ruleById(ruleId);
      if (remaining == null) {
        _back();
        return;
      }
      setState(() {
        _selected = remaining.latest.version;
        _seeded = null;
      });
    });
  }

  void _createRule() {
    final store = AppScope.read(context);
    final code = _code.text.trim();
    final name = _name.text.trim();
    setState(() {
      _codeError = !ruleCodePattern.hasMatch(code)
          ? 'Usa mayúsculas, números y _ (3 a 40 caracteres).'
          : store.ruleByCode(code) != null
          ? 'Ya existe una regla con ese código.'
          : null;
      _nameError = name.isEmpty ? 'Escribe un nombre.' : null;
      _attempted = true;
    });
    if (_codeError != null || _nameError != null || !_complete) return;
    _act((s) {
      final view = s.createRule(
        code: code,
        name: name,
        description: _description.text.trim(),
        conditions: _conditions,
        action: _action,
      );
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.ruleEditor(view.rule.id));
    });
  }

  RuleEditorPage _page({
    RuleView? view,
    RuleVersion? version,
    required DateTime now,
    AppUser? creator,
    AppUser? approver,
    bool canWrite = false,
    bool canApprove = false,
    bool editing = false,
  }) {
    final ruleId = view?.rule.id;
    final number = version?.version;
    void onVersion(void Function(AppStore s, String id, int n) action) {
      if (ruleId != null && number != null) {
        _act((s) => action(s, ruleId, number));
      }
    }

    return RuleEditorPage(
      view: view,
      version: version,
      now: now,
      creator: creator,
      approver: approver,
      canWrite: canWrite,
      canApprove: canApprove,
      onBack: _back,
      onSelectVersion: (n) => setState(() => _selected = n),
      onStartShadow: () => onVersion((s, id, n) => s.startShadow(id, n)),
      onRunBacktest: () => onVersion((s, id, n) => s.runBacktest(id, n)),
      onSubmit: () => onVersion((s, id, n) => s.submitForApproval(id, n)),
      onApprove: () => onVersion((s, id, n) => s.approve(id, n)),
      onReject: (reason) => onVersion((s, id, n) => s.reject(id, n, reason)),
      onNewVersion: () {
        if (ruleId == null) return;
        _act((s) {
          final created = s.createVersion(ruleId);
          setState(() => _selected = created.version);
        });
      },
      draftConditions: editing ? _conditions : null,
      draftAction: _action,
      dirty: _dirty,
      conditionErrors: [
        for (final condition in _conditions)
          _attempted && !isValidCondition(condition),
      ],
      showConditionsError: _attempted && !_complete,
      onFeatureChanged: (i, name) => _replace(i, feature: name),
      onOpChanged: (i, op) => _replace(i, op: op),
      onValueChanged: (i, text) => _replace(i, text: text),
      onRemoveCondition: (i) => _edit((conditions) => conditions..removeAt(i)),
      onAddCondition: () =>
          _edit((conditions) => conditions..add(_emptyCondition)),
      onActionChanged: (action) => setState(() {
        _action = action;
        _dirty = true;
      }),
      onSaveDraft: () {
        if (ruleId != null && number != null) _saveDraft(ruleId, number);
      },
      onDiscardDraft: () {
        if (ruleId != null && number != null) _discardDraft(ruleId, number);
      },
      onCreateRule: _createRule,
      codeController: _code,
      nameController: _name,
      descriptionController: _description,
      codeError: _codeError,
      nameError: _nameError,
      onCodeChanged: (_) {
        if (_codeError != null) setState(() => _codeError = null);
      },
      onNameChanged: (_) {
        if (_nameError != null) setState(() => _nameError = null);
      },
    );
  }

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
    final store = AppScope.of(context);
    if (ruleId == null) {
      return AppShell(
        active: NavDestination.rules,
        title: 'Nueva regla',
        subtitle: 'Borrador sin guardar',
        child: _page(now: store.now, editing: true),
      );
    }

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
    final canWrite = store.can(PermissionCode.RULE_WRITE);
    final editing = canWrite && version.status == RuleStatus.DRAFT;
    // Seeded here, so a version switch, a new version, a save or a discard
    // shows the stored conditions again.
    if (!editing) {
      _seeded = null;
    } else if (_seeded != version.version) {
      _seed(version);
    }

    return AppShell(
      active: NavDestination.rules,
      title: '${view.rule.code} · v${version.version}',
      subtitle: view.rule.name,
      child: _page(
        view: view,
        version: version,
        now: store.now,
        creator: store.userById(version.createdBy.id),
        approver: approver,
        canWrite: canWrite,
        canApprove: canApprove,
        editing: editing,
      ),
    );
  }
}
