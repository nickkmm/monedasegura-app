import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/cases/case_detail_screen.dart';
import 'package:monedasegura_app/screens/dashboard/dashboard_page.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';

final _seed = MockSeed.build(kTestNow);

DashboardMetrics _fakeMetrics({int latencyP95 = 120}) => DashboardMetrics(
  from: kTestNow.subtract(const Duration(hours: 24)),
  to: kTestNow,
  decisions: 1000,
  verdicts: const {Verdict.APPROVE: 950, Verdict.REVIEW: 40, Verdict.BLOCK: 10},
  latencyP50: 50,
  latencyP95: latencyP95,
  latencyP99: 700,
  degradedRate: 0.002,
  openCases: 2,
  alerts: const [],
  previousDecisions: 900,
  hourly: List.generate(
    24,
    (i) => HourBucket(approve: 40 + i, review: 2, block: i % 3),
  ),
);

class _Calls {
  int queue = 0;
  int models = 0;
  final List<CaseView> cases = [];
}

Future<_Calls> _pumpPage(
  WidgetTester tester, {
  DashboardMetrics? metrics,
  ModelVersion? activeModel,
  bool withModel = true,
  List<CaseView>? recentCases,
  bool canOpenModels = true,
}) async {
  await setDesktopView(tester);
  final calls = _Calls();
  await tester.pumpWidget(
    harness(
      SingleChildScrollView(
        child: SizedBox(
          width: 1200,
          child: DashboardPage(
            metrics: metrics ?? _fakeMetrics(),
            openCases: 2,
            unassignedCases: 1,
            activeModel: withModel
                ? activeModel ??
                      _seed.models.firstWhere(
                        (m) => m.status == ModelStatus.ACTIVE,
                      )
                : null,
            recentCases: recentCases ?? [_seed.cases.first],
            now: kTestNow,
            canOpenModels: canOpenModels,
            onOpenQueue: () => calls.queue++,
            onOpenCase: calls.cases.add,
            onOpenModels: () => calls.models++,
          ),
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  testWidgets('shows the subtitle and the KPIs from the store', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    // "Dashboard" is also the sidebar entry.
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Hoy · actualizado hace 12 s'), findsOneWidget);
    // Some KPI texts also appear in the legend and the case rows' badges.
    for (final text in [
      'Transacciones hoy',
      '12.480',
      '+8,2 % vs. ayer',
      'Bloqueadas',
      '37',
      '0,30 % del total',
      'En revisión',
      '9',
      '7 sin asignar',
      'Latencia p95',
      '182 ms',
      'Objetivo < 500 ms',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
      expect(
        find.descendant(of: find.byType(KpiCard), matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
  });

  testWidgets('renders the decisions chart with 24 columns', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    for (final text in [
      'Decisiones por hora',
      'Últimas 24 horas',
      'Aprobadas',
      'Revisión',
      '00:00',
      '06:00',
      '12:00',
      '18:00',
      '23:00',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      find.descendant(
        of: find.byType(LegendItem),
        matching: find.text('Bloqueadas'),
      ),
      findsOneWidget,
    );
    for (var i = 0; i < 24; i++) {
      expect(find.byKey(Key('hour-column-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('hour-column-24')), findsNothing);
  });

  testWidgets('shows the active model and opens the models screen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    for (final text in [
      'Modelo activo',
      'v5',
      '0,81',
      '0,74',
      'hoy 02:00 · automático',
      '3 decisiones degradadas hoy (solo reglas)',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await tester.tap(find.text('Modelo activo'));
    await tester.pumpAndSettle();
    expect(tester.widget<TopBar>(find.byType(TopBar)).title, 'Modelos');
  });

  testWidgets('lists the recent cases and opens a case', (tester) async {
    final store = await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    expect(find.text('Casos recientes'), findsOneWidget);
    final ys = [
      for (final id in ['#7F0B6A', '#3A91C2', '#B204E7'])
        tester.getTopLeft(find.text(id)).dy,
    ];
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));

    final target = store.recentCases.firstWhere((c) => c.shortId == '#B204E7');
    await tester.tap(find.text('#B204E7'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(CaseDetailScreen)))!;
    expect(route.settings.name, AppRoutes.caseDetail(target.id));
  });

  testWidgets('"Ver la cola" opens the case queue', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    await tester.tap(find.text('Ver la cola'));
    await tester.pumpAndSettle();
    expect(tester.widget<TopBar>(find.byType(TopBar)).title, 'Cola de casos');
  });

  testWidgets('the open-case KPI follows the store', (tester) async {
    final store = await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.dashboard,
    );
    final reviewKpi = find.ancestor(
      of: find.text('En revisión'),
      matching: find.byType(KpiCard),
    );
    expect(tester.widget<KpiCard>(reviewKpi).value, '9');

    final open = store.recentCases.firstWhere(
      (c) => c.status == CaseStatus.OPEN,
    );
    store.takeCase(open.id);
    store.resolveCase(open.id, CaseLabel.DISMISSED);
    await tester.pump();
    expect(tester.widget<KpiCard>(reviewKpi).value, '8');
  });

  testWidgets('the page reports taps through its callbacks', (tester) async {
    final calls = await _pumpPage(tester);

    await tester.tap(find.text('Ver la cola'));
    expect(calls.queue, 1);

    await tester.tap(find.byType(CaseRow));
    expect(calls.cases, [_seed.cases.first]);

    await tester.tap(find.text('Modelo activo'));
    expect(calls.models, 1);
  });

  testWidgets('the model card is not tappable without permission', (
    tester,
  ) async {
    final calls = await _pumpPage(tester, canOpenModels: false);
    await tester.tap(find.text('Modelo activo'));
    expect(calls.models, 0);
  });

  testWidgets('shows the empty states', (tester) async {
    await _pumpPage(tester, withModel: false, recentCases: const []);
    expect(find.text('Sin modelo activo'), findsOneWidget);
    expect(find.text('—'), findsAtLeastNWidgets(3));
    expect(find.text('No hay casos abiertos'), findsOneWidget);
    expect(
      find.text('Los casos nuevos aparecen aquí apenas el sistema los marca.'),
      findsOneWidget,
    );
    expect(find.byType(CaseRow), findsNothing);
  });

  testWidgets('a slow p95 shows the target in the block color', (tester) async {
    await _pumpPage(tester, metrics: _fakeMetrics(latencyP95: 600));
    expect(find.text('600 ms'), findsOneWidget);
    final target = tester.widget<Text>(find.text('Objetivo < 500 ms'));
    expect(target.style!.color, AppColors.statusBlock);
  });
}
