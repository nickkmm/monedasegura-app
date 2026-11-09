import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/simulator/simulator_page.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';

const _start = 'Iniciar simulación';
const _stop = 'Detener simulación';
const _countLabel = 'Cantidad (máximo 50)';
const _countError = 'Escribe un número entre 1 y 50.';

const _tick = Duration(milliseconds: 400);

Future<AppStore> _pumpScreen(WidgetTester tester) =>
    pumpApp(tester, signInAs: _valentina, initialRoute: '/simulator');

Future<void> _ticks(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(_tick);
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
}

/// Stops a run, so the test ends with no pending timer.
Future<void> _stopRun(WidgetTester tester) => _tapText(tester, _stop);

AppTextField _field(WidgetTester tester, String label) =>
    tester.widget<AppTextField>(find.widgetWithText(AppTextField, label));

Future<void> _enterCount(WidgetTester tester, String text) => tester.enterText(
  find.descendant(
    of: find.widgetWithText(AppTextField, _countLabel),
    matching: find.byType(TextField),
  ),
  text,
);

SimulatorPage _page(WidgetTester tester) =>
    tester.widget<SimulatorPage>(find.byType(SimulatorPage));

int _tileValue(WidgetTester tester, String label) => int.parse(
  tester.widget<StatTile>(find.widgetWithText(StatTile, label)).value,
);

SimulationEvent _event(
  int number, {
  Verdict verdict = Verdict.APPROVE,
  int latencyMs = 100,
  TransactionType type = TransactionType.DEBIT,
  String name = 'Ana P.',
}) {
  final at = DateTime(2026, 10, 25, 9, 45, number % 60);
  return SimulationEvent(
    transaction: Transaction(
      id: 'tx-$number',
      customerId: 'c-1',
      deviceId: 'd-1',
      type: type,
      amount: 120000,
      latitude: 4.6,
      longitude: -74.1,
      source: TransactionSource.SIMULATOR,
      occurredAt: at,
    ),
    decision: Decision(
      id: 'dec-$number',
      transactionId: 'tx-$number',
      kind: DecisionKind.ORIGINAL,
      verdict: verdict,
      degraded: false,
      features: const {},
      ruleHits: const [],
      latencyMs: latencyMs,
      decidedAt: at,
    ),
    customer: Customer(
      id: 'c-1',
      maskedName: name,
      maskedDocument: '****1234',
      homeCity: 'Bogotá',
      createdAt: at,
      transactions30d: 0,
      previousFrauds: 0,
    ),
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  RunState state = RunState.finished,
  List<SimulationEvent> events = const [],
  VoidCallback? onStart,
  VoidCallback? onStop,
}) async {
  await setDesktopView(tester);
  final controller = TextEditingController(text: '20');
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    harness(
      SingleChildScrollView(
        child: SizedBox(
          width: 1136,
          child: SimulatorPage(
            scenario: Scenario.ATO,
            customerId: 'c-1',
            customers: [_event(1).customer],
            countController: controller,
            countError: null,
            runNumber: 18,
            runTotal: 20,
            events: events,
            state: state,
            onScenario: (_) {},
            onCustomer: (_) {},
            onStart: onStart ?? () {},
            onStop: onStop ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadInterFont);

  testWidgets('shows the idle screen', (tester) async {
    await _pumpScreen(tester);

    // "Simulador" is also the sidebar entry.
    expect(find.text('Simulador'), findsWidgets);
    for (final text in [
      'Crea transacciones de prueba para ver cómo responde el sistema',
      'Escenario',
      'Normal',
      'Hábitos normales',
      'Fraude con tarjeta',
      'Compras de noche',
      'Toma de cuenta',
      'Clave y equipo nuevos',
      'Originación',
      'Cliente recién creado',
      'Inicios fallidos, cambio de clave y un dispositivo nuevo; después, '
          'compras grandes desde otra ciudad.',
      'Cliente',
      'Sofía V. · documento ••••3310',
      _countLabel,
      _start,
      'Resultados en vivo',
      'Sin ejecutar',
      'Aprobadas',
      'En revisión',
      'Bloqueadas',
      'Latencia p95',
      '—',
      'Todavía no hay transacciones',
      'Elige un escenario y presiona Iniciar simulación.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('20'), findsOneWidget);
    expect(find.byType(OptionCard), findsNWidgets(4));
    expect(find.text('Fraude del dataset'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows progress during a run', (tester) async {
    await _pumpScreen(tester);
    await _tapText(tester, _start);
    await _ticks(tester, 14);

    expect(find.text('En vivo · ejecución #18'), findsOneWidget);
    expect(find.text('14 / 20 enviadas'), findsOneWidget);
    expect(find.byType(VerdictBadge), findsNWidgets(14));
    expect(
      _tileValue(tester, 'Aprobadas') +
          _tileValue(tester, 'En revisión') +
          _tileValue(tester, 'Bloqueadas'),
      14,
    );
    expect(find.text(_stop), findsOneWidget);
    expect(find.text(_start), findsNothing);
    await _stopRun(tester);
  });

  testWidgets('a finished run opens a case per flagged decision', (
    tester,
  ) async {
    final store = await _pumpScreen(tester);
    final decisions = store.metrics.decisions;
    final openCases = store.openCaseCount;
    await _tapText(tester, _start);
    await _ticks(tester, 20);

    expect(find.text('Ejecución #18 · terminada'), findsOneWidget);
    expect(find.text('20 / 20 enviadas'), findsOneWidget);
    expect(find.text(_start), findsOneWidget);
    expect(store.metrics.decisions, decisions + 20);

    final flagged = _page(tester).events
        .where((event) => event.decision.verdict != Verdict.APPROVE);
    final openIds = {for (final view in store.openCases) view.fraudCase.id};
    for (final event in flagged) {
      expect(openIds, contains(event.decision.caseId));
    }
    expect(store.openCaseCount, openCases + flagged.length);
  });

  testWidgets('stopping keeps the results and sends nothing more', (
    tester,
  ) async {
    final store = await _pumpScreen(tester);
    await _tapText(tester, _start);
    await _ticks(tester, 5);
    await _stopRun(tester);

    expect(find.text('Ejecución #18 · detenida'), findsOneWidget);
    expect(find.text('5 / 20 enviadas'), findsOneWidget);
    final decisions = store.metrics.decisions;
    await _ticks(tester, 5);
    expect(find.byType(VerdictBadge), findsNWidgets(5));
    expect(store.metrics.decisions, decisions);
  });

  for (final text in ['0', '51', '', 'abc']) {
    testWidgets('rejects the count "$text"', (tester) async {
      final store = await _pumpScreen(tester);
      await _enterCount(tester, text);
      await _tapText(tester, _start);

      expect(find.text(_countError), findsOneWidget);
      expect(store.nextRunNumber, 18);
      expect(find.text('Sin ejecutar'), findsOneWidget);
    });
  }

  testWidgets('an invalid count keeps the previous results', (tester) async {
    final store = await _pumpScreen(tester);
    await _enterCount(tester, '2');
    await _tapText(tester, _start);
    await _ticks(tester, 2);
    await _enterCount(tester, '51');
    await _tapText(tester, _start);

    expect(find.text(_countError), findsOneWidget);
    expect(find.text('Ejecución #18 · terminada'), findsOneWidget);
    expect(find.byType(VerdictBadge), findsNWidgets(2));
    expect(store.nextRunNumber, 19);

    await _enterCount(tester, '1');
    await _tapText(tester, _start);
    expect(find.text(_countError), findsNothing);
    await _ticks(tester, 1);
  });

  testWidgets('Originación creates one customer per run', (tester) async {
    final store = await _pumpScreen(tester);
    final customers = store.customers.length;
    await _tapText(tester, 'Originación');

    expect(find.text('Se crea un cliente nuevo'), findsOneWidget);
    expect(_field(tester, 'Cliente').enabled, isFalse);

    await _enterCount(tester, '3');
    await _tapText(tester, _start);
    await _ticks(tester, 3);

    expect(store.customers.length, customers + 1);
    expect(find.text('Cliente nuevo 18.'), findsNWidgets(3));
    expect(find.text('Se crea un cliente nuevo'), findsOneWidget);
  });

  testWidgets('the guard keeps out a user without SIMULATOR_RUN', (
    tester,
  ) async {
    await pumpApp(tester, signInAs: _camilo, initialRoute: '/simulator');
    expect(
      tester.widget<TopBar>(find.byType(TopBar)).title,
      isNot('Simulador'),
    );
  });

  group('page isolation', () {
    test('only screens reach the store', () {
      final offenders = Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.endsWith('_screen.dart'))
          .where(
            (file) =>
                file.readAsStringSync().contains(RegExp('AppScope|AppStore')),
          )
          .map((file) => file.path);
      expect(offenders, isEmpty);
    });

    testWidgets('reports the start and stop taps', (tester) async {
      var starts = 0;
      var stops = 0;
      await _pumpPage(tester, state: RunState.idle, onStart: () => starts++);
      expect(tester.takeException(), isNull);
      await _tapText(tester, _start);
      expect(starts, 1);

      await _pumpPage(tester, state: RunState.running, onStop: () => stops++);
      expect(tester.takeException(), isNull);
      await _tapText(tester, _stop);
      expect(stops, 1);
    });
  });

  testWidgets('the controls lock during a run', (tester) async {
    await _pumpScreen(tester);
    await _tapText(tester, _start);
    await _ticks(tester, 1);
    await _tapText(tester, 'Normal');

    expect(_page(tester).scenario, Scenario.ATO);
    expect(
      tester
          .widget<OptionCard>(find.widgetWithText(OptionCard, 'Toma de cuenta'))
          .selected,
      isTrue,
    );
    expect(_field(tester, 'Cliente').enabled, isFalse);
    expect(_field(tester, _countLabel).enabled, isFalse);
    await _stopRun(tester);
  });

  testWidgets('choosing a customer from the menu drives the run', (
    tester,
  ) async {
    await _pumpScreen(tester);
    const mariana = 'Mariana G. · documento ••••1907';
    expect(find.text(mariana), findsNothing);
    await tester.tap(find.text('Sofía V. · documento ••••3310'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(mariana));
    await tester.pumpAndSettle();

    expect(find.text(mariana), findsOneWidget);
    expect(find.text('Sofía V. · documento ••••3310'), findsNothing);

    await _enterCount(tester, '2');
    await _tapText(tester, _start);
    await _ticks(tester, 2);
    expect(find.text('Mariana G.'), findsNWidgets(2));
  });

  group('p95', () {
    testWidgets('uses the nearest rank', (tester) async {
      await _pumpPage(
        tester,
        events: [for (var i = 1; i <= 20; i++) _event(i, latencyMs: i)],
      );
      expect(find.text('19 ms'), findsNWidgets(2));
      expect(
        tester
            .widget<StatTile>(find.widgetWithText(StatTile, 'Latencia p95'))
            .value,
        '19 ms',
      );
    });

    testWidgets('reads one event directly', (tester) async {
      await _pumpPage(tester, events: [_event(1, latencyMs: 168)]);
      expect(
        tester
            .widget<StatTile>(find.widgetWithText(StatTile, 'Latencia p95'))
            .value,
        '168 ms',
      );
    });
  });

  testWidgets('a later run keeps its own total', (tester) async {
    await _pumpScreen(tester);
    await _tapText(tester, _start);
    await _ticks(tester, 20);
    await _enterCount(tester, '5');
    await tester.pump();
    expect(find.text('20 / 20 enviadas'), findsOneWidget);

    await _tapText(tester, _start);
    expect(find.text('En vivo · ejecución #19'), findsOneWidget);
    expect(find.byType(VerdictBadge), findsNothing);
    await _ticks(tester, 1);
    expect(find.text('1 / 5 enviadas'), findsOneWidget);
    await _stopRun(tester);
  });

  group('timer lifecycle', () {
    testWidgets('leaving the screen ends the run', (tester) async {
      final store = await _pumpScreen(tester);
      await _tapText(tester, _start);
      await _ticks(tester, 2);
      await tester.tap(find.widgetWithText(NavItem, 'Modelos'));
      await tester.pumpAndSettle();

      expect(tester.widget<TopBar>(find.byType(TopBar)).title, 'Modelos');
      final decisions = store.metrics.decisions;
      await _ticks(tester, 3);
      expect(store.metrics.decisions, decisions);
    });

    testWidgets('signing out during a run does not throw', (tester) async {
      final store = await _pumpScreen(tester);
      await _tapText(tester, _start);
      await _ticks(tester, 2);
      final decisions = store.metrics.decisions;
      store.signOut();
      await tester.pump(_tick);

      expect(tester.takeException(), isNull);
      expect(store.metrics.decisions, decisions);
    });
  });

  testWidgets('a full run does not overflow at the 1280 px layout', (
    tester,
  ) async {
    await _pumpScreen(tester);
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pump();
    await _tapText(tester, _start);
    await _ticks(tester, 20);

    expect(tester.takeException(), isNull);
    expect(find.byType(VerdictBadge), findsNWidgets(20));
    expect(
      tester.widget<VerdictBadge>(find.byType(VerdictBadge).last).verdict,
      _page(tester).events.last.decision.verdict,
    );
  });

  testWidgets('feed rows color the type and keep the given order', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      events: [
        _event(1, name: 'Ana P.', type: TransactionType.DEBIT),
        _event(
          2,
          name: 'Luis R.',
          verdict: Verdict.BLOCK,
          type: TransactionType.TRANSFER,
        ),
      ],
    );

    expect(
      tester.widget<Text>(find.text('Compra')).style?.color,
      AppColors.textSecondary,
    );
    expect(
      tester.widget<Text>(find.text('Transferencia')).style?.color,
      AppColors.statusBlock,
    );
    expect(
      tester.getTopLeft(find.text('Ana P.')).dy,
      lessThan(tester.getTopLeft(find.text('Luis R.')).dy),
    );
  });

  testWidgets('the running header shows the live dot and the progress', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      state: RunState.running,
      events: [for (var i = 1; i <= 5; i++) _event(i)],
    );
    expect(find.text('En vivo · ejecución #18'), findsOneWidget);
    expect(find.text('5 / 20 enviadas'), findsOneWidget);
    final bar = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(bar.widthFactor, 0.25);
  });
}
