import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/ms_icon.dart';
import '../widgets/progress_feedback.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'case_detail_page.dart';
import 'cases_page.dart';
import 'dashboard_page.dart';
import 'models_page.dart';
import 'rule_editor_page.dart';
import 'rules_page.dart';
import 'simulator_page.dart';

/// Sections of the console, in sidebar order.
enum ConsoleSection { dashboard, cases, rules, models, simulator }

/// Host of the signed-in console. It owns all the app data (cases, rules,
/// model versions, the simulator run) and the navigation state; the pages only
/// show data and report interactions through callbacks.
class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key, required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  // Data.
  List<FraudCase> _cases = initialCases();
  List<Rule> _rules = initialRules();
  List<ModelVersion> _models = initialModels();

  // Navigation.
  late ConsoleSection? _section = _allowedSections().isEmpty
      ? null
      : _allowedSections().first;
  String? _caseId;
  String? _ruleCode;
  bool _creatingRule = false;

  // Queue and rules list state.
  CaseTab _caseTab = CaseTab.all;
  Verdict? _verdictFilter;
  final TextEditingController _search = TextEditingController();
  RuleTab _ruleTab = RuleTab.all;

  // Simulator.
  String _scenario = 'ACCOUNT_TAKEOVER';
  String _simCustomer = 'Sofía V.';
  String _simCount = '20';
  bool _simRunning = false;
  int _simRun = 17;
  bool _simHasRun = false;
  int _simTotal = 0;
  List<SimEvent> _simEvents = const [];
  Timer? _simTimer;

  AppUser get _user => widget.user;

  static const Map<ConsoleSection, Permission> _required = {
    ConsoleSection.dashboard: Permission.dashboardRead,
    ConsoleSection.cases: Permission.caseRead,
    ConsoleSection.rules: Permission.ruleRead,
    ConsoleSection.models: Permission.modelRead,
    ConsoleSection.simulator: Permission.simulatorRun,
  };

  List<ConsoleSection> _allowedSections() => [
    for (final s in ConsoleSection.values)
      if (_user.can(_required[s]!)) s,
  ];

  @override
  void dispose() {
    _simTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Navigation -------------------------------------------------------

  void _select(ConsoleSection section) {
    setState(() {
      _section = section;
      _caseId = null;
      _ruleCode = null;
      _creatingRule = false;
    });
  }

  // ---- Cases ------------------------------------------------------------

  void _updateCase(String id, FraudCase Function(FraudCase) change) {
    setState(() {
      _cases = [for (final c in _cases) c.id == id ? change(c) : c];
    });
  }

  void _takeCase(String id) {
    _updateCase(
      id,
      (c) => c.copyWith(status: CaseStatus.inReview, assignedTo: _user.name),
    );
    _toast('Caso tomado: ahora está asignado a ti.');
  }

  void _saveLabel(String id, CaseLabel label, String notes) {
    _updateCase(
      id,
      (c) =>
          c.copyWith(status: CaseStatus.resolved, label: label, notes: notes),
    );
    _toast('Etiqueta guardada. Entra al reentrenamiento de las 02:00.');
  }

  void _cycleVerdictFilter() {
    setState(() {
      switch (_verdictFilter) {
        case null:
          _verdictFilter = Verdict.block;
        case Verdict.block:
          _verdictFilter = Verdict.review;
        case Verdict.review:
        case Verdict.approve:
          _verdictFilter = null;
      }
    });
  }

  // ---- Rules ------------------------------------------------------------

  Rule? _ruleByCode(String? code) {
    for (final r in _rules) {
      if (r.code == code) return r;
    }
    return null;
  }

  void _replaceRule(Rule updated) {
    setState(() {
      _rules = [for (final r in _rules) r.code == updated.code ? updated : r];
    });
  }

  String get _stamp => 'hoy · ${_user.name}';

  String? _validate(RuleDraft draft, {required bool isNew}) {
    if (isNew) {
      if (draft.code.isEmpty) return 'Escribe un código para la regla.';
      if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(draft.code)) {
        return 'El código usa mayúsculas, números y guiones bajos '
            '(por ejemplo NIGHT_TRANSFER).';
      }
      if (_ruleByCode(draft.code) != null) {
        return 'Ya existe una regla con ese código.';
      }
    }
    if (draft.description.isEmpty) return 'Escribe una descripción.';
    if (draft.conditions.any((c) => c.value.trim().isEmpty)) {
      return 'Completa el valor de cada condición.';
    }
    return null;
  }

  String? _saveRule(RuleDraft draft) {
    final error = _validate(draft, isNew: _creatingRule);
    if (error != null) return error;
    if (_creatingRule) {
      final created = Rule(
        code: draft.code,
        description: draft.description,
        versions: [
          RuleVersion(
            number: 1,
            action: draft.action,
            status: RuleStatus.draft,
            conditions: draft.conditions,
            createdBy: _user.name,
            updatedLabel: _stamp,
          ),
        ],
      );
      setState(() {
        _rules = [..._rules, created];
        _creatingRule = false;
        _ruleCode = created.code;
      });
      _toast('Borrador ${created.code} creado.');
      return null;
    }
    final rule = _ruleByCode(_ruleCode);
    if (rule == null) return null;
    _replaceRule(
      rule
          .copyWith(description: draft.description)
          .withLatest(
            rule.latest.copyWith(
              action: draft.action,
              conditions: draft.conditions,
              updatedLabel: _stamp,
              backtestDone: false,
            ),
          ),
    );
    _toast('Borrador guardado.');
    return null;
  }

  String? _sendToShadow(RuleDraft draft) {
    final error = _saveRule(draft);
    if (error != null) return error;
    final rule = _ruleByCode(_ruleCode);
    if (rule == null) return null;
    _replaceRule(
      rule.withLatest(
        rule.latest.copyWith(
          status: RuleStatus.shadow,
          shadowDays: 0,
          backtestDone: false,
          updatedLabel: _stamp,
        ),
      ),
    );
    _toast('La regla ahora corre en shadow: no cambia decisiones todavía.');
    return null;
  }

  Future<void> _deleteDraft() async {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null || rule.latest.status != RuleStatus.draft) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar el borrador?'),
        content: Text(
          rule.versions.length == 1
              ? 'Se elimina la regla ${rule.code}. No se puede deshacer.'
              : 'Se elimina el borrador v${rule.latest.number} de '
                    '${rule.code}. Las versiones anteriores se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      if (rule.versions.length == 1) {
        _rules = [
          for (final r in _rules)
            if (r.code != rule.code) r,
        ];
      } else {
        _rules = [
          for (final r in _rules)
            r.code == rule.code
                ? r.copyWith(
                    versions: r.versions.sublist(0, r.versions.length - 1),
                  )
                : r,
        ];
      }
      _ruleCode = null;
    });
    _toast('Borrador eliminado.');
  }

  void _runBacktest() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null) return;
    final v = rule.latest;
    final n = v.conditions.length;
    _replaceRule(
      rule.withLatest(
        v.copyWith(
          backtestDone: true,
          hits7d: v.hits7d ?? (140 - 25 * n).clamp(20, 140),
          precision: v.precision ?? (0.38 + 0.05 * n).clamp(0.0, 0.9),
        ),
      ),
    );
    _toast('Backtest listo sobre los últimos 30 días.');
  }

  void _sendToApproval() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null || !rule.latest.backtestDone) return;
    final v = rule.latest;
    _replaceRule(
      rule.withLatest(
        v.copyWith(
          status: RuleStatus.pendingApproval,
          shadowDays: v.shadowDays < 5 ? 5 : v.shadowDays,
          updatedLabel: _stamp,
        ),
      ),
    );
    _toast('Enviada a aprobación: otro líder de riesgo debe aprobarla.');
  }

  void _approve() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null) return;
    final v = rule.latest;
    if (!_user.can(Permission.ruleApprove)) return;
    if (v.createdBy == _user.name) {
      _toast('Quien creó la regla no puede aprobarla.');
      return;
    }
    // The previous ACTIVE version is retired; the new one takes over.
    final older = [
      for (final old in rule.versions.sublist(0, rule.versions.length - 1))
        old.status == RuleStatus.active
            ? old.copyWith(status: RuleStatus.retired)
            : old,
    ];
    _replaceRule(
      rule.copyWith(
        versions: [
          ...older,
          v.copyWith(status: RuleStatus.active, updatedLabel: _stamp),
        ],
      ),
    );
    _toast('Regla activada: ya participa en las decisiones.');
  }

  void _returnToDraft() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null) return;
    _replaceRule(
      rule.withLatest(
        rule.latest.copyWith(
          status: RuleStatus.draft,
          shadowDays: 0,
          backtestDone: false,
          updatedLabel: _stamp,
        ),
      ),
    );
    _toast('La regla volvió a borrador.');
  }

  void _newVersion() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null || rule.latest.status != RuleStatus.active) return;
    final v = rule.latest;
    _replaceRule(
      rule.copyWith(
        versions: [
          ...rule.versions,
          RuleVersion(
            number: v.number + 1,
            action: v.action,
            status: RuleStatus.draft,
            conditions: List.of(v.conditions),
            createdBy: _user.name,
            updatedLabel: _stamp,
          ),
        ],
      ),
    );
    _toast(
      'Nueva versión v${v.number + 1} en borrador. '
      'La activa no se modifica.',
    );
  }

  void _retire() {
    final rule = _ruleByCode(_ruleCode);
    if (rule == null || rule.latest.status != RuleStatus.active) return;
    _replaceRule(
      rule.withLatest(
        rule.latest.copyWith(status: RuleStatus.retired, updatedLabel: _stamp),
      ),
    );
    _toast('Regla retirada.');
  }

  // ---- Models -----------------------------------------------------------

  ModelVersion? get _activeModel {
    for (final m in _models) {
      if (m.status == ModelStatus.active) return m;
    }
    return null;
  }

  void _retrain() {
    final active = _activeModel;
    final next = _models.length + 1;
    final candidate = ModelVersion(
      name: 'v$next',
      trainedAt: 'hoy · 10:05',
      origin: 'Manual · ${_user.name.split(' ').first}',
      prAuc: ((active?.prAuc ?? 0.8) + 0.01),
      recall: ((active?.recall ?? 0.7) + 0.01),
      status: ModelStatus.candidate,
    );
    setState(() => _models = [candidate, ..._models]);
    _toast('Reentrenamiento listo: v$next quedó como candidato.');
  }

  void _activate(String name) {
    setState(() {
      _models = [
        for (final m in _models)
          if (m.name == name)
            m.copyWith(status: ModelStatus.active)
          else if (m.status == ModelStatus.active)
            m.copyWith(status: ModelStatus.retired)
          else
            m,
      ];
    });
    _toast('Modelo $name activado.');
  }

  // ---- Simulator --------------------------------------------------------

  void _startSimulation() {
    final count = parseSimulatorCount(_simCount);
    if (count == null || _simCustomer.trim().isEmpty) return;
    _simTimer?.cancel();
    setState(() {
      _simRun += 1;
      _simHasRun = true;
      _simTotal = count;
      _simEvents = const [];
      _simRunning = true;
    });
    _simTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) return;
      final index = _simEvents.length;
      if (index >= _simTotal) {
        timer.cancel();
        setState(() => _simRunning = false);
        return;
      }
      final event = simulateEvent(
        scenarioCode: _scenario,
        customer: _simCustomer.trim(),
        index: index,
      );
      final done = index + 1 >= _simTotal;
      setState(() {
        _simEvents = [..._simEvents, event];
        if (done) _simRunning = false;
      });
      if (done) timer.cancel();
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    setState(() => _simRunning = false);
  }

  // ---- Build ------------------------------------------------------------

  static const Map<ConsoleSection, (String, MsIconName)> _nav = {
    ConsoleSection.dashboard: ('Dashboard', MsIconName.dashboard),
    ConsoleSection.cases: ('Casos', MsIconName.inbox),
    ConsoleSection.rules: ('Reglas', MsIconName.sliders),
    ConsoleSection.models: ('Modelos', MsIconName.cpu),
    ConsoleSection.simulator: ('Simulador', MsIconName.play),
  };

  List<NotificationItem> _notifications() {
    final items = <NotificationItem>[];
    if (_user.can(Permission.caseRead)) {
      final unassigned = _cases
          .where((c) => c.status != CaseStatus.resolved && c.assignedTo == null)
          .length;
      if (unassigned > 0) {
        items.add(
          NotificationItem(
            message: unassigned == 1
                ? '1 caso sin asignar en la cola.'
                : '$unassigned casos sin asignar en la cola.',
            onOpen: () {
              _caseTab = CaseTab.unassigned;
              _select(ConsoleSection.cases);
            },
          ),
        );
      }
    }
    if (_user.can(Permission.ruleRead)) {
      final pending = [
        for (final r in _rules)
          if (r.latest.status == RuleStatus.pendingApproval) r,
      ];
      if (pending.isNotEmpty) {
        items.add(
          NotificationItem(
            message: pending.length == 1
                ? 'La regla ${pending.first.code} espera aprobación.'
                : '${pending.length} reglas esperan aprobación.',
            onOpen: () {
              _ruleTab = RuleTab.pending;
              _select(ConsoleSection.rules);
              if (pending.length == 1) {
                setState(() => _ruleCode = pending.first.code);
              }
            },
          ),
        );
      }
    }
    if (_user.can(Permission.modelRead)) {
      for (final m in _models) {
        if (m.status == ModelStatus.candidate) {
          items.add(
            NotificationItem(
              message: 'El modelo ${m.name} está como candidato.',
              onOpen: () => _select(ConsoleSection.models),
            ),
          );
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowedSections();
    return NotificationsScope(
      items: _notifications(),
      child: _scaffold(allowed),
    );
  }

  Widget _scaffold(List<ConsoleSection> allowed) {
    return Scaffold(
      backgroundColor: MsColors.bgCanvas,
      body: Row(
        children: [
          Sidebar(
            items: [
              for (final s in allowed)
                SidebarItem(id: s.name, label: _nav[s]!.$1, icon: _nav[s]!.$2),
            ],
            selectedId: _section?.name ?? '',
            onSelect: (id) =>
                _select(ConsoleSection.values.firstWhere((s) => s.name == id)),
            user: _user,
            onLogout: widget.onLogout,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final section = _section;
    if (section == null) {
      return const EmptyState(
        title: 'Tu cuenta no tiene acceso a ninguna sección',
        hint: 'Pide a un administrador que te asigne un rol.',
      );
    }
    switch (section) {
      case ConsoleSection.dashboard:
        return DashboardPage(
          activeModel: _activeModel,
          recentCases: _cases
              .where((c) => c.status != CaseStatus.resolved)
              .take(3)
              .toList(),
          onOpenCase: (id) => setState(() {
            _section = ConsoleSection.cases;
            _caseId = id;
          }),
          onSeeAllCases: _user.can(Permission.caseRead)
              ? () => _select(ConsoleSection.cases)
              : null,
        );
      case ConsoleSection.cases:
        return _casesBody();
      case ConsoleSection.rules:
        return _rulesBody();
      case ConsoleSection.models:
        return ModelsPage(
          models: _models,
          canTrain: _user.can(Permission.modelTrain),
          onRetrain: _retrain,
          onActivate: _activate,
        );
      case ConsoleSection.simulator:
        return SimulatorPage(
          scenarioCode: _scenario,
          customer: _simCustomer,
          countText: _simCount,
          running: _simRunning,
          runNumber: _simHasRun ? _simRun : 0,
          total: _simTotal,
          events: _simEvents,
          onScenarioChanged: (code) => setState(() => _scenario = code),
          onCustomerChanged: (v) => setState(() => _simCustomer = v),
          onCountChanged: (v) => setState(() => _simCount = v),
          onStart: _startSimulation,
          onStop: _stopSimulation,
        );
    }
  }

  Widget _casesBody() {
    final id = _caseId;
    if (id != null) {
      final match = _cases.where((c) => c.id == id);
      if (match.isNotEmpty) {
        final c = match.first;
        return CaseDetailPage(
          key: ValueKey('${c.id}-${c.status.name}'),
          fraudCase: c,
          currentUserName: _user.name,
          canResolve: _user.can(Permission.caseResolve),
          onBack: () => setState(() => _caseId = null),
          onTake: () => _takeCase(c.id),
          onSaveLabel: (label, notes) => _saveLabel(c.id, label, notes),
        );
      }
    }
    return CasesPage(
      cases: _cases,
      currentUserName: _user.name,
      tab: _caseTab,
      onTabChanged: (tab) => setState(() => _caseTab = tab),
      verdictFilter: _verdictFilter,
      onVerdictFilterTap: _cycleVerdictFilter,
      searchController: _search,
      onSearchChanged: (_) => setState(() {}),
      onOpenCase: (id) => setState(() => _caseId = id),
    );
  }

  Widget _rulesBody() {
    final rule = _ruleByCode(_ruleCode);
    if (_creatingRule || rule != null) {
      final v = rule?.latest;
      return RuleEditorPage(
        key: ValueKey(
          rule == null
              ? 'new-rule'
              : '${rule.code}-${v!.number}-${v.status.name}',
        ),
        rule: rule,
        currentUserName: _user.name,
        canWrite: _user.can(Permission.ruleWrite),
        canApprove: _user.can(Permission.ruleApprove),
        activeModelRecall: _activeModel?.recall ?? 0.74,
        onBack: () => setState(() {
          _ruleCode = null;
          _creatingRule = false;
        }),
        onSave: _saveRule,
        onDeleteDraft: _deleteDraft,
        onSendToShadow: _sendToShadow,
        onRunBacktest: _runBacktest,
        onSendToApproval: _sendToApproval,
        onApprove: _approve,
        onReturnToDraft: _returnToDraft,
        onNewVersion: _newVersion,
        onRetire: _retire,
      );
    }
    return RulesPage(
      rules: _rules,
      canWrite: _user.can(Permission.ruleWrite),
      tab: _ruleTab,
      onTabChanged: (tab) => setState(() => _ruleTab = tab),
      onOpenRule: (code) => setState(() => _ruleCode = code),
      onNewRule: () => setState(() {
        _creatingRule = true;
        _ruleCode = null;
      }),
    );
  }
}
