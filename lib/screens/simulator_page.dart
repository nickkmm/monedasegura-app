import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/labels.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/data_display.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_text_field.dart';
import '../widgets/option_card.dart';
import '../widgets/page_frame.dart';
import '../widgets/progress_feedback.dart';

/// Most transactions one run may send.
const int simulatorMaxCount = 50;

/// Parses the "Cantidad" field; null when it is not a number in 1..50.
int? parseSimulatorCount(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value < 1 || value > simulatorMaxCount) return null;
  return value;
}

/// Simulator (admin only). The host owns the run: events, progress and timer.
class SimulatorPage extends StatefulWidget {
  const SimulatorPage({
    super.key,
    required this.scenarioCode,
    required this.customer,
    required this.countText,
    required this.running,
    required this.runNumber,
    required this.total,
    required this.events,
    required this.onScenarioChanged,
    required this.onCustomerChanged,
    required this.onCountChanged,
    required this.onStart,
    required this.onStop,
  });

  final String scenarioCode;
  final String customer;
  final String countText;
  final bool running;

  /// Number of the last run; 0 when nothing has run yet.
  final int runNumber;

  /// Transactions the current (or last) run sends.
  final int total;

  /// Decisions received so far, oldest first.
  final List<SimEvent> events;
  final ValueChanged<String> onScenarioChanged;
  final ValueChanged<String> onCustomerChanged;
  final ValueChanged<String> onCountChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
  late final TextEditingController _customer = TextEditingController(
    text: widget.customer,
  );
  late final TextEditingController _count = TextEditingController(
    text: widget.countText,
  );

  @override
  void dispose() {
    _customer.dispose();
    _count.dispose();
    super.dispose();
  }

  int _countOf(Verdict verdict) =>
      widget.events.where((e) => e.verdict == verdict).length;

  String _p95() {
    if (widget.events.isEmpty) return '—';
    final latencies = widget.events.map((e) => e.latencyMs).toList()..sort();
    final index = (latencies.length * 0.95).ceil() - 1;
    return '${latencies[index]} ms';
  }

  @override
  Widget build(BuildContext context) {
    final scenario = simScenarios.firstWhere(
      (s) => s.code == widget.scenarioCode,
    );
    final count = parseSimulatorCount(widget.countText);
    final canStart =
        !widget.running && widget.customer.trim().isNotEmpty && count != null;
    return PageFrame(
      title: 'Simulador',
      subtitle:
          'Crea transacciones de prueba para ver cómo responde el sistema',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 420,
            child: MsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Escenario', style: MsText.heading),
                  const SizedBox(height: MsSpace.lg),
                  Wrap(
                    spacing: MsSpace.sm,
                    runSpacing: MsSpace.sm,
                    children: [
                      for (final s in simScenarios)
                        SizedBox(
                          width: 178,
                          child: OptionCard(
                            title: s.title,
                            code: s.subtitle,
                            selected: s.code == widget.scenarioCode,
                            onTap: widget.running
                                ? null
                                : () => widget.onScenarioChanged(s.code),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: MsSpace.lg),
                  Text(scenario.description, style: MsText.caption),
                  const SizedBox(height: MsSpace.lg),
                  MsTextField(
                    label: 'Cliente',
                    controller: _customer,
                    hint: 'Nombre del cliente de prueba',
                    enabled: !widget.running,
                    onChanged: widget.onCustomerChanged,
                  ),
                  const SizedBox(height: MsSpace.lg),
                  MsTextField(
                    label: 'Cantidad (máximo $simulatorMaxCount)',
                    controller: _count,
                    enabled: !widget.running,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: count == null && widget.countText.isNotEmpty
                        ? 'Escribe un número entre 1 y $simulatorMaxCount'
                        : null,
                    onChanged: widget.onCountChanged,
                  ),
                  const SizedBox(height: MsSpace.lg),
                  if (widget.running)
                    MsButton(
                      label: 'Detener simulación',
                      variant: MsButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: widget.onStop,
                    )
                  else
                    MsButton(
                      label: 'Iniciar simulación',
                      fullWidth: true,
                      onPressed: canStart ? widget.onStart : null,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          Expanded(child: _liveResults()),
        ],
      ),
    );
  }

  Widget _liveResults() {
    final sent = widget.events.length;
    final hasRun = widget.runNumber > 0;
    final String title;
    final String progressText;
    if (widget.running) {
      title = 'En vivo · ejecución #${widget.runNumber}';
      progressText = '$sent / ${widget.total} enviadas';
    } else if (hasRun) {
      title = 'Ejecución #${widget.runNumber} terminada';
      progressText = '$sent / ${widget.total} enviadas';
    } else {
      title = 'Resultados en vivo';
      progressText = 'Sin ejecutar';
    }
    final fraction = widget.total == 0
        ? 0.0
        : (sent / widget.total).clamp(0.0, 1.0);
    final newestFirst = widget.events.reversed.take(8).toList();

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.running) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MsColors.approve,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: MsSpace.sm),
              ],
              Expanded(child: Text(title, style: MsText.heading)),
              Text(progressText, style: MsText.caption),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(MsRadius.full),
            child: Container(
              height: 4,
              color: MsColors.bgSubtle,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 4, color: MsColors.bgInverse),
              ),
            ),
          ),
          const SizedBox(height: MsSpace.lg),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Aprobadas',
                  value: '${_countOf(Verdict.approve)}',
                  valueColor: MsColors.approve,
                ),
              ),
              const SizedBox(width: MsSpace.md),
              Expanded(
                child: StatTile(
                  label: 'En revisión',
                  value: '${_countOf(Verdict.review)}',
                  valueColor: MsColors.review,
                ),
              ),
              const SizedBox(width: MsSpace.md),
              Expanded(
                child: StatTile(
                  label: 'Bloqueadas',
                  value: '${_countOf(Verdict.block)}',
                  valueColor: MsColors.block,
                ),
              ),
              const SizedBox(width: MsSpace.md),
              Expanded(
                child: StatTile(label: 'Latencia p95', value: _p95()),
              ),
            ],
          ),
          const SizedBox(height: MsSpace.lg),
          if (widget.events.isEmpty)
            const SizedBox(
              height: 220,
              child: EmptyState(
                title: 'Todavía no hay transacciones',
                hint: 'Elige un escenario y presiona Iniciar simulación.',
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.only(bottom: MsSpace.sm),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MsColors.borderDefault),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 64, child: Text('Hora', style: MsText.label)),
                  SizedBox(width: MsSpace.md),
                  SizedBox(
                    width: 130,
                    child: Text('Cliente', style: MsText.label),
                  ),
                  SizedBox(width: MsSpace.md),
                  SizedBox(width: 84, child: Text('Tipo', style: MsText.label)),
                  SizedBox(width: MsSpace.md),
                  SizedBox(
                    width: 104,
                    child: Text('Monto', style: MsText.label),
                  ),
                  Spacer(),
                  Text('Decisión', style: MsText.label),
                ],
              ),
            ),
            for (final e in newestFirst)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: MsColors.borderDefault),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        e.time,
                        style: MsText.caption.copyWith(
                          color: MsColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: MsSpace.md),
                    SizedBox(
                      width: 130,
                      child: Text(
                        e.customer,
                        overflow: TextOverflow.ellipsis,
                        style: MsText.bodyStrong,
                      ),
                    ),
                    const SizedBox(width: MsSpace.md),
                    SizedBox(
                      width: 84,
                      child: Text(
                        e.type,
                        overflow: TextOverflow.ellipsis,
                        style: MsText.caption.copyWith(
                          color: e.type == 'Transferencia'
                              ? MsColors.block
                              : MsColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: MsSpace.md),
                    SizedBox(
                      width: 104,
                      child: Text(formatCop(e.amount), style: MsText.body),
                    ),
                    const Spacer(),
                    Text(
                      '${e.latencyMs} ms',
                      style: MsText.caption.copyWith(
                        color: MsColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: MsSpace.md),
                    VerdictBadge(verdict: e.verdict),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
