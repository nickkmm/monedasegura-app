import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/data_display.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/page_frame.dart';

/// Models: the production model, decision thresholds, versions and the most
/// influential variables. The host owns the versions.
class ModelsPage extends StatelessWidget {
  const ModelsPage({
    super.key,
    required this.models,
    required this.canTrain,
    required this.onRetrain,
    required this.onActivate,
  });

  final List<ModelVersion> models;

  /// The user has `MODEL_TRAIN`.
  final bool canTrain;
  final VoidCallback onRetrain;
  final ValueChanged<String> onActivate;

  StatusTone _tone(ModelStatus status) {
    switch (status) {
      case ModelStatus.active:
        return StatusTone.success;
      case ModelStatus.candidate:
        return StatusTone.accent;
      case ModelStatus.retired:
        return StatusTone.neutral;
    }
  }

  String _signed(double value) {
    final text = formatDecimal(value.abs());
    return value < 0 ? '-$text' : '+$text';
  }

  @override
  Widget build(BuildContext context) {
    ModelVersion? active;
    ModelVersion? previous;
    for (final m in models) {
      if (m.status == ModelStatus.active) active ??= m;
      if (m.status == ModelStatus.retired) previous ??= m;
    }
    return PageFrame(
      title: 'Modelos',
      subtitle: 'Modelo de scoring · LightGBM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _productionCard(active, previous)),
              const SizedBox(width: MsSpace.xl),
              SizedBox(width: 360, child: _thresholdsCard()),
            ],
          ),
          const SizedBox(height: MsSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _versionsCard()),
              const SizedBox(width: MsSpace.xl),
              SizedBox(width: 360, child: _importanceCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productionCard(ModelVersion? active, ModelVersion? previous) {
    final white72 = MsText.body.copyWith(color: const Color(0xB8FFFFFF));
    String delta(double? now, double? before) {
      if (now == null || before == null) return 'sin versión anterior';
      return '${_signed(now - before)} vs. anterior';
    }

    Color? deltaColor(double? now, double? before) =>
        (now != null && before != null && now < before)
        ? const Color(0xFFF2A39B)
        : null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MsColors.bgInverse,
        borderRadius: BorderRadius.circular(MsRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modelo en producción',
                style: MsText.label.copyWith(color: const Color(0xB8FFFFFF)),
              ),
              if (active != null)
                StatusPill(
                  label: modelStatusLabel(active.status),
                  tone: StatusTone.success,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            active?.name ?? '—',
            style: MsText.display.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            active == null
                ? 'No hay un modelo activo'
                : 'Entrenado ${active.trainedAt} · '
                      '${active.origin.toLowerCase()} · 182.400 transacciones',
            style: white72,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  onDark: true,
                  label: 'PR-AUC',
                  value: active == null ? '—' : formatDecimal(active.prAuc),
                  delta: delta(active?.prAuc, previous?.prAuc),
                  deltaColor: deltaColor(active?.prAuc, previous?.prAuc),
                ),
              ),
              const SizedBox(width: MsSpace.md),
              Expanded(
                child: MetricTile(
                  onDark: true,
                  label: 'Recall',
                  value: active == null ? '—' : formatDecimal(active.recall),
                  delta: delta(active?.recall, previous?.recall),
                  deltaColor: deltaColor(active?.recall, previous?.recall),
                ),
              ),
              const SizedBox(width: MsSpace.md),
              const Expanded(
                child: MetricTile(
                  onDark: true,
                  label: 'Precisión',
                  value: '0,62',
                  delta: '+0,01 vs. anterior',
                ),
              ),
              const SizedBox(width: MsSpace.md),
              const Expanded(
                child: MetricTile(
                  onDark: true,
                  label: 'Fraudes vistos',
                  value: '1.940',
                  delta: '+120 vs. anterior',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thresholdsCard() {
    Widget legend(String label, Color color, String range) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: MsSpace.sm),
            Text(label, style: MsText.body),
          ],
        ),
        Text(range, style: MsText.bodyStrong),
      ],
    );

    Widget segment(int flex, Color color) => Expanded(
      flex: flex,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );

    return MsCard(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Umbrales de decisión', style: MsText.heading),
          const SizedBox(height: MsSpace.xs),
          const Text(
            'Según el puntaje de riesgo del modelo',
            style: MsText.caption,
          ),
          const SizedBox(height: MsSpace.lg),
          Row(
            children: [
              segment(60, MsColors.approve),
              const SizedBox(width: 3),
              segment(30, MsColors.review),
              const SizedBox(width: 3),
              segment(10, MsColors.block),
            ],
          ),
          const SizedBox(height: MsSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in const ['0', '0,60', '0,90', '1'])
                Text(
                  t,
                  style: MsText.caption.copyWith(color: MsColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          legend('Aprobar', MsColors.approve, '< 0,60'),
          const SizedBox(height: 10),
          legend('Revisar', MsColors.review, '0,60 – 0,90'),
          const SizedBox(height: 10),
          legend('Bloquear', MsColors.block, '≥ 0,90'),
        ],
      ),
    );
  }

  Widget _versionsCard() {
    return MsCard(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Versiones', style: MsText.heading),
                    SizedBox(height: MsSpace.xs),
                    Text(
                      'Reentrenamiento automático cada noche a las 02:00',
                      style: MsText.caption,
                    ),
                  ],
                ),
              ),
              if (canTrain)
                MsButton(label: 'Reentrenar ahora', onPressed: onRetrain),
            ],
          ),
          const SizedBox(height: MsSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MsColors.bgSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Versión', style: MsText.label)),
                const SizedBox(
                  width: 130,
                  child: Text('Entrenado', style: MsText.label),
                ),
                const SizedBox(
                  width: 150,
                  child: Text('Origen', style: MsText.label),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('PR-AUC', style: MsText.label),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('Recall', style: MsText.label),
                ),
                const SizedBox(
                  width: 110,
                  child: Text('Estado', style: MsText.label),
                ),
                if (canTrain) const SizedBox(width: 96),
              ],
            ),
          ),
          for (var i = 0; i < models.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: i < models.length - 1
                    ? const Border(
                        bottom: BorderSide(color: MsColors.borderDefault),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(models[i].name, style: MsText.bodyStrong),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      models[i].trainedAt,
                      style: MsText.body.copyWith(
                        color: MsColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      models[i].origin,
                      overflow: TextOverflow.ellipsis,
                      style: MsText.body.copyWith(
                        color: MsColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      formatDecimal(models[i].prAuc),
                      style: MsText.body.copyWith(
                        color: MsColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      formatDecimal(models[i].recall),
                      style: MsText.body.copyWith(
                        color: MsColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(
                        label: modelStatusLabel(models[i].status),
                        tone: _tone(models[i].status),
                      ),
                    ),
                  ),
                  if (canTrain)
                    SizedBox(
                      width: 96,
                      child: models[i].status != ModelStatus.active
                          ? MsButton(
                              label: 'Activar',
                              variant: MsButtonVariant.secondary,
                              height: 32,
                              onPressed: () => onActivate(models[i].name),
                            )
                          : null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _importanceCard() {
    return MsCard(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Variables más influyentes', style: MsText.heading),
          const SizedBox(height: MsSpace.xs),
          const Text(
            'Importancia relativa en la versión activa',
            style: MsText.caption,
          ),
          const SizedBox(height: 18),
          for (final f in featureImportance) ...[
            FeatureBar(label: f.$1, value: f.$2),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
