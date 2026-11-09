import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/cases/case_detail_screen.dart';
import 'package:monedasegura_app/screens/cases/case_queue_page.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';

Future<AppStore> _pumpQueue(WidgetTester tester) =>
    pumpApp(tester, signInAs: _valentina, initialRoute: '/cases');

Finder get _rows => find.byType(CaseRow);

Finder _inRow(Finder row, String text) =>
    find.descendant(of: row, matching: find.text(text));

List<String> _shownIds(WidgetTester tester) => [
  for (final row in tester.widgetList<CaseRow>(_rows)) row.caseView.shortId,
];

CaseView _byShortId(AppStore store, String shortId) =>
    store.openCases.firstWhere((c) => c.shortId == shortId);

/// Scrolls [finder] into view, taps it and settles.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  testWidgets('shows the title, tabs, headers, summary and 9 rows', (
    tester,
  ) async {
    await _pumpQueue(tester);

    final topBar = tester.widget<TopBar>(find.byType(TopBar));
    expect(topBar.title, 'Cola de casos');
    expect(
      topBar.subtitle,
      'Transacciones marcadas para revisión · 9 abiertas',
    );
    for (final text in [
      'Todos · 9',
      'Sin asignar · 7',
      'Asignados a mí · 1',
      'Resueltos hoy · 3',
      'ID',
      'Cliente',
      'Monto',
      'Tipo',
      'Score',
      'Veredicto',
      'Antigüedad',
      'Mostrando 9 de 9 · ordenados por riesgo',
      'Veredicto: todos',
      'Score ≥ 0,60',
      'Filtros',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(_rows, findsNWidgets(9));
  });

  testWidgets('the first and last rows follow the queue order', (tester) async {
    await _pumpQueue(tester);

    final first = _rows.first;
    for (final text in [
      '#A17D3C',
      'Tomás H.',
      r'$ 15.000.000',
      '0,97',
      'Bloqueada',
    ]) {
      expect(_inRow(first, text), findsOneWidget, reason: text);
    }
    final last = _rows.last;
    expect(_inRow(last, '#09F35B'), findsOneWidget);
    expect(_inRow(last, '—'), findsOneWidget);
  });

  testWidgets('the tabs switch the listed cases', (tester) async {
    final store = await _pumpQueue(tester);

    await _tap(tester, find.text('Asignados a mí · 1'));
    expect(_shownIds(tester), ['#C66A2F']);

    await _tap(tester, find.text('Resueltos hoy · 3'));
    expect(_shownIds(tester), [for (final c in store.resolvedToday) c.shortId]);
    expect(_rows, findsNWidgets(3));
  });

  testWidgets('the verdict menu filters and resets', (tester) async {
    await _pumpQueue(tester);

    await _tap(tester, find.text('Veredicto: todos'));
    await _tap(tester, find.text('Bloqueadas'));
    expect(_rows, findsNWidgets(3));
    for (final row in tester.widgetList<CaseRow>(_rows)) {
      expect(row.caseView.verdict, Verdict.BLOCK);
    }
    expect(
      find.descendant(of: _rows, matching: find.text('Bloqueada')),
      findsNWidgets(3),
    );
    expect(find.text('Veredicto: bloqueadas'), findsOneWidget);
    expect(
      find.text('Mostrando 3 de 3 · ordenados por riesgo'),
      findsOneWidget,
    );

    await _tap(tester, find.text('Veredicto: bloqueadas'));
    await _tap(tester, find.text('Todos'));
    expect(_rows, findsNWidgets(9));
    expect(find.text('Veredicto: todos'), findsOneWidget);
  });

  testWidgets('tapping a row opens its case detail', (tester) async {
    final store = await _pumpQueue(tester);
    final target = _byShortId(store, '#B204E7');

    await _tap(tester, find.text('#B204E7'));

    final detail = tester.widget<CaseDetailScreen>(
      find.byType(CaseDetailScreen),
    );
    expect(detail.caseId, target.id);
  });

  testWidgets('resolving a case elsewhere updates the mounted queue', (
    tester,
  ) async {
    final store = await _pumpQueue(tester);
    final target = _byShortId(store, '#B204E7');

    store.takeCase(target.id);
    store.resolveCase(target.id, CaseLabel.CONFIRMED_FRAUD);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TopBar>(find.byType(TopBar)).subtitle,
      'Transacciones marcadas para revisión · 8 abiertas',
    );
    expect(find.text('Todos · 8'), findsOneWidget);
    expect(find.text('Resueltos hoy · 4'), findsOneWidget);
  });

  testWidgets('pagination is disabled with 9 rows', (tester) async {
    await _pumpQueue(tester);
    expect(_button(tester, 'Anterior').onPressed, isNull);
    expect(_button(tester, 'Siguiente').onPressed, isNull);
    expect(_button(tester, 'Filtros').onPressed, isNotNull);
  });

  group('CaseQueuePage alone', () {
    final store = AppStore.seeded(clock: () => kTestNow);
    final rows = store.openCases.take(3).toList();

    Future<List<Object?>> pumpPage(
      WidgetTester tester, {
      List<CaseView>? pageRows,
      bool hasNext = false,
    }) async {
      final calls = <Object?>[];
      await setDesktopView(tester);
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: CaseQueuePage(
              tabLabels: const ['A · 1', 'B · 2', 'C · 3', 'D · 4'],
              tab: 0,
              rows: pageRows ?? rows,
              shownCount: (pageRows ?? rows).length,
              totalCount: (pageRows ?? rows).length,
              verdictFilter: null,
              hasPrevious: false,
              hasNext: hasNext,
              now: kTestNow,
              onTabSelected: (i) => calls.add(('tab', i)),
              onVerdictFilter: (v) => calls.add(('verdict', v)),
              onPrevious: () => calls.add('previous'),
              onNext: () => calls.add('next'),
              onOpenCase: (c) => calls.add(('open', c)),
            ),
          ),
        ),
      );
      return calls;
    }

    testWidgets('tapping a row calls onOpenCase with it', (tester) async {
      final calls = await pumpPage(tester);
      await _tap(tester, find.text(rows[1].shortId));
      expect(calls, [('open', rows[1])]);
    });

    testWidgets('tapping a tab calls onTabSelected with its index', (
      tester,
    ) async {
      final calls = await pumpPage(tester);
      await _tap(tester, find.text('C · 3'));
      expect(calls, [('tab', 2)]);
    });

    testWidgets('Siguiente calls onNext when there is a next page', (
      tester,
    ) async {
      final calls = await pumpPage(tester, hasNext: true);
      await _tap(tester, find.text('Siguiente'));
      expect(calls, ['next']);
    });

    testWidgets('choosing Todos calls onVerdictFilter with null', (
      tester,
    ) async {
      final calls = await pumpPage(tester);
      await _tap(tester, find.text('Veredicto: todos'));
      await _tap(tester, find.text('Todos'));
      expect(calls, [('verdict', null)]);
    });

    testWidgets('empty rows show the empty state', (tester) async {
      await pumpPage(tester, pageRows: const []);
      expect(find.text('No hay casos en esta vista'), findsOneWidget);
      expect(
        find.text(
          'Los casos nuevos aparecen aquí apenas el sistema los marca.',
        ),
        findsOneWidget,
      );
      expect(_rows, findsNothing);
    });
  });
}
