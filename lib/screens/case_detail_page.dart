import 'package:flutter/material.dart';

import '../data/prototype_labels.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/data_display.dart';
import '../widgets/ms_avatar.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_icon.dart';
import '../widgets/ms_text_field.dart';
import '../widgets/option_card.dart';
import '../widgets/page_frame.dart';
import '../widgets/score_bar.dart';

/// Case detail with the transaction, why it was flagged, the customer and the
/// labeling form. The host owns the case; this page reports actions up.
class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({
    super.key,
    required this.fraudCase,
    required this.currentUserName,
    required this.canResolve,
    required this.onBack,
    required this.onTake,
    required this.onSaveLabel,
  });

  final FraudCase fraudCase;
  final String currentUserName;

  /// The user has `CASE_RESOLVE`.
  final bool canResolve;
  final VoidCallback onBack;
  final VoidCallback onTake;
  final void Function(CaseLabel label, String notes) onSaveLabel;

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  // Draft of the labeling form; the saved label lives in the host.
  CaseLabel? _selected;
  late final TextEditingController _notes = TextEditingController(
    text: widget.fraudCase.notes,
  );

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Color _verdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.block:
        return MsColors.block;
      case Verdict.review:
        return MsColors.review;
      case Verdict.approve:
        return MsColors.approve;
    }
  }

  Color _verdictBg(Verdict verdict) {
    switch (verdict) {
      case Verdict.block:
        return MsColors.blockBg;
      case Verdict.review:
        return MsColors.reviewBg;
      case Verdict.approve:
        return MsColors.approveBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.fraudCase;
    final assignedLabel = c.assignedTo == null
        ? 'sin asignar'
        : 'asignado a ${c.assignedTo}';
    final isMine = c.assignedTo == widget.currentUserName;
    final canTake =
        widget.canResolve &&
        c.status == CaseStatus.open &&
        c.assignedTo == null;
    final canLabel =
        widget.canResolve && c.status == CaseStatus.inReview && isMine;

    return PageFrame(
      title: 'Caso ${c.id}',
      subtitle: 'Abierto ${c.ageLabel} · $assignedLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MsButton(
                label: '← Volver a la cola',
                variant: MsButtonVariant.ghost,
                onPressed: widget.onBack,
              ),
              const Spacer(),
              VerdictBadge(verdict: c.verdict),
              const SizedBox(width: MsSpace.md),
              if (canTake)
                MsButton(
                  label: 'Tomar caso',
                  variant: MsButtonVariant.secondary,
                  onPressed: widget.onTake,
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
                    _transactionCard(c),
                    const SizedBox(height: MsSpace.lg),
                    _whyFlaggedCard(c),
                  ],
                ),
              ),
              const SizedBox(width: MsSpace.lg),
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _customerCard(c),
                    const SizedBox(height: MsSpace.lg),
                    _labelCard(c, canLabel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(FraudCase c) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto', style: MsText.caption),
                    const SizedBox(height: MsSpace.xxs),
                    Text(formatCop(c.amount), style: MsText.metric),
                  ],
                ),
              ),
              Text(
                c.occurredAt,
                style: MsText.caption.copyWith(color: MsColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          Wrap(
            spacing: MsSpace.xl,
            runSpacing: 20,
            children: [
              for (final field in [
                ('Tipo', c.type == 'Transferencia' ? c.type : 'Compra'),
                ('Comercio', c.merchant),
                ('Categoría', c.category),
                ('Dispositivo', c.device),
                ('Ubicación', c.location),
                ('Sistema operativo', c.os),
              ])
                SizedBox(
                  width: 220,
                  child: DetailField(label: field.$1, value: field.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whyFlaggedCard(FraudCase c) {
    final color = _verdictColor(c.verdict);
    final bg = _verdictBg(c.verdict);
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Por qué se marcó', style: MsText.heading),
              ),
              ScoreBar(
                score: c.score,
                text: c.score == null
                    ? 'Sin score · solo reglas'
                    : '${formatScore(c.score)} · modelo v5',
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          for (final hit in c.ruleHits)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MsColors.borderDefault),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hit.matched ? bg : MsColors.bgSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: MsIcon(
                      hit.matched ? MsIconName.check : MsIconName.x,
                      size: 14,
                      color: hit.matched ? color : MsColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: MsSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hit.code,
                          style: MsText.bodyStrong.copyWith(
                            color: hit.matched
                                ? MsColors.textPrimary
                                : MsColors.textTertiary,
                          ),
                        ),
                        Text(hit.description, style: MsText.caption),
                      ],
                    ),
                  ),
                  if (hit.shadow)
                    const RuleStatusBadge(status: RuleStatus.shadow)
                  else
                    Text(
                      hit.matched ? 'Coincide' : 'No coincide',
                      style: MsText.caption.copyWith(
                        color: hit.matched ? color : MsColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: MsSpace.lg),
          Wrap(
            spacing: MsSpace.sm,
            runSpacing: MsSpace.sm,
            children: [for (final s in c.signals) SignalChip(label: s)],
          ),
        ],
      ),
    );
  }

  Widget _customerCard(FraudCase c) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MsAvatar(initials: initialsOf(c.customerName)),
              const SizedBox(width: MsSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.customerName, style: MsText.heading),
                  Text('Documento ${c.document}', style: MsText.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          Wrap(
            spacing: MsSpace.lg,
            runSpacing: MsSpace.lg,
            children: [
              for (final field in [
                ('Ciudad', c.city),
                ('Cliente desde', c.customerSince),
                ('Transacciones 30 d', '${c.tx30d}'),
                ('Fraudes previos', '${c.previousFrauds}'),
              ])
                SizedBox(
                  width: 140,
                  child: DetailField(label: field.$1, value: field.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelCard(FraudCase c, bool canLabel) {
    final resolved = c.status == CaseStatus.resolved;
    final shown = resolved ? c.label : _selected;
    final editable = canLabel;
    String? hint;
    if (!resolved && !editable) {
      hint = widget.canResolve
          ? 'Toma el caso para poder etiquetarlo.'
          : 'No tienes permiso para etiquetar casos.';
    }
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Etiquetar caso', style: MsText.heading),
          const SizedBox(height: MsSpace.lg),
          OptionCard(
            title: 'Fraude confirmado',
            code: 'No la hizo el cliente',
            selected: shown == CaseLabel.confirmedFraud,
            danger: true,
            onTap: editable
                ? () => setState(() => _selected = CaseLabel.confirmedFraud)
                : null,
          ),
          const SizedBox(height: MsSpace.sm),
          OptionCard(
            title: 'Legítima',
            code: 'La hizo el cliente',
            selected: shown == CaseLabel.dismissed,
            onTap: editable
                ? () => setState(() => _selected = CaseLabel.dismissed)
                : null,
          ),
          const SizedBox(height: MsSpace.lg),
          MsTextField(
            label: 'Notas',
            controller: _notes,
            hint: 'El cliente no reconoce la compra…',
            enabled: editable,
          ),
          const SizedBox(height: MsSpace.lg),
          MsButton(
            label: resolved ? 'Etiqueta guardada' : 'Guardar etiqueta',
            fullWidth: true,
            onPressed: editable && _selected != null
                ? () => widget.onSaveLabel(_selected!, _notes.text.trim())
                : null,
          ),
          if (hint != null) ...[
            const SizedBox(height: MsSpace.sm),
            Text(hint, style: MsText.caption),
          ],
          const SizedBox(height: MsSpace.lg),
          Row(
            children: [
              const MsIcon(
                MsIconName.clock,
                size: 16,
                color: MsColors.textTertiary,
              ),
              const SizedBox(width: MsSpace.xs),
              Expanded(
                child: Text(
                  'La etiqueta entra al reentrenamiento de las 02:00',
                  style: MsText.caption.copyWith(color: MsColors.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
