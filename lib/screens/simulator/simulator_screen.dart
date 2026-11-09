import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../data/models/models.dart';
import '../../widgets/widgets.dart';
import 'simulator_page.dart';

/// The simulator: owns the configuration and the current run, sending one
/// transaction per timer tick and showing each decision as it arrives.
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  static const Duration _tick = Duration(milliseconds: 400);
  static const int _maxCount = 50;

  final TextEditingController _countController = TextEditingController(
    text: '20',
  );

  Scenario _scenario = Scenario.ATO;
  late String _customerId;
  String? _countError;
  int? _runNumber;
  int _runTotal = 0;
  List<SimulationEvent> _events = const [];
  RunState _state = RunState.idle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _customerId = AppScope.read(context).customers
        .firstWhere((c) => c.maskedName == 'Sofía V.')
        .id;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countController.dispose();
    super.dispose();
  }

  void _start() {
    final count = int.tryParse(_countController.text.trim());
    if (count == null || count < 1 || count > _maxCount) {
      setState(() => _countError = 'Escribe un número entre 1 y 50.');
      return;
    }
    final store = AppScope.read(context);
    setState(() {
      _countError = null;
      _events = const [];
      _runTotal = count;
      _state = RunState.running;
      _runNumber = store.startRun();
      if (_scenario == Scenario.ORIGINATION) {
        _customerId = store.createOriginationCustomer().id;
      }
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    final store = AppScope.read(context);
    // Signing out clears the user before the route changes.
    if (!store.can(PermissionCode.SIMULATOR_RUN)) {
      _timer?.cancel();
      return;
    }
    final event = store.simulateOne(
      scenario: _scenario,
      customerId: _customerId,
      runNumber: _runNumber!,
      index: _events.length,
    );
    setState(() {
      _events = [event, ..._events];
      if (_events.length == _runTotal) {
        _timer?.cancel();
        _state = RunState.finished;
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _state = RunState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppShell(
      active: NavDestination.simulator,
      title: 'Simulador',
      subtitle:
          'Crea transacciones de prueba para ver cómo responde el sistema',
      child: SimulatorPage(
        scenario: _scenario,
        customerId: _customerId,
        customers: store.customers,
        countController: _countController,
        countError: _countError,
        runNumber: _runNumber,
        runTotal: _runTotal,
        events: _events,
        state: _state,
        onScenario: (scenario) => setState(() => _scenario = scenario),
        onCustomer: (id) => setState(() => _customerId = id),
        onStart: _start,
        onStop: _stop,
      ),
    );
  }
}
