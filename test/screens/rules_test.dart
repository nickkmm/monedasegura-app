import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/app_scope.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/rules/rule_editor_screen.dart';
import 'package:monedasegura_app/screens/rules/rules_page.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _laura = 'laura.mendez@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';

const _subtitle = 'Deciden qué transacciones se revisan y cuáles se bloquean';
const _tabs = [
  'Todas · 8',
  'Activas · 4',
  'En shadow · 1',
  'Pendientes · 1',
  'Borradores · 1',
];
const _headers = [
  'Regla',
  'Versión',
  'Acción',
  'Estado',
  'Coinc. 7 d',
  'Precisión',
  'Actualizada',
];
const _emptyTitle = 'No hay reglas en este estado';
const _emptyHint = 'Cambia de pestaña o crea una regla nueva.';

const _nightCondition = Condition('is_night', ConditionOp.eq, true);

Finder _rowOf(String code) =>
    find.ancestor(of: find.text(code), matching: find.byType(RuleRow));

List<String> _visibleCodes(WidgetTester tester) => [
  for (final row in tester.widgetList<RuleRow>(find.byType(RuleRow)))
    row.rule.rule.code,
];

Finder get _legend => find
    .ancestor(of: find.text('Ciclo de vida:'), matching: find.byType(Row))
    .first;

AppStore _store(WidgetTester tester) =>
    AppScope.read(tester.element(find.byType(RulesPage)));

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

String? _editorRouteName(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byType(RuleEditorScreen)))!.settings.name;

String? _editorRuleId(WidgetTester tester) =>
    tester.widget<RuleEditorScreen>(find.byType(RuleEditorScreen)).ruleId;

RuleView _fakeRule(String code) => RuleView(
  rule: Rule(
    id: 'id-$code',
    code: code,
    name: code,
    description: 'Fake rule',
    createdAt: kTestNow,
  ),
  versions: [
    RuleVersion(
      ruleId: 'id-$code',
      version: 1,
      conditions: const [_nightCondition],
      action: RuleAction.REVIEW,
      status: RuleStatus.DRAFT,
      createdBy: const UserRef(id: 'u', fullName: 'Fake User'),
      createdAt: kTestNow,
    ),
  ],
);

Future<void> _pumpPage(
  WidgetTester tester, {
  List<RuleView> rows = const [],
  bool canCreate = true,
  ValueChanged<int>? onTabSelected,
  VoidCallback? onNewRule,
  ValueChanged<RuleView>? onOpenRule,
}) async {
  await setDesktopView(tester);
  await tester.pumpWidget(
    harness(
      RulesPage(
        tabLabels: const ['Uno', 'Dos'],
        tab: 0,
        rows: rows,
        now: kTestNow,
        canCreate: canCreate,
        onTabSelected: onTabSelected ?? (_) {},
        onNewRule: onNewRule ?? () {},
        onOpenRule: onOpenRule ?? (_) {},
      ),
    ),
  );
}

void main() {
  // The "Pendiente" badge overflows its 130 px cell in the default test font.
  setUpAll(loadInterFont);

  group('the list', () {
    testWidgets(
      'shows the frame, the tabs, the headers and the rows in order',
      (tester) async {
        await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');
        expect(
          find.descendant(
            of: find.byType(TopBar),
            matching: find.text('Reglas'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(TopBar),
            matching: find.text(_subtitle),
          ),
          findsOneWidget,
        );
        for (final label in [..._tabs, ..._headers]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }

        const codes = [
          'SCORE_BLOCK',
          'SCORE_REVIEW',
          'HIGH_AMOUNT_NEW_DEVICE',
          'VELOCITY_1H',
          'FAR_FROM_HOME',
          'NIGHT_TRANSFER',
          'ATO_PASSWORD_RESET',
          'VELOCITY_5M',
        ];
        expect(find.byType(RuleRow), findsNWidgets(8));
        expect(_visibleCodes(tester), codes);
        final tops = [
          for (final code in codes) tester.getTopLeft(_rowOf(code)).dy,
        ];
        expect(tops, [...tops]..sort());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('each row shows the values of its latest version', (
      tester,
    ) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');
      const rows = {
        'SCORE_BLOCK': [
          'v2',
          'Bloquear',
          'Activa',
          '312',
          '0,88',
          'hace 9 d · Laura Méndez',
        ],
        'SCORE_REVIEW': [
          'v4',
          'Revisar',
          'Activa',
          '2.410',
          '0,41',
          'hace 3 d · Laura Méndez',
        ],
        'HIGH_AMOUNT_NEW_DEVICE': [
          'v3',
          'Revisar',
          'Activa',
          '486',
          '0,57',
          'hace 12 d · Diego Salazar',
        ],
        'VELOCITY_1H': [
          'v1',
          'Bloquear',
          'Activa',
          '97',
          '0,74',
          'hace 20 d · Diego Salazar',
        ],
        'FAR_FROM_HOME': [
          'v1',
          'Revisar',
          'Shadow',
          '1.102',
          '0,33',
          'ayer · Laura Méndez',
        ],
        'NIGHT_TRANSFER': [
          'v2',
          'Revisar',
          'Pendiente',
          '61',
          '0,52',
          'hoy · Laura Méndez',
        ],
        'ATO_PASSWORD_RESET': [
          'v1',
          'Bloquear',
          'Borrador',
          'hoy · Diego Salazar',
        ],
        'VELOCITY_5M': [
          'v5',
          'Bloquear',
          'Retirada',
          'hace 2 meses · Laura Méndez',
        ],
      };
      for (final MapEntry(key: code, value: values) in rows.entries) {
        for (final value in values) {
          expect(
            find.descendant(of: _rowOf(code), matching: find.text(value)),
            findsOneWidget,
            reason: '$code: $value',
          );
        }
      }
      for (final code in ['ATO_PASSWORD_RESET', 'VELOCITY_5M']) {
        expect(
          find.descendant(of: _rowOf(code), matching: find.text('—')),
          findsNWidgets(2),
          reason: code,
        );
      }
    });

    testWidgets('the tabs filter by the status of the latest version', (
      tester,
    ) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');

      await _tapTab(tester, 'Activas · 4');
      expect(find.byType(RuleRow), findsNWidgets(4));
      expect(_visibleCodes(tester), isNot(contains('NIGHT_TRANSFER')));

      await _tapTab(tester, 'En shadow · 1');
      expect(_visibleCodes(tester), ['FAR_FROM_HOME']);

      await _tapTab(tester, 'Pendientes · 1');
      expect(_visibleCodes(tester), ['NIGHT_TRANSFER']);

      await _tapTab(tester, 'Borradores · 1');
      expect(_visibleCodes(tester), ['ATO_PASSWORD_RESET']);

      await _tapTab(tester, 'Todas · 8');
      expect(find.byType(RuleRow), findsNWidgets(8));
    });

    testWidgets('the legend shows the lifecycle in order', (tester) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');
      expect(find.text('Ciclo de vida:'), findsOneWidget);

      final badges = find.descendant(
        of: _legend,
        matching: find.byType(RuleStatusBadge),
      );
      expect(badges, findsNWidgets(5));
      const labels = ['Borrador', 'Shadow', 'Pendiente', 'Activa', 'Retirada'];
      for (var i = 0; i < labels.length; i++) {
        expect(
          find.descendant(of: badges.at(i), matching: find.text(labels[i])),
          findsOneWidget,
          reason: labels[i],
        );
      }
      expect(
        find.descendant(of: _legend, matching: find.text('→')),
        findsNWidgets(4),
      );

      final lefts = [
        for (var i = 0; i < labels.length; i++)
          tester.getTopLeft(badges.at(i)).dx,
      ];
      expect(lefts, [...lefts]..sort());
    });
  });

  group('the "Actualizada" column', () {
    const fullValues = {
      'SCORE_BLOCK': 'hace 9 d · Laura Méndez',
      'SCORE_REVIEW': 'hace 3 d · Laura Méndez',
      'HIGH_AMOUNT_NEW_DEVICE': 'hace 12 d · Diego Salazar',
      'VELOCITY_1H': 'hace 20 d · Diego Salazar',
      'FAR_FROM_HOME': 'ayer · Laura Méndez',
      'NIGHT_TRANSFER': 'hoy · Laura Méndez',
      'ATO_PASSWORD_RESET': 'hoy · Diego Salazar',
      'VELOCITY_5M': 'hace 2 meses · Laura Méndez',
    };

    bool truncated(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(text).didExceedMaxLines;

    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    for (final width in [1280.0, 1366.0, 1424.0]) {
      testWidgets('at $width wide shows only the date, in full', (
        tester,
      ) async {
        await pumpAtWidth(tester, width);
        expect(truncated(tester, find.text('Actualizada')), isFalse);
        for (final MapEntry(key: code, value: full) in fullValues.entries) {
          final date = find.descendant(
            of: _rowOf(code),
            matching: find.text(full.split(' · ').first),
          );
          expect(date, findsOneWidget, reason: code);
          expect(truncated(tester, date), isFalse, reason: code);
          expect(find.text(full), findsNothing, reason: code);
          // The header and the values stay in the same column.
          expect(
            tester.getTopRight(date).dx,
            tester.getTopRight(find.text('Actualizada')).dx,
            reason: code,
          );
          for (final text in [
            code,
            _store(tester).ruleByCode(code)!.rule.description,
          ]) {
            expect(truncated(tester, find.text(text)), isFalse, reason: text);
          }
        }
      });
    }

    for (final width in [1425.0, 1440.0]) {
      testWidgets('at $width wide keeps the date and the author, in full', (
        tester,
      ) async {
        await pumpAtWidth(tester, width);
        for (final MapEntry(key: code, value: full) in fullValues.entries) {
          final value = find.descendant(
            of: _rowOf(code),
            matching: find.text(full),
          );
          expect(value, findsOneWidget, reason: code);
          expect(truncated(tester, value), isFalse, reason: code);
          expect(
            tester.getTopRight(value).dx,
            tester.getTopRight(find.text('Actualizada')).dx,
            reason: code,
          );
        }
      });
    }

    // The widest date up to 99 months, with the widest seed author.
    Future<void> pumpWidest(WidgetTester tester, double cardWidth) async {
      final fake = _fakeRule('FAKE_WIDEST');
      await setDesktopView(tester);
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: cardWidth,
            child: RulesPage(
              tabLabels: const ['Uno', 'Dos'],
              tab: 0,
              rows: [
                RuleView(
                  rule: fake.rule,
                  versions: [
                    fake.latest.copyWith(
                      createdBy: const UserRef(
                        id: 'u',
                        fullName: 'Laura Cárdenas',
                      ),
                      createdAt: kTestNow.subtract(
                        const Duration(days: 44 * 30),
                      ),
                    ),
                  ],
                ),
              ],
              now: kTestNow,
              canCreate: true,
              onTabSelected: (_) {},
              onNewRule: () {},
              onOpenRule: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }

    testWidgets('just below the switch point "hace 44 meses" fits', (
      tester,
    ) async {
      await pumpWidest(tester, 1120);
      final date = find.text('hace 44 meses');
      expect(date, findsOneWidget);
      expect(truncated(tester, date), isFalse);
      expect(find.text('hace 44 meses · Laura Cárdenas'), findsNothing);
    });

    testWidgets('at the switch point "hace 44 meses · Laura Cárdenas" fits', (
      tester,
    ) async {
      await pumpWidest(tester, 1121);
      final value = find.text('hace 44 meses · Laura Cárdenas');
      expect(value, findsOneWidget);
      expect(truncated(tester, value), isFalse);
    });
  });

  group('navigation', () {
    testWidgets('"Nueva regla" opens the new rule route', (tester) async {
      await pumpApp(tester, signInAs: _valentina, initialRoute: '/rules');
      await tester.tap(find.text('Nueva regla'));
      await tester.pumpAndSettle();
      expect(_editorRouteName(tester), AppRoutes.newRule);
      expect(_editorRuleId(tester), isNull);
    });

    testWidgets('tapping a row opens its editor and back keeps the tab', (
      tester,
    ) async {
      final store = await pumpApp(
        tester,
        signInAs: _valentina,
        initialRoute: '/rules',
      );
      await _tapTab(tester, 'Pendientes · 1');
      await tester.tap(_rowOf('NIGHT_TRANSFER'));
      await tester.pumpAndSettle();

      final id = store.ruleByCode('NIGHT_TRANSFER')!.rule.id;
      expect(_editorRouteName(tester), '/rules/$id');
      expect(_editorRuleId(tester), id);

      Navigator.of(tester.element(find.byType(RuleEditorScreen))).pop();
      await tester.pumpAndSettle();
      expect(_visibleCodes(tester), ['NIGHT_TRANSFER']);
    });

    testWidgets('without RULE_WRITE there is no button, rows still open', (
      tester,
    ) async {
      final store = await pumpApp(
        tester,
        signInAs: _camilo,
        initialRoute: '/rules',
      );
      expect(find.text('Nueva regla'), findsNothing);

      await tester.tap(_rowOf('SCORE_BLOCK'));
      await tester.pumpAndSettle();
      final id = store.ruleByCode('SCORE_BLOCK')!.rule.id;
      expect(_editorRouteName(tester), '/rules/$id');
      expect(_editorRuleId(tester), id);
    });
  });

  testWidgets('a rule created in the store shows up without a re-pump', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      signInAs: _laura,
      initialRoute: '/rules',
    );
    store.createRule(
      code: 'NIGHT_ATM',
      name: 'Retiro nocturno',
      conditions: const [_nightCondition],
      action: RuleAction.REVIEW,
    );
    await tester.pump();

    expect(find.byType(RuleRow), findsNWidgets(9));
    expect(find.text('Todas · 9'), findsOneWidget);
    expect(find.text('Borradores · 2'), findsOneWidget);
    expect(_rowOf('NIGHT_ATM'), findsOneWidget);
  });

  group('the page alone', () {
    testWidgets('reports the user actions through its callbacks', (
      tester,
    ) async {
      final rows = [_fakeRule('FAKE_ONE'), _fakeRule('FAKE_TWO')];
      var newRule = 0;
      final opened = <RuleView>[];
      final selected = <int>[];
      await _pumpPage(
        tester,
        rows: rows,
        onTabSelected: selected.add,
        onNewRule: () => newRule++,
        onOpenRule: opened.add,
      );

      await tester.tap(find.text('Nueva regla'));
      expect(newRule, 1);

      await tester.tap(_rowOf('FAKE_TWO'));
      expect(opened, [rows[1]]);

      await tester.tap(find.text('Dos'));
      expect(selected, [1]);
    });

    testWidgets('canCreate false hides the button and its gap', (tester) async {
      await _pumpPage(tester, canCreate: false);
      expect(find.text('Nueva regla'), findsNothing);
      expect(find.byType(AppButton), findsNothing);
      expect(
        tester.getSize(find.byType(AppTabBar)).width,
        tester.getSize(find.byType(RulesPage)).width,
      );
    });

    testWidgets('the button sits 16 px right of the tabs', (tester) async {
      await _pumpPage(tester);
      expect(
        tester.getTopLeft(find.byType(AppButton)).dx -
            tester.getTopRight(find.byType(AppTabBar)).dx,
        AppSpacing.lg,
      );
    });

    testWidgets('no rows shows the headers and the empty state', (
      tester,
    ) async {
      await _pumpPage(tester);
      for (final header in _headers) {
        expect(find.text(header), findsOneWidget, reason: header);
      }
      expect(find.text(_emptyTitle), findsOneWidget);
      expect(find.text(_emptyHint), findsOneWidget);
      expect(find.byType(RuleRow), findsNothing);
      expect(
        tester.getCenter(find.byType(EmptyState)).dx,
        tester.getCenter(find.byType(TableHeaderRow)).dx,
      );
    });

    testWidgets('the table is a card with the theme tokens', (tester) async {
      await _pumpPage(tester);
      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TableHeaderRow),
              matching: find.byType(Container),
            )
            .last,
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(card.clipBehavior, Clip.antiAlias);
      expect(decoration.color, AppColors.bgSurface);
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.lg));
      expect(decoration.border, Border.all(color: AppColors.borderDefault));
      expect(card.padding, isNull);
    });
  });
}
