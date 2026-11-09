import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// Where a simulation run is.
enum RunState { idle, running, finished, stopped }

/// The simulator content: the configuration card and the live results card.
/// Shows only what it is given and reports every interaction up.
class SimulatorPage extends StatelessWidget {
  const SimulatorPage({
    super.key,
    required this.scenario,
    required this.customerId,
    required this.customers,
    required this.countController,
    required this.countError,
    required this.runNumber,
    required this.runTotal,
    required this.events,
    required this.state,
    required this.onScenario,
    required this.onCustomer,
    required this.onStart,
    required this.onStop,
  });

  final Scenario scenario;
  final String? customerId;
  final List<Customer> customers;
  final TextEditingController countController;
  final String? countError;

  /// Null until the first run starts.
  final int? runNumber;

  /// The total stored when the run started, not the count field's live text.
  final int runTotal;

  /// Newest first.
  final List<SimulationEvent> events;
  final RunState state;
  final ValueChanged<Scenario> onScenario;
  final ValueChanged<String> onCustomer;
  final VoidCallback onStart;
  final VoidCallback onStop;

  static const double _configWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _configWidth,
          child: _ConfigCard(
            scenario: scenario,
            customerId: customerId,
            customers: customers,
            countController: countController,
            countError: countError,
            running: state == RunState.running,
            onScenario: onScenario,
            onCustomer: onCustomer,
            onStart: onStart,
            onStop: onStop,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _ResultsCard(
            runNumber: runNumber,
            runTotal: runTotal,
            events: events,
            state: state,
          ),
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.scenario,
    required this.customerId,
    required this.customers,
    required this.countController,
    required this.countError,
    required this.running,
    required this.onScenario,
    required this.onCustomer,
    required this.onStart,
    required this.onStop,
  });

  final Scenario scenario;
  final String? customerId;
  final List<Customer> customers;
  final TextEditingController countController;
  final String? countError;
  final bool running;
  final ValueChanged<Scenario> onScenario;
  final ValueChanged<String> onCustomer;
  final VoidCallback onStart;
  final VoidCallback onStop;

  Widget _option(Scenario option) {
    return Expanded(
      child: OptionCard(
        title: option.label,
        subtitle: option.hint,
        selected: option == scenario,
        onTap: running ? null : () => onScenario(option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escenario',
            style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _option(Scenario.NORMAL),
              const SizedBox(width: AppSpacing.sm),
              _option(Scenario.CARD_FRAUD),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _option(Scenario.ATO),
              const SizedBox(width: AppSpacing.sm),
              _option(Scenario.ORIGINATION),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            scenario.description,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CustomerField(
            customers: customers,
            customerId: customerId,
            createsCustomer: scenario == Scenario.ORIGINATION,
            running: running,
            onCustomer: onCustomer,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Cantidad (máximo 50)',
            hintText: '20 transacciones',
            controller: countController,
            keyboardType: TextInputType.number,
            errorText: countError,
            enabled: !running,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (running)
            AppButton(
              label: 'Detener simulación',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: onStop,
            )
          else
            AppButton(
              label: 'Iniciar simulación',
              expand: true,
              onPressed: onStart,
            ),
        ],
      ),
    );
  }
}

/// The read-only customer field and its menu. Owns the controller that
/// displays the selection, because [AppTextField] shows text only through one.
class _CustomerField extends StatefulWidget {
  const _CustomerField({
    required this.customers,
    required this.customerId,
    required this.createsCustomer,
    required this.running,
    required this.onCustomer,
  });

  final List<Customer> customers;
  final String? customerId;

  /// True for Originación, where the run creates the customer.
  final bool createsCustomer;
  final bool running;
  final ValueChanged<String> onCustomer;

  @override
  State<_CustomerField> createState() => _CustomerFieldState();
}

class _CustomerFieldState extends State<_CustomerField> {
  late final TextEditingController _display = TextEditingController(
    text: _text,
  );

  String _option(Customer customer) {
    final document = customer.maskedDocument;
    return '${customer.maskedName} · documento '
        '••••${document.substring(document.length - 4)}';
  }

  String get _text {
    if (widget.createsCustomer) return 'Se crea un cliente nuevo';
    for (final customer in widget.customers) {
      if (customer.id == widget.customerId) return _option(customer);
    }
    return '';
  }

  @override
  void didUpdateWidget(_CustomerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _text;
    if (_display.text != text) _display.text = text;
  }

  @override
  void dispose() {
    _display.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final customer in widget.customers)
          MenuItemButton(
            onPressed: () => widget.onCustomer(customer.id),
            child: Text(_option(customer)),
          ),
      ],
      builder: (context, controller, _) => AppTextField(
        label: 'Cliente',
        controller: _display,
        readOnly: true,
        enabled: !widget.createsCustomer && !widget.running,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.runNumber,
    required this.runTotal,
    required this.events,
    required this.state,
  });

  final int? runNumber;
  final int runTotal;
  final List<SimulationEvent> events;
  final RunState state;

  static const double _minHeight = 795;

  int _count(Verdict verdict) =>
      events.where((event) => event.decision.verdict == verdict).length;

  /// The nearest-rank 95th percentile, with integers to avoid float rounding.
  String get _p95 {
    if (events.isEmpty) return '—';
    final latencies = [for (final event in events) event.decision.latencyMs]
      ..sort();
    final rank = (latencies.length * 95 + 99) ~/ 100;
    return '${latencies[rank - 1]} ms';
  }

  Widget _tile(String label, String value, Color color) {
    return Expanded(
      child: StatTile(label: label, value: value, valueColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = <Widget>[
      _ResultsHeader(
        runNumber: runNumber,
        runTotal: runTotal,
        sent: events.length,
        state: state,
      ),
      const SizedBox(height: AppSpacing.md),
      _ProgressBar(
        fraction: state == RunState.idle ? 0 : events.length / runTotal,
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        children: [
          _tile(
            'Aprobadas',
            '${_count(Verdict.APPROVE)}',
            AppColors.statusApprove,
          ),
          const SizedBox(width: AppSpacing.md),
          _tile(
            'En revisión',
            '${_count(Verdict.REVIEW)}',
            AppColors.statusReview,
          ),
          const SizedBox(width: AppSpacing.md),
          _tile(
            'Bloqueadas',
            '${_count(Verdict.BLOCK)}',
            AppColors.statusBlock,
          ),
          const SizedBox(width: AppSpacing.md),
          _tile('Latencia p95', _p95, AppColors.textPrimary),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    if (state == RunState.idle) {
      // A fixed height gives the empty state space to center in, under the
      // shell's unbounded height.
      return SizedBox(
        height: _minHeight,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...summary,
              const Expanded(
                child: Center(
                  child: EmptyState(
                    icon: AppIcons.play,
                    title: 'Todavía no hay transacciones',
                    hint: 'Elige un escenario y presiona Iniciar simulación.',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...summary,
            _Feed(events: events),
          ],
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.runNumber,
    required this.runTotal,
    required this.sent,
    required this.state,
  });

  final int? runNumber;
  final int runTotal;
  final int sent;
  final RunState state;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      RunState.idle => 'Resultados en vivo',
      RunState.running => 'En vivo · ejecución #$runNumber',
      RunState.finished => 'Ejecución #$runNumber · terminada',
      RunState.stopped => 'Ejecución #$runNumber · detenida',
    };
    return Row(
      children: [
        if (state == RunState.running) ...[
          Container(
            width: _dot,
            height: _dot,
            decoration: const BoxDecoration(
              color: AppColors.statusBlock,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          state == RunState.idle
              ? 'Sin ejecutar'
              : '$sent / $runTotal enviadas',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgInverse,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

/// The feed: a header row and one row per event. Keeps its fixed columns and
/// scrolls sideways when the card is narrower than they need.
class _Feed extends StatelessWidget {
  const _Feed({required this.events});

  final List<SimulationEvent> events;

  static const double _minWidth = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(constraints.maxWidth, _minWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FeedHeader(),
              for (final event in events) _FeedRow(event: event),
            ],
          ),
        ),
      ),
    );
  }
}

const double _timeWidth = 64;
const double _customerWidth = 130;
const double _typeWidth = 84;
const double _amountWidth = 104;

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  Widget _cell(String label, TextStyle style, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.label.copyWith(color: AppColors.textTertiary);
    return Row(
      children: [
        _cell('Hora', style, _timeWidth),
        const SizedBox(width: AppSpacing.md),
        _cell('Cliente', style, _customerWidth),
        const SizedBox(width: AppSpacing.md),
        _cell('Tipo', style, _typeWidth),
        const SizedBox(width: AppSpacing.md),
        _cell('Monto', style, _amountWidth),
        const Spacer(),
        Text('Decisión', style: style),
      ],
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.event});

  final SimulationEvent event;

  static const double _verticalPadding = 9;

  Widget _cell(String text, TextStyle style, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = event.transaction;
    final decision = event.decision;
    final flagged = decision.verdict != Verdict.APPROVE;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          _cell(
            formatHms(transaction.occurredAt),
            AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            _timeWidth,
          ),
          const SizedBox(width: AppSpacing.md),
          _cell(
            event.customer.maskedName,
            AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
            _customerWidth,
          ),
          const SizedBox(width: AppSpacing.md),
          _cell(
            transaction.type.label,
            AppTextStyles.caption.copyWith(
              color: flagged ? AppColors.statusBlock : AppColors.textSecondary,
            ),
            _typeWidth,
          ),
          const SizedBox(width: AppSpacing.md),
          _cell(
            formatCop(transaction.amount),
            AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            _amountWidth,
          ),
          const Spacer(),
          Text(
            '${decision.latencyMs} ms',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          VerdictBadge(verdict: decision.verdict),
        ],
      ),
    );
  }
}
