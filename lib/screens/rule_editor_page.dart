import 'package:flutter/material.dart';

import '../data/prototype_labels.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/condition_row.dart';
import '../widgets/data_display.dart';
import '../widgets/ms_avatar.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_icon.dart';
import '../widgets/ms_segmented.dart';
import '../widgets/ms_text_field.dart';
import '../widgets/page_frame.dart';
import '../widgets/progress_feedback.dart';

/// Values of the editor form. The host validates and stores them.
class RuleDraft {
  const RuleDraft({
    required this.code,
    required this.description,
    required this.action,
    required this.conditions,
  });

  final String code;
  final String description;
  final RuleAction action;
  final List<RuleCondition> conditions;
}

/// Backtest figures derived from the stored hits and precision. The 30-day
/// backtest window sees about 1.3 times the 7-day hits; 1.920 labeled cases
/// of which 290 are fraud (the prototype's simulated figures).
class BacktestFigures {
  BacktestFigures(RuleVersion v) {
    final hits7d = v.hits7d ?? 0;
    matches = (hits7d * 1.3).round();
    caught = (matches * (v.precision ?? 0)).round();
    extraCaught = (caught * 0.22).round();
    recallGainPp = extraCaught / 290 * 100;
  }

  static const int labeledCases = 1920;

  late final int matches;
  late final int caught;
  late final int extraCaught;
  late final double recallGainPp;
}

/// Rule editor / viewer. [rule] is null when a new rule is being created.
/// Every lifecycle action is reported up; the host changes the rule.
class RuleEditorPage extends StatefulWidget {
  const RuleEditorPage({
    super.key,
    required this.rule,
    required this.currentUserName,
    required this.canWrite,
    required this.canApprove,
    required this.activeModelRecall,
    required this.onBack,
    required this.onSave,
    required this.onDeleteDraft,
    required this.onSendToShadow,
    required this.onRunBacktest,
    required this.onSendToApproval,
    required this.onApprove,
    required this.onReturnToDraft,
    required this.onNewVersion,
    required this.onRetire,
  });

  final Rule? rule;
  final String currentUserName;

  /// The user has `RULE_WRITE`.
  final bool canWrite;

  /// The user has `RULE_APPROVE`.
  final bool canApprove;
  final double activeModelRecall;
  final VoidCallback onBack;

  /// Creates (new rule) or updates the draft. Returns an error message in
  /// Spanish, or null when it was saved.
  final String? Function(RuleDraft draft) onSave;
  final VoidCallback onDeleteDraft;

  /// Saves the form and moves the draft to SHADOW. Returns an error or null.
  final String? Function(RuleDraft draft) onSendToShadow;
  final VoidCallback onRunBacktest;
  final VoidCallback onSendToApproval;
  final VoidCallback onApprove;
  final VoidCallback onReturnToDraft;
  final VoidCallback onNewVersion;
  final VoidCallback onRetire;

  @override
  State<RuleEditorPage> createState() => _RuleEditorPageState();
}

class _RuleEditorPageState extends State<RuleEditorPage> {
  // Form draft; the stored rule lives in the host.
  late final TextEditingController _code = TextEditingController(
    text: widget.rule?.code ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.rule?.description ?? '',
  );
  late RuleAction _action = widget.rule?.latest.action ?? RuleAction.review;
  late final List<RuleCondition> _conditions = widget.rule == null
      ? [const RuleCondition(feature: 'amount', operator: '≥', value: '')]
      : List.of(widget.rule!.latest.conditions);
  String? _error;

  bool get _isNew => widget.rule == null;
  RuleVersion? get _version => widget.rule?.latest;
  bool get _editable =>
      widget.canWrite && (_isNew || _version!.status == RuleStatus.draft);

  RuleDraft get _draft => RuleDraft(
    code: _code.text.trim(),
    description: _description.text.trim(),
    action: _action,
    conditions: List.unmodifiable(_conditions),
  );

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    super.dispose();
  }

  void _run(String? Function(RuleDraft) action) {
    final error = action(_draft);
    setState(() => _error = error);
  }

  FlowStepState _stepState(int index) {
    final status = _version?.status ?? RuleStatus.draft;
    if (status == RuleStatus.active || status == RuleStatus.retired) {
      return FlowStepState.done;
    }
    final current = status == RuleStatus.draft
        ? 0
        : (status == RuleStatus.shadow ? 1 : 2);
    if (index < current) return FlowStepState.done;
    return index == current ? FlowStepState.current : FlowStepState.pending;
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final v = _version;
    final shadowDays = v?.shadowDays ?? 0;
    return PageFrame(
      title: rule == null ? 'Nueva regla' : '${rule.code} · v${v!.number}',
      subtitle: rule == null
          ? 'Define la condición y la acción del borrador'
          : rule.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MsButton(
                label: '← Reglas',
                variant: MsButtonVariant.ghost,
                onPressed: widget.onBack,
              ),
              const Spacer(),
              StepperStep(label: 'Borrador', state: _stepState(0)),
              _line(_stepState(0) == FlowStepState.done),
              StepperStep(
                label: shadowDays > 0 ? 'Shadow · $shadowDays d' : 'Shadow',
                state: _stepState(1),
              ),
              _line(_stepState(1) == FlowStepState.done),
              StepperStep(label: 'Aprobación', state: _stepState(2)),
              _line(_stepState(2) == FlowStepState.done),
              StepperStep(
                label: 'Activa',
                state: v?.status == RuleStatus.active
                    ? FlowStepState.done
                    : (v?.status == RuleStatus.retired
                          ? FlowStepState.done
                          : FlowStepState.pending),
              ),
            ],
          ),
          const SizedBox(height: MsSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_editable && (_isNew || v!.status == RuleStatus.draft))
                      _identityCard(),
                    if (_editable) const SizedBox(height: MsSpace.lg),
                    _conditionCard(),
                    if (v != null &&
                        (v.status == RuleStatus.shadow ||
                            v.status == RuleStatus.pendingApproval ||
                            v.status == RuleStatus.active)) ...[
                      const SizedBox(height: MsSpace.lg),
                      _backtestCard(v),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _approvalCard(),
                    if (rule != null) ...[
                      const SizedBox(height: MsSpace.lg),
                      _versionsCard(rule),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(bool done) => Container(
    width: 28,
    height: 1.5,
    margin: const EdgeInsets.symmetric(horizontal: MsSpace.sm),
    color: done ? MsColors.bgInverse : MsColors.borderStrong,
  );

  Widget _identityCard() {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Identificación', style: MsText.heading),
          const SizedBox(height: MsSpace.lg),
          MsTextField(
            label: 'Código',
            controller: _code,
            hint: 'NIGHT_TRANSFER',
            enabled: _isNew,
          ),
          const SizedBox(height: MsSpace.md),
          MsTextField(
            label: 'Descripción',
            controller: _description,
            hint: 'Transferencia de noche ≥ \$ 2.000.000',
          ),
        ],
      ),
    );
  }

  Widget _conditionCard() {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Condición', style: MsText.heading),
          const SizedBox(height: MsSpace.xxs),
          const Text(
            'Se cumple cuando se cumplen todas',
            style: MsText.caption,
          ),
          const SizedBox(height: MsSpace.lg),
          for (var i = 0; i < _conditions.length; i++) ...[
            ConditionRow(
              key: ValueKey('condition-$i'),
              condition: _conditions[i],
              onChanged: _editable
                  ? (c) => setState(() => _conditions[i] = c)
                  : null,
              onRemove: _editable && _conditions.length > 1
                  ? () => setState(() => _conditions.removeAt(i))
                  : null,
            ),
            const SizedBox(height: MsSpace.sm),
          ],
          if (_editable)
            Align(
              alignment: Alignment.centerLeft,
              child: MsButton(
                label: 'Agregar condición',
                variant: MsButtonVariant.ghost,
                icon: MsIconName.plus,
                onPressed: () => setState(
                  () => _conditions.add(
                    const RuleCondition(
                      feature: 'amount',
                      operator: '≥',
                      value: '',
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: MsSpace.md),
          Row(
            children: [
              const Text('Acción', style: MsText.bodyStrong),
              const SizedBox(width: MsSpace.md),
              MsSegmented<RuleAction>(
                options: [
                  (RuleAction.review, ruleActionLabel(RuleAction.review)),
                  (RuleAction.block, ruleActionLabel(RuleAction.block)),
                ],
                value: _action,
                onChanged: _editable
                    ? (a) => setState(() => _action = a)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backtestCard(RuleVersion v) {
    final figures = BacktestFigures(v);
    final recallAfter = widget.activeModelRecall + figures.recallGainPp / 100;
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backtest · últimos 30 días', style: MsText.heading),
                    SizedBox(height: MsSpace.xxs),
                    Text(
                      'Sobre 1.920 casos etiquetados',
                      style: MsText.caption,
                    ),
                  ],
                ),
              ),
              if (widget.canWrite && v.status == RuleStatus.shadow)
                MsButton(
                  label: v.backtestDone ? 'Volver a correr' : 'Correr backtest',
                  variant: MsButtonVariant.secondary,
                  onPressed: widget.onRunBacktest,
                ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          if (!v.backtestDone)
            const SizedBox(
              height: 140,
              child: EmptyState(
                title: 'Todavía no hay backtest',
                hint: 'Córrelo para ver cuántos fraudes atraparía esta regla.',
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Coincidencias',
                    value: formatCount(figures.matches),
                    delta:
                        '${formatDecimal(figures.matches / BacktestFigures.labeledCases * 100, 1)} % de los casos',
                  ),
                ),
                const SizedBox(width: MsSpace.lg),
                Expanded(
                  child: MetricTile(
                    label: 'Fraudes atrapados',
                    value: formatCount(figures.caught),
                    delta: '+${figures.extraCaught} que hoy se escapan',
                  ),
                ),
                const SizedBox(width: MsSpace.lg),
                Expanded(
                  child: MetricTile(
                    label: 'Precisión',
                    value: formatDecimal(v.precision ?? 0),
                    delta: 'objetivo ≥ 0,40',
                  ),
                ),
                const SizedBox(width: MsSpace.lg),
                Expanded(
                  child: MetricTile(
                    label: 'Recall total',
                    value: '+${formatDecimal(figures.recallGainPp, 1)} pp',
                    delta:
                        '${formatDecimal(widget.activeModelRecall)} → ${formatDecimal(recallAfter)}',
                  ),
                ),
              ],
            ),
            if (v.shadowDays > 0) ...[
              const SizedBox(height: MsSpace.lg),
              MsBanner(
                message:
                    '${v.shadowDays} días en shadow: '
                    '${v.hits7d ?? 0} coincidencias, ninguna decisión '
                    'cambiada todavía.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<TimelineEvent> _timeline(Rule rule) {
    final v = rule.latest;
    final events = <TimelineEvent>[
      TimelineEvent(
        title: 'Creada por ${v.createdBy}',
        meta: 'v${v.number} · ${v.updatedLabel.split(' · ').first}',
      ),
    ];
    final reachedShadow = v.status != RuleStatus.draft;
    if (reachedShadow) {
      events.add(
        TimelineEvent(
          title: 'Shadow iniciado',
          meta: v.shadowDays > 0
              ? '${v.shadowDays} días en shadow'
              : 'recién iniciado',
        ),
      );
    }
    final reachedApproval =
        v.status == RuleStatus.pendingApproval ||
        v.status == RuleStatus.active ||
        v.status == RuleStatus.retired;
    if (reachedApproval) {
      events.add(
        const TimelineEvent(
          title: 'Enviada a aprobación',
          meta: 'con backtest corrido',
        ),
      );
    }
    if (v.status == RuleStatus.pendingApproval) {
      events.add(
        const TimelineEvent(
          title: 'Esperando a otro líder de riesgo',
          meta: 'Quien la creó no puede aprobarla',
        ),
      );
    }
    if (v.status == RuleStatus.active) {
      events.add(TimelineEvent(title: 'Activada', meta: v.updatedLabel));
    }
    if (v.status == RuleStatus.retired) {
      events.add(TimelineEvent(title: 'Retirada', meta: v.updatedLabel));
    }
    return events;
  }

  Widget _approvalCard() {
    final rule = widget.rule;
    final v = _version;
    final status = v?.status;
    final isOwn = v != null && v.createdBy == widget.currentUserName;
    final buttons = <Widget>[];

    void add(Widget w) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: MsSpace.sm));
      buttons.add(w);
    }

    if (_isNew) {
      if (widget.canWrite) {
        add(
          MsButton(
            label: 'Crear borrador',
            fullWidth: true,
            onPressed: () => _run(widget.onSave),
          ),
        );
      }
    } else if (status == RuleStatus.draft && widget.canWrite) {
      add(
        MsButton(
          label: 'Guardar borrador',
          fullWidth: true,
          onPressed: () => _run(widget.onSave),
        ),
      );
      add(
        MsButton(
          label: 'Enviar a shadow',
          variant: MsButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => _run(widget.onSendToShadow),
        ),
      );
      add(
        MsButton(
          label: 'Eliminar borrador',
          variant: MsButtonVariant.danger,
          fullWidth: true,
          onPressed: widget.onDeleteDraft,
        ),
      );
    } else if (status == RuleStatus.shadow && widget.canWrite) {
      add(
        MsButton(
          label: 'Enviar a aprobación',
          fullWidth: true,
          onPressed: v!.backtestDone ? widget.onSendToApproval : null,
        ),
      );
    } else if (status == RuleStatus.pendingApproval) {
      if (widget.canApprove) {
        add(
          MsButton(
            label: 'Aprobar y activar',
            fullWidth: true,
            onPressed: isOwn ? null : widget.onApprove,
          ),
        );
      }
      if (widget.canApprove || widget.canWrite) {
        add(
          MsButton(
            label: 'Devolver a borrador',
            variant: MsButtonVariant.secondary,
            fullWidth: true,
            onPressed: widget.onReturnToDraft,
          ),
        );
      }
    } else if (status == RuleStatus.active) {
      if (widget.canWrite) {
        add(
          MsButton(
            label: 'Crear nueva versión',
            fullWidth: true,
            onPressed: widget.onNewVersion,
          ),
        );
      }
      if (widget.canApprove) {
        add(
          MsButton(
            label: 'Retirar regla',
            variant: MsButtonVariant.danger,
            fullWidth: true,
            onPressed: widget.onRetire,
          ),
        );
      }
    }

    String? hint;
    if (status == RuleStatus.shadow && widget.canWrite && !v!.backtestDone) {
      hint = 'Corre el backtest antes de enviarla a aprobación.';
    } else if (status == RuleStatus.pendingApproval && isOwn) {
      hint = 'Quien creó la regla no puede aprobarla.';
    } else if (status == RuleStatus.active) {
      hint = 'Una versión activa no se edita: crea una versión nueva.';
    } else if (status == RuleStatus.retired) {
      hint = 'Regla retirada: solo lectura.';
    } else if (!widget.canWrite && !widget.canApprove) {
      hint = 'Tu rol solo puede consultar las reglas.';
    }

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Aprobación en dos pasos', style: MsText.heading),
          if (rule != null) ...[
            const SizedBox(height: MsSpace.lg),
            for (final event in _timeline(rule)) ...[
              event,
              const SizedBox(height: 20),
            ],
          ] else
            const SizedBox(height: MsSpace.lg),
          if (status == RuleStatus.pendingApproval && widget.canApprove) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MsSpace.md,
                vertical: MsSpace.sm,
              ),
              decoration: BoxDecoration(
                color: MsColors.bgCanvas,
                borderRadius: BorderRadius.circular(MsRadius.md),
              ),
              child: Row(
                children: [
                  MsAvatar(initials: initialsOf(widget.currentUserName)),
                  const SizedBox(width: MsSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.currentUserName, style: MsText.bodyStrong),
                        Text(
                          isOwn ? 'No puede aprobar' : 'Puede aprobar',
                          style: MsText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MsSpace.lg),
          ],
          ...buttons,
          if (_error != null) ...[
            const SizedBox(height: MsSpace.sm),
            Text(
              _error!,
              key: const ValueKey('rule-error'),
              style: MsText.caption.copyWith(color: MsColors.block),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: MsSpace.sm),
            Text(hint, style: MsText.caption),
          ],
        ],
      ),
    );
  }

  String _summary(RuleVersion v) {
    RuleCondition? main;
    for (final c in v.conditions) {
      if (c.feature == 'amount') main = c;
    }
    main ??= v.conditions.isEmpty ? null : v.conditions.first;
    final condition = main == null
        ? 'sin condiciones'
        : (main.feature == 'amount'
              ? '${main.operator} ${main.value}'
              : describeCondition(main));
    return '$condition · ${ruleActionLabel(v.action)}';
  }

  Widget _versionsCard(Rule rule) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Versiones', style: MsText.heading),
          const SizedBox(height: MsSpace.lg),
          for (final v in rule.versions.reversed) ...[
            Row(
              children: [
                Text('v${v.number}', style: MsText.bodyStrong),
                const SizedBox(width: MsSpace.md),
                Expanded(child: Text(_summary(v), style: MsText.caption)),
                RuleStatusBadge(status: v.status),
              ],
            ),
            const SizedBox(height: MsSpace.md),
          ],
        ],
      ),
    );
  }
}
