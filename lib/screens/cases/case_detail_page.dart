import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// The signal features shown as chips, in this order when present.
const _signalFeatures = [
  'amount_vs_avg_30d',
  'is_new_device',
  'km_from_home',
  'tx_count_1h',
  'failed_logins_1h',
  'password_changed_24h',
];

/// Case detail content: the transaction, why it was flagged, the customer
/// and the label form. The host screen owns the state and the store.
///
/// [view] is the case and [rules] the rule of each hit, keyed by `ruleId`.
/// [now] is the clock and [currentUserId] the signed-in user. [canResolve]
/// shows "Tomar caso" and the label card. [selectedLabel] and [notes] hold
/// the label form. [onTake] is `null` when "Tomar caso" must not show, and
/// [onSave] is `null` when "Guardar etiqueta" is disabled.
class CaseDetailPage extends StatelessWidget {
  const CaseDetailPage({
    super.key,
    required this.view,
    required this.rules,
    required this.now,
    required this.currentUserId,
    required this.canResolve,
    required this.selectedLabel,
    required this.notes,
    required this.onBack,
    required this.onTake,
    required this.onSelectLabel,
    required this.onSave,
  });

  final CaseView view;
  final Map<String, RuleView> rules;
  final DateTime now;
  final String? currentUserId;
  final bool canResolve;
  final CaseLabel? selectedLabel;
  final TextEditingController notes;
  final VoidCallback onBack;
  final VoidCallback? onTake;
  final ValueChanged<CaseLabel> onSelectLabel;
  final VoidCallback? onSave;

  static const double _sideWidth = 360;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        Row(
          spacing: AppSpacing.md,
          children: [
            AppButton(
              label: 'Volver a la cola',
              icon: AppIcons.back,
              variant: AppButtonVariant.ghost,
              onPressed: onBack,
            ),
            const Spacer(),
            VerdictBadge(verdict: view.verdict),
            if (view.degraded) const VerdictBadge.degraded(),
            if (view.status == CaseStatus.OPEN && canResolve && onTake != null)
              AppButton(
                label: 'Tomar caso',
                variant: AppButtonVariant.secondary,
                onPressed: onTake,
              ),
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
                  _TransactionCard(view: view, now: now),
                  _WhyFlaggedCard(view: view, rules: rules),
                ],
              ),
            ),
            SizedBox(
              width: _sideWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [
                  _CustomerCard(customer: view.customer),
                  if (canResolve)
                    _LabelCard(
                      view: view,
                      now: now,
                      currentUserId: currentUserId,
                      selectedLabel: selectedLabel,
                      notes: notes,
                      onSelectLabel: onSelectLabel,
                      onSave: onSave,
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

/// Lays [children] out in rows of [columns] equal cells.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.columnGap,
    required this.rowGap,
    required this.children,
  });

  final int columns;
  final double columnGap;
  final double rowGap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: rowGap,
      children: [
        for (var start = 0; start < children.length; start += columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: columnGap,
            children: [
              for (var i = start; i < start + columns; i++)
                Expanded(
                  child: i < children.length
                      ? children[i]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.view, required this.now});

  final CaseView view;
  final DateTime now;

  String get _deviceText {
    final firstSeen = view.device.firstSeenAt;
    if (view.decision.features['is_new_device'] == true) {
      final today =
          firstSeen.year == now.year &&
          firstSeen.month == now.month &&
          firstSeen.day == now.day;
      return today ? 'Nuevo · primera vez hoy' : 'Nuevo';
    }
    return 'Conocido · desde ${formatMonthYear(firstSeen)}';
  }

  String get _locationText {
    final km = view.decision.features['km_from_home'] as num? ?? 0;
    return km < 1 ? 'En su ciudad' : 'A ${km.round()} km de su ciudad';
  }

  @override
  Widget build(BuildContext context) {
    final transaction = view.transaction;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg + AppSpacing.xs,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    'Monto',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(formatCop(view.amount), style: AppTextStyles.metric),
                ],
              ),
              Text(
                '${transaction.currency} · '
                '${formatDateTime(transaction.occurredAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          _Grid(
            columns: 3,
            columnGap: AppSpacing.xl,
            rowGap: AppSpacing.lg + AppSpacing.xs,
            children: [
              DetailField(label: 'Tipo', value: transaction.type.label),
              DetailField(
                label: 'Comercio',
                value: transaction.counterparty ?? '—',
              ),
              DetailField(
                label: 'Categoría',
                value: categoryLabel(transaction.category ?? ''),
              ),
              DetailField(label: 'Dispositivo', value: _deviceText),
              DetailField(label: 'Ubicación', value: _locationText),
              DetailField(
                label: 'Sistema operativo',
                value: view.device.os.label,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhyFlaggedCard extends StatelessWidget {
  const _WhyFlaggedCard({required this.view, required this.rules});

  final CaseView view;
  final Map<String, RuleView> rules;

  static String _signalValue(Object value) => switch (value) {
    true => 'sí',
    false => 'no',
    num() => formatTrimmed(value),
    _ => '$value',
  };

  static String _signalLabel(String name, Object value) =>
      name == 'amount_vs_avg_30d'
      ? '$name × ${_signalValue(value)}'
      : '$name = ${_signalValue(value)}';

  @override
  Widget build(BuildContext context) {
    final features = view.decision.features;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Por qué se marcó', style: AppTextStyles.heading),
              ),
              ScoreBar(
                score: view.score,
                suffix: view.degraded ? ' · solo reglas' : ' · modelo v5',
              ),
            ],
          ),
          for (final hit in view.decision.ruleHits)
            _RuleHitRow(hit: hit, rule: rules[hit.ruleId]),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final name in _signalFeatures)
                  if (features[name] case final value?)
                    SignalChip(label: _signalLabel(name, value)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleHitRow extends StatelessWidget {
  const _RuleHitRow({required this.hit, required this.rule});

  final RuleHit hit;
  final RuleView? rule;

  static const double _mark = 24;
  static const double _markIcon = 14;
  static const double _verticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final actionColor = hit.action == RuleAction.BLOCK
        ? AppColors.statusBlock
        : AppColors.statusReview;
    final (Color markBg, IconData markIcon, Color markColor) = hit.matched
        ? (
            hit.action == RuleAction.BLOCK
                ? AppColors.statusBlockBg
                : AppColors.statusReviewBg,
            AppIcons.check,
            actionColor,
          )
        : (AppColors.bgSubtle, AppIcons.close, AppColors.textTertiary);
    final description = rule == null
        ? hit.ruleCode
        : '${rule!.rule.description} → ${hit.action.label}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Container(
            width: _mark,
            height: _mark,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: markBg, shape: BoxShape.circle),
            child: Icon(markIcon, size: _markIcon, color: markColor),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.ruleCode,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: hit.matched
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hit.shadow)
            const RuleStatusBadge(status: RuleStatus.SHADOW)
          else if (hit.matched)
            Text(
              'Coincide',
              style: AppTextStyles.caption.copyWith(color: actionColor),
            )
          else
            Text(
              'No coincide',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final Customer customer;

  /// First letter of each word, uppercase, punctuation ignored.
  String get _initials => customer.maskedName
      .split(RegExp(r'\s+'))
      .map((word) => word.replaceAll(RegExp(r'[^\p{L}]', unicode: true), ''))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join();

  String get _lastFour {
    final digits = customer.maskedDocument.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg + AppSpacing.xs,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              AppAvatar(initials: _initials),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.maskedName, style: AppTextStyles.heading),
                    Text(
                      'Documento •••• $_lastFour',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Grid(
            columns: 2,
            columnGap: AppSpacing.lg,
            rowGap: AppSpacing.lg,
            children: [
              DetailField(label: 'Ciudad', value: customer.homeCity),
              DetailField(
                label: 'Cliente desde',
                value: formatMonthYear(customer.createdAt),
              ),
              DetailField(
                label: 'Transacciones 30 d',
                value: '${customer.transactions30d}',
              ),
              DetailField(
                label: 'Fraudes previos',
                value: '${customer.previousFrauds}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.view,
    required this.now,
    required this.currentUserId,
    required this.selectedLabel,
    required this.notes,
    required this.onSelectLabel,
    required this.onSave,
  });

  final CaseView view;
  final DateTime now;
  final String? currentUserId;
  final CaseLabel? selectedLabel;
  final TextEditingController notes;
  final ValueChanged<CaseLabel> onSelectLabel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final resolved = view.status == CaseStatus.RESOLVED;
    final assignedToOther =
        view.status == CaseStatus.IN_REVIEW &&
        view.assignedTo?.id != currentUserId;
    final editable = !resolved && !assignedToOther;
    final selected = resolved ? view.label : selectedLabel;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Etiquetar caso', style: AppTextStyles.heading),
              if (assignedToOther)
                Text(
                  'Asignado a ${view.assignedTo?.fullName ?? ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              for (final label in CaseLabel.values)
                OptionCard(
                  title: label.label,
                  subtitle: label.hint,
                  selected: selected == label,
                  danger: label == CaseLabel.CONFIRMED_FRAUD,
                  onTap: editable ? () => onSelectLabel(label) : null,
                ),
            ],
          ),
          AppTextField(
            label: 'Notas',
            hintText: 'El cliente no reconoce la compra…',
            controller: notes,
            enabled: !assignedToOther,
            readOnly: resolved,
          ),
          if (!resolved)
            AppButton(
              label: 'Guardar etiqueta',
              expand: true,
              onPressed: editable ? onSave : null,
            ),
          Row(
            spacing: AppSpacing.sm,
            children: [
              const Icon(
                AppIcons.clock,
                size: AppIcons.size,
                color: AppColors.textTertiary,
              ),
              Expanded(
                child: Text(
                  resolved
                      ? 'Resuelto ${formatAgo(view.resolvedAt!, now)}'
                      : 'La etiqueta entra al reentrenamiento de las 02:00',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
