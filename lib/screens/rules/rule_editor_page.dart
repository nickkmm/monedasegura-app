import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// The rule editor content for one version: the stepper, the condition, the
/// backtest, the approval timeline and the versions. Shows only what it is
/// given and reports every action up.
class RuleEditorPage extends StatelessWidget {
  const RuleEditorPage({
    super.key,
    required this.view,
    required this.version,
    required this.now,
    required this.creator,
    required this.approver,
    required this.canWrite,
    required this.canApprove,
    required this.onBack,
    required this.onSelectVersion,
    required this.onStartShadow,
    required this.onRunBacktest,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
    required this.onNewVersion,
  });

  final RuleView view;

  /// The selected version.
  final RuleVersion version;
  final DateTime now;

  /// The user who created [version], for the role label.
  final AppUser? creator;

  /// Who is shown as able to approve [version].
  final AppUser? approver;
  final bool canWrite;
  final bool canApprove;

  final VoidCallback onBack;
  final ValueChanged<int> onSelectVersion;
  final VoidCallback onStartShadow;
  final VoidCallback onRunBacktest;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onNewVersion;

  static const double _sideWidth = 360;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        Row(
          children: [
            AppButton(
              label: 'Reglas',
              icon: AppIcons.back,
              variant: AppButtonVariant.ghost,
              onPressed: onBack,
            ),
            const Spacer(),
            AppStepper(steps: _steps(version, now)),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  _ConditionCard(version: version),
                  _BacktestCard(
                    version: version,
                    now: now,
                    canWrite: canWrite,
                    onRunBacktest: onRunBacktest,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _sideWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  _ApprovalCard(
                    view: view,
                    version: version,
                    now: now,
                    creator: creator,
                    approver: approver,
                    canWrite: canWrite,
                    canApprove: canApprove,
                    onStartShadow: onStartShadow,
                    onSubmit: onSubmit,
                    onApprove: onApprove,
                    onReject: onReject,
                    onNewVersion: onNewVersion,
                  ),
                  _VersionsCard(
                    view: view,
                    selected: version.version,
                    onSelectVersion: onSelectVersion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

int _shadowDays(ShadowStats stats, DateTime now) =>
    now.difference(stats.since).inDays;

String _daysText(int days) => days == 1 ? '1 día' : '$days días';

List<(String, StepperStepState)> _steps(RuleVersion version, DateTime now) {
  const done = StepperStepState.done;
  const current = StepperStepState.current;
  const pending = StepperStepState.pending;
  final (draft, shadow, approval, active) = switch (version.status) {
    RuleStatus.DRAFT => (current, pending, pending, pending),
    RuleStatus.SHADOW => (done, current, pending, pending),
    RuleStatus.PENDING_APPROVAL => (done, done, current, pending),
    RuleStatus.ACTIVE || RuleStatus.RETIRED => (done, done, done, done),
  };
  final stats = version.shadowStats;
  return [
    ('Borrador', draft),
    (
      stats == null ? 'Shadow' : 'Shadow · ${_shadowDays(stats, now)} d',
      shadow,
    ),
    ('Aprobación', approval),
    ('Activa', active),
  ];
}

/// A card heading, with its caption 2 px below when given.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          _Caption(caption),
        ],
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.version});

  final RuleVersion version;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          const _CardTitle(
            title: 'Condición',
            caption: 'Se cumple cuando se cumplen todas',
          ),
          for (final condition in version.conditions)
            ConditionRow(condition: condition),
          Row(
            spacing: AppSpacing.md,
            children: [
              Text(
                'Acción',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSegmentedControl<RuleAction>(
                options: [
                  (RuleAction.REVIEW, RuleAction.REVIEW.label),
                  (RuleAction.BLOCK, RuleAction.BLOCK.label),
                ],
                selected: version.action,
                onChanged: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BacktestCard extends StatelessWidget {
  const _BacktestCard({
    required this.version,
    required this.now,
    required this.canWrite,
    required this.onRunBacktest,
  });

  final RuleVersion version;
  final DateTime now;
  final bool canWrite;
  final VoidCallback onRunBacktest;

  bool get _canRun =>
      version.status == RuleStatus.DRAFT || version.status == RuleStatus.SHADOW;

  String _caughtNote(Backtest backtest) {
    final active = backtest.active;
    if (active == null) return 'Sin versión activa para comparar';
    final difference = backtest.candidate.truePositives - active.truePositives;
    return difference > 0
        ? '+$difference que hoy se escapan'
        : 'Sin fraudes nuevos frente a la versión activa';
  }

  MetricTile _recallTile(Backtest backtest) {
    const label = 'Recall total';
    final before = backtest.systemRecallBefore;
    final after = backtest.systemRecallAfter;
    if (before == null || after == null) {
      return const MetricTile(label: label, value: '—', note: '');
    }
    // Rounded first, so float noise never reads "-0,0 pp".
    final points = ((after - before) * 1000).round() / 10;
    final sign = points >= 0 ? '+' : '-';
    return MetricTile(
      label: label,
      value: '$sign${formatDecimal(points.abs(), digits: 1)} pp',
      note: '${formatDecimal(before)} → ${formatDecimal(after)}',
    );
  }

  String _shadowMessage(ShadowStats stats) {
    final matched = stats.matched == 1
        ? '1 coincidencia'
        : '${formatInt(stats.matched)} coincidencias';
    final changes = switch (stats.verdictChanges) {
      0 => 'ninguna decisión cambiada todavía.',
      1 => '1 decisión cambiaría.',
      final k => '${formatInt(k)} decisiones cambiarían.',
    };
    return '${_daysText(_shadowDays(stats, now))} en shadow: $matched, '
        '$changes';
  }

  Widget _tiles(Backtest backtest) {
    final candidate = backtest.candidate;
    final share = candidate.matches / backtest.casesEvaluated;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Expanded(
            child: MetricTile(
              label: 'Coincidencias',
              value: formatInt(candidate.matches),
              note: '${formatPercent(share, digits: 1)} de los casos',
            ),
          ),
          Expanded(
            child: MetricTile(
              label: 'Fraudes atrapados',
              value: formatInt(candidate.truePositives),
              note: _caughtNote(backtest),
            ),
          ),
          Expanded(
            child: MetricTile(
              label: 'Precisión',
              value: formatDecimal(candidate.precision),
              note: 'objetivo ≥ 0,40',
            ),
          ),
          Expanded(child: _recallTile(backtest)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backtest = version.backtest;
    final stats = version.shadowStats;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardTitle(
                  title: 'Backtest · últimos 30 días',
                  caption: backtest == null
                      ? null
                      : 'Sobre ${formatInt(backtest.casesEvaluated)} casos '
                            'etiquetados',
                ),
              ),
              if (canWrite)
                AppButton(
                  label: backtest == null
                      ? 'Correr backtest'
                      : 'Volver a correr',
                  variant: AppButtonVariant.secondary,
                  onPressed: _canRun ? onRunBacktest : null,
                ),
            ],
          ),
          if (backtest == null)
            const _Caption('Todavía no hay backtest para esta versión.')
          else
            _tiles(backtest),
          if (stats != null)
            AppBanner(
              leading: const RuleStatusBadge(status: RuleStatus.SHADOW),
              message: _shadowMessage(stats),
            ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.view,
    required this.version,
    required this.now,
    required this.creator,
    required this.approver,
    required this.canWrite,
    required this.canApprove,
    required this.onStartShadow,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
    required this.onNewVersion,
  });

  final RuleView view;
  final RuleVersion version;
  final DateTime now;
  final AppUser? creator;
  final AppUser? approver;
  final bool canWrite;
  final bool canApprove;
  final VoidCallback onStartShadow;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onNewVersion;

  String _createdMeta() {
    final date = formatDayMonth(version.createdAt);
    final roles = creator?.roles ?? const <RoleCode>[];
    return roles.isEmpty ? date : '${roles.first.label} · $date';
  }

  List<Widget> _events() {
    final stats = version.shadowStats;
    final submittedAt = version.submittedAt;
    final approvedBy = version.approvedBy;
    final approvedAt = version.approvedAt;
    final reason = version.rejectionReason;
    final status = version.status;
    return [
      TimelineEvent(
        title: 'Creada por ${version.createdBy.fullName}',
        meta: _createdMeta(),
      ),
      if (stats != null)
        TimelineEvent(
          title: 'Shadow iniciado',
          meta:
              '${formatDayMonth(stats.since)} · '
              '${_daysText(_shadowDays(stats, now))}',
        ),
      if (submittedAt != null)
        TimelineEvent(
          title: 'Enviada a aprobación',
          meta: '${formatDayAgo(submittedAt, now)}, ${formatHm(submittedAt)}',
        ),
      if (status == RuleStatus.PENDING_APPROVAL)
        const TimelineEvent(
          title: 'Esperando a otro líder de riesgo',
          meta: 'Quien la creó no puede aprobarla',
        ),
      if ((status == RuleStatus.ACTIVE || status == RuleStatus.RETIRED) &&
          approvedBy != null &&
          approvedAt != null)
        TimelineEvent(
          title: 'Aprobada por ${approvedBy.fullName}',
          meta: formatDayMonth(approvedAt),
        ),
      if (status == RuleStatus.DRAFT && reason != null)
        TimelineEvent(title: 'Devuelta a borrador', meta: reason),
    ];
  }

  Future<void> _openRejectDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason != null) onReject(reason);
  }

  /// The lifecycle action for users with `RULE_WRITE`, if this version has one.
  Widget? _writeAction() {
    final status = version.status;
    if (status == RuleStatus.SHADOW) {
      final hasBacktest = version.backtest != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          AppButton(
            label: 'Enviar a aprobación',
            expand: true,
            onPressed: hasBacktest ? onSubmit : null,
          ),
          if (!hasBacktest)
            const _Caption('Corre el backtest antes de enviar.'),
        ],
      );
    }
    if (status == RuleStatus.DRAFT) {
      return AppButton(
        label: 'Iniciar shadow',
        expand: true,
        onPressed: onStartShadow,
      );
    }
    final inProgress = view.versions.any(
      (v) =>
          v.status == RuleStatus.DRAFT ||
          v.status == RuleStatus.SHADOW ||
          v.status == RuleStatus.PENDING_APPROVAL,
    );
    if (version.version == view.latest.version &&
        (status == RuleStatus.ACTIVE || status == RuleStatus.RETIRED) &&
        !inProgress) {
      return AppButton(
        label: 'Crear nueva versión',
        expand: true,
        onPressed: onNewVersion,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final approver = this.approver;
    final writeAction = canWrite ? _writeAction() : null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          const _CardTitle(title: 'Aprobación en dos pasos'),
          ..._events(),
          if (version.status == RuleStatus.PENDING_APPROVAL && approver != null)
            _ApproverBox(approver: approver),
          if (canApprove)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'Aprobar y activar',
                  expand: true,
                  onPressed: onApprove,
                ),
                AppButton(
                  label: 'Devolver a borrador',
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _openRejectDialog(context),
                ),
              ],
            ),
          ?writeAction,
        ],
      ),
    );
  }
}

class _ApproverBox extends StatelessWidget {
  const _ApproverBox({required this.approver});

  final AppUser approver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          AppAvatar(initials: approver.initials),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approver.fullName,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const _Caption('Puede aprobar'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for the reason to return a version to draft, and pops it trimmed.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  static const double _width = 420;

  String _reason = '';

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SizedBox(
        width: _width,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              const _CardTitle(title: 'Devolver a borrador'),
              AppTextField(
                label: 'Motivo',
                onChanged: (text) => setState(() => _reason = text.trim()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.ghost,
                    onPressed: navigator.pop,
                  ),
                  AppButton(
                    label: 'Devolver',
                    onPressed: _reason.isEmpty
                        ? null
                        : () => navigator.pop(_reason),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionsCard extends StatelessWidget {
  const _VersionsCard({
    required this.view,
    required this.selected,
    required this.onSelectVersion,
  });

  final RuleView view;
  final int selected;
  final ValueChanged<int> onSelectVersion;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          const _CardTitle(title: 'Versiones'),
          for (final version in view.versions)
            _VersionRow(
              version: version,
              selected: version.version == selected,
              onTap: () => onSelectVersion(version.version),
            ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.version,
    required this.selected,
    required this.onTap,
  });

  final RuleVersion version;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = 40;

  /// The `amount` condition if there is one, otherwise the first.
  String _summary() {
    final conditions = version.conditions;
    final shown = conditions.firstWhere(
      (c) => c.feature == 'amount',
      orElse: () => conditions.first,
    );
    return '${shown.op.symbol} '
        '${formatConditionValue(shown.feature, shown.value)} · '
        '${version.action.label}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: selected
              ? BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                )
              : null,
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Text(
                'v${version.version}',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  _summary(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              RuleStatusBadge(status: version.status),
            ],
          ),
        ),
      ),
    );
  }
}
