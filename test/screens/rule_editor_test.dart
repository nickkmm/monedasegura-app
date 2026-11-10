import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/rules/rule_editor_page.dart';
import 'package:monedasegura_app/screens/rules/rules_screen.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _lauraMendez = 'laura.mendez@monedasegura.co';
const _diego = 'diego.salazar@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';

const _night = 'NIGHT_TRANSFER';
const _farFromHome = 'FAR_FROM_HOME';
const _ato = 'ATO_PASSWORD_RESET';
const _scoreBlock = 'SCORE_BLOCK';

/// Opens the editor of the rule [code], signed in as [email].
Future<AppStore> _open(WidgetTester tester, String code, String email) async {
  final store = AppStore.seeded(clock: () => kTestNow);
  await pumpApp(
    tester,
    store: store,
    signInAs: email,
    initialRoute: AppRoutes.ruleEditor(store.ruleByCode(code)!.rule.id),
  );
  return store;
}

Finder _button(String label) => find.widgetWithText(AppButton, label);

AppButton _appButton(WidgetTester tester, String label) =>
    tester.widget<AppButton>(_button(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The tappable row of version [label] ("v2") in the versions card.
Finder _versionRow(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
    .first;

Finder _inRow(String version, String text) =>
    find.descendant(of: _versionRow(version), matching: find.text(text));

/// The reason field of the dialog: the top bar has a text field of its own.
final _reason = find.descendant(
  of: find.byType(Dialog),
  matching: find.byType(TextField),
);

Finder _approverBox() => find
    .ancestor(of: find.text('Puede aprobar'), matching: find.byType(Container))
    .first;

List<StepperStepState> _stepStates(WidgetTester tester) => [
  for (final step in tester.widgetList<StepperStep>(find.byType(StepperStep)))
    step.state,
];

MetricTile _tile(WidgetTester tester, String label) =>
    tester.widget<MetricTile>(find.widgetWithText(MetricTile, label));

const _reviewCondition = Condition('amount', ConditionOp.gte, 2000000);
const _ref = UserRef(id: 'creator', fullName: 'Ana Pérez');

RuleVersion _fakeVersion({
  int version = 1,
  RuleStatus status = RuleStatus.PENDING_APPROVAL,
  List<Condition> conditions = const [_reviewCondition],
  ShadowStats? shadowStats,
  DateTime? submittedAt,
}) => RuleVersion(
  ruleId: 'r1',
  version: version,
  conditions: conditions,
  action: RuleAction.REVIEW,
  status: status,
  createdBy: _ref,
  createdAt: DateTime(2026, 10, 1),
  shadowStats: shadowStats,
  submittedAt: submittedAt,
);

const _fakeApprover = AppUser(
  id: 'approver',
  fullName: 'Marta Gil',
  email: 'marta@example.com',
  active: true,
  roles: [RoleCode.RISK_LEAD],
);

class _Recorder {
  int approved = 0;
  final rejected = <String>[];
  final selected = <int>[];
}

/// Pumps the page alone: no app, no scope, plain data and recording callbacks.
Future<_Recorder> _pumpPage(
  WidgetTester tester, {
  required List<RuleVersion> versions,
  bool canApprove = true,
  bool canWrite = false,
  AppUser? creator,
}) async {
  await setDesktopView(tester);
  final recorder = _Recorder();
  await tester.pumpWidget(
    harness(
      SingleChildScrollView(
        child: SizedBox(
          width: 1136,
          child: RuleEditorPage(
            view: RuleView(
              rule: Rule(
                id: 'r1',
                code: 'FAKE_RULE',
                name: 'Regla de prueba',
                description: '',
                createdAt: DateTime(2026, 10, 1),
              ),
              versions: versions,
            ),
            version: versions.first,
            now: kTestNow,
            creator: creator,
            approver: _fakeApprover,
            canWrite: canWrite,
            canApprove: canApprove,
            onBack: () {},
            onSelectVersion: recorder.selected.add,
            onStartShadow: () {},
            onRunBacktest: () {},
            onSubmit: () {},
            onApprove: () => recorder.approved++,
            onReject: recorder.rejected.add,
            onNewVersion: () {},
            onFeatureChanged: (_, _) {},
            onOpChanged: (_, _) {},
            onValueChanged: (_, _) {},
            onRemoveCondition: (_) {},
            onAddCondition: () {},
            onActionChanged: (_) {},
            onSaveDraft: () {},
            onDiscardDraft: () {},
            onCreateRule: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return recorder;
}

void main() {
  setUpAll(loadInterFont);

  group('NIGHT_TRANSFER as Valentina', () {
    testWidgets('shows the header, stepper and condition', (tester) async {
      await _open(tester, _night, _valentina);

      expect(find.text('NIGHT_TRANSFER · v2'), findsOneWidget);
      expect(find.text('Transferencia nocturna de monto alto'), findsOneWidget);
      expect(_button('Reglas'), findsOneWidget);

      for (final step in ['Borrador', 'Shadow · 5 d', 'Aprobación', 'Activa']) {
        expect(
          find.descendant(
            of: find.byType(StepperStep),
            matching: find.text(step),
          ),
          findsOneWidget,
        );
      }
      expect(_stepStates(tester), [
        StepperStepState.done,
        StepperStepState.done,
        StepperStepState.current,
        StepperStepState.pending,
      ]);

      expect(find.text('Condición'), findsOneWidget);
      expect(find.text('Se cumple cuando se cumplen todas'), findsOneWidget);
      expect(find.text('is_night'), findsOneWidget);
      expect(find.text('Sí'), findsOneWidget);
      expect(find.text('amount'), findsOneWidget);
      expect(find.text('≥'), findsOneWidget);
      expect(find.text(r'$ 2.000.000'), findsOneWidget);
      expect(find.text('Acción'), findsOneWidget);

      final action = tester.widget<AppSegmentedControl<RuleAction>>(
        find.byType(AppSegmentedControl<RuleAction>),
      );
      expect(action.onChanged, isNull);
      expect(action.selected, RuleAction.REVIEW);
      expect(find.text('Revisar'), findsOneWidget);
      expect(find.text('Bloquear'), findsOneWidget);
      expect(
        tester
            .widgetList<ConditionRow>(find.byType(ConditionRow))
            .every((row) => !row.editable),
        isTrue,
      );
    });

    testWidgets('shows the backtest and the shadow banner', (tester) async {
      await _open(tester, _night, _valentina);

      expect(find.text('Backtest · últimos 30 días'), findsOneWidget);
      expect(find.text('Sobre 1.920 casos etiquetados'), findsOneWidget);
      expect(find.text('79'), findsOneWidget);
      expect(find.text('4,1 % de los casos'), findsOneWidget);
      expect(find.text('41'), findsOneWidget);
      expect(find.text('+9 que hoy se escapan'), findsOneWidget);
      expect(find.text('0,52'), findsOneWidget);
      expect(find.text('objetivo ≥ 0,40'), findsOneWidget);
      expect(find.text('+3,1 pp'), findsOneWidget);
      expect(find.text('0,74 → 0,77'), findsOneWidget);
      expect(
        find.text(
          '5 días en shadow: 61 coincidencias, ninguna decisión cambiada '
          'todavía.',
        ),
        findsOneWidget,
      );
      final banner = tester.widget<AppBanner>(find.byType(AppBanner));
      expect((banner.leading! as RuleStatusBadge).status, RuleStatus.SHADOW);
      expect(_appButton(tester, 'Volver a correr').onPressed, isNull);
    });

    testWidgets('shows the approval timeline and the versions', (tester) async {
      await _open(tester, _night, _valentina);

      expect(find.text('Aprobación en dos pasos'), findsOneWidget);
      expect(find.text('Creada por Laura Méndez'), findsOneWidget);
      expect(find.text('Líder de riesgo · 19 oct'), findsOneWidget);
      expect(find.text('Shadow iniciado'), findsOneWidget);
      expect(find.text('20 oct · 5 días'), findsOneWidget);
      expect(find.text('Enviada a aprobación'), findsOneWidget);
      expect(find.text('hoy, 08:10'), findsOneWidget);
      expect(
        find.text('Esperando a otra persona con permiso para aprobar'),
        findsOneWidget,
      );
      expect(find.text('Quien la creó no puede aprobarla'), findsOneWidget);
      expect(
        find.descendant(
          of: _approverBox(),
          matching: find.text('Valentina Ríos'),
        ),
        findsOneWidget,
      );
      expect(_button('Aprobar y activar'), findsOneWidget);
      expect(_button('Devolver a borrador'), findsOneWidget);

      expect(find.text('Versiones'), findsOneWidget);
      expect(_inRow('v2', r'≥ $ 2.000.000 · Revisar'), findsOneWidget);
      expect(_inRow('v2', 'Pendiente'), findsOneWidget);
      expect(_inRow('v1', r'≥ $ 5.000.000 · Revisar'), findsOneWidget);
      expect(_inRow('v1', 'Activa'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('v2')).dy,
        lessThan(tester.getTopLeft(find.text('v1')).dy),
      );
    });

    testWidgets('lays out the columns and marks the selected row', (
      tester,
    ) async {
      await _open(tester, _night, _valentina);

      final side = find.ancestor(
        of: find.text('Versiones'),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(side.first).width, 360);
      expect(tester.getSize(_versionRow('v2')).height, 40);

      BoxDecoration? decoration(String version) {
        final container = find
            .descendant(
              of: _versionRow(version),
              matching: find.byType(Container),
            )
            .first;
        return tester.widget<Container>(container).decoration as BoxDecoration?;
      }

      expect(decoration('v2')?.color, AppColors.bgCanvas);
      expect(
        decoration('v2')?.borderRadius,
        BorderRadius.circular(AppRadius.sm),
      );
      expect(decoration('v1'), isNull);
    });

    testWidgets('approving activates v2 and keeps it selected', (tester) async {
      await _open(tester, _night, _valentina);

      await _tap(tester, _button('Aprobar y activar'));

      expect(_inRow('v2', 'Activa'), findsOneWidget);
      expect(_inRow('v1', 'Retirada'), findsOneWidget);
      expect(_stepStates(tester), List.filled(4, StepperStepState.done));
      expect(find.text('NIGHT_TRANSFER · v2'), findsOneWidget);
      expect(find.text('Aprobada por Valentina Ríos'), findsOneWidget);
      expect(_button('Aprobar y activar'), findsNothing);

      await _tap(tester, _button('Reglas'));

      final row = find.ancestor(
        of: find.text(_night),
        matching: find.byType(RuleRow),
      );
      expect(find.descendant(of: row, matching: find.text('Activa')), findsOne);
      expect(
        find.descendant(of: row, matching: find.text('Pendiente')),
        findsNothing,
      );
    });

    testWidgets('returning to draft asks for a reason', (tester) async {
      await _open(tester, _night, _valentina);

      await _tap(tester, _button('Devolver a borrador'));
      expect(find.text('Motivo'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Devolver a borrador'),
        ),
        findsOneWidget,
      );
      expect(_appButton(tester, 'Devolver').onPressed, isNull);

      await tester.enterText(_reason, '   ');
      await tester.pump();
      expect(_appButton(tester, 'Devolver').onPressed, isNull);

      await tester.enterText(_reason, '  Falta evidencia ');
      await tester.pump();
      expect(_appButton(tester, 'Devolver').onPressed, isNotNull);

      await _tap(tester, _button('Devolver'));

      expect(find.byType(Dialog), findsNothing);
      expect(_inRow('v2', 'Borrador'), findsOneWidget);
      expect(find.text('Devuelta a borrador'), findsOneWidget);
      expect(find.text('Falta evidencia'), findsOneWidget);
      expect(find.text('Shadow iniciado'), findsNothing);
    });

    testWidgets('cancelling the dialog leaves v2 pending', (tester) async {
      await _open(tester, _night, _valentina);

      await _tap(tester, _button('Devolver a borrador'));
      await tester.enterText(_reason, 'Falta evidencia');
      await tester.pump();
      await _tap(tester, _button('Cancelar'));

      expect(find.byType(Dialog), findsNothing);
      expect(_inRow('v2', 'Pendiente'), findsOneWidget);
      expect(find.text('Devuelta a borrador'), findsNothing);
    });

    testWidgets('a store error shows a message and changes nothing', (
      tester,
    ) async {
      await _open(tester, _night, _valentina);

      // The page never offers this action on a pending version.
      tester
          .widget<RuleEditorPage>(find.byType(RuleEditorPage))
          .onStartShadow();
      await tester.pump();

      expect(find.text('No se pudo completar la acción.'), findsOneWidget);
      expect(_inRow('v2', 'Pendiente'), findsOneWidget);
    });

    testWidgets('the back button goes to the rules list', (tester) async {
      await _open(tester, _night, _valentina);

      await _tap(tester, _button('Reglas'));

      expect(find.byType(RulesScreen), findsOneWidget);
    });
  });

  group('four eyes', () {
    testWidgets('the creator cannot approve and sees who can', (tester) async {
      await _open(tester, _night, _lauraMendez);

      expect(_button('Aprobar y activar'), findsNothing);
      expect(_button('Devolver a borrador'), findsNothing);
      expect(
        find.descendant(
          of: _approverBox(),
          matching: find.text('Valentina Ríos'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('another risk lead can approve', (tester) async {
      await _open(tester, _night, _diego);

      expect(_button('Aprobar y activar'), findsOneWidget);
      expect(
        find.descendant(
          of: _approverBox(),
          matching: find.text('Diego Salazar'),
        ),
        findsOneWidget,
      );
    });
  });

  group('backtest gate', () {
    testWidgets('ATO_PASSWORD_RESET needs a backtest before submitting', (
      tester,
    ) async {
      await _open(tester, _ato, _lauraMendez);
      const caption = 'Corre el backtest antes de enviar.';

      await _tap(tester, _button('Iniciar shadow'));
      expect(_inRow('v1', 'Shadow'), findsOneWidget);
      expect(_appButton(tester, 'Enviar a aprobación').onPressed, isNull);
      expect(find.text(caption), findsOneWidget);

      await _tap(tester, _button('Correr backtest'));
      expect(_appButton(tester, 'Enviar a aprobación').onPressed, isNotNull);
      expect(find.text(caption), findsNothing);

      await _tap(tester, _button('Enviar a aprobación'));
      expect(_inRow('v1', 'Pendiente'), findsOneWidget);
    });

    testWidgets('FAR_FROM_HOME can be submitted right away', (tester) async {
      await _open(tester, _farFromHome, _lauraMendez);

      expect(_button('Volver a correr'), findsOneWidget);
      expect(_appButton(tester, 'Volver a correr').onPressed, isNotNull);
      expect(_appButton(tester, 'Enviar a aprobación').onPressed, isNotNull);
      expect(
        find.text(
          '1 día en shadow: 1.102 coincidencias, 14 decisiones cambiarían.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('· 1 día'), findsOneWidget);

      await _tap(tester, _button('Enviar a aprobación'));
      expect(_inRow('v1', 'Pendiente'), findsOneWidget);
    });
  });

  group('versions', () {
    testWidgets('creating a new version selects it', (tester) async {
      await _open(tester, _scoreBlock, _lauraMendez);

      await _tap(tester, _button('Crear nueva versión'));

      expect(_inRow('v3', 'Borrador'), findsOneWidget);
      expect(find.text('SCORE_BLOCK · v3'), findsOneWidget);
      expect(_button('Crear nueva versión'), findsNothing);
      expect(_button('Iniciar shadow'), findsOneWidget);
    });

    testWidgets('selecting an old version hides the new version button', (
      tester,
    ) async {
      await _open(tester, _scoreBlock, _lauraMendez);
      expect(_button('Crear nueva versión'), findsOneWidget);

      await _tap(tester, _versionRow('v1'));

      expect(find.text('SCORE_BLOCK · v1'), findsOneWidget);
      expect(_button('Crear nueva versión'), findsNothing);
    });
  });

  testWidgets('a read-only user has no lifecycle actions', (tester) async {
    for (final code in [_night, _farFromHome, _ato, _scoreBlock]) {
      await _open(tester, code, _camilo);

      for (final label in [
        'Volver a correr',
        'Correr backtest',
        'Aprobar y activar',
        'Devolver a borrador',
        'Enviar a aprobación',
        'Iniciar shadow',
        'Crear nueva versión',
      ]) {
        expect(_button(label), findsNothing, reason: '$code: $label');
      }
      expect(_button('Reglas'), findsOneWidget, reason: code);
      expect(_versionRow('v1'), findsOneWidget, reason: code);
    }
  });

  group('without data', () {
    testWidgets('a version without a backtest says so', (tester) async {
      await _open(tester, _ato, _lauraMendez);

      expect(
        find.text('Todavía no hay backtest para esta versión.'),
        findsOneWidget,
      );
      expect(find.textContaining('casos etiquetados'), findsNothing);
      expect(_button('Correr backtest'), findsOneWidget);
      expect(find.byType(MetricTile), findsNothing);

      await _tap(tester, _button('Correr backtest'));

      expect(
        _tile(tester, 'Fraudes atrapados').note,
        'Sin versión activa para comparar',
      );
      expect(find.textContaining('casos etiquetados'), findsOneWidget);
    });

    testWidgets('a backtest without recall shows a dash', (tester) async {
      await _open(tester, _farFromHome, _lauraMendez);

      final recall = _tile(tester, 'Recall total');
      expect(recall.value, '—');
      expect(recall.note, '');
    });

    testWidgets('a version worse than the active one reads as such', (
      tester,
    ) async {
      await _open(tester, _scoreBlock, _lauraMendez);

      await _tap(tester, _button('Crear nueva versión'));
      await _tap(tester, _button('Correr backtest'));

      expect(
        _tile(tester, 'Fraudes atrapados').note,
        'Sin fraudes nuevos frente a la versión activa',
      );
      expect(_tile(tester, 'Recall total').value, startsWith('-'));
    });
  });

  group('empty states', () {
    testWidgets('/rules/new opens the new-rule form', (tester) async {
      await pumpApp(
        tester,
        signInAs: _lauraMendez,
        initialRoute: AppRoutes.newRule,
      );

      expect(find.text('Nueva regla'), findsOneWidget);
      expect(find.text('Datos de la regla'), findsOneWidget);
      expect(_button('Crear borrador'), findsOneWidget);
    });

    testWidgets('an unknown rule offers the way back', (tester) async {
      await pumpApp(
        tester,
        signInAs: _lauraMendez,
        initialRoute: AppRoutes.ruleEditor('abc'),
      );

      expect(find.text('No encontramos esta regla'), findsOneWidget);
      expect(find.text('Puede que se haya descartado.'), findsOneWidget);

      await _tap(tester, _button('Reglas'));

      expect(find.byType(RulesScreen), findsOneWidget);
    });
  });

  group('RuleEditorPage alone', () {
    testWidgets('reports approve, reject and version selection', (
      tester,
    ) async {
      final recorder = await _pumpPage(
        tester,
        versions: [
          _fakeVersion(version: 2),
          _fakeVersion(status: RuleStatus.ACTIVE),
        ],
      );

      await _tap(tester, _button('Aprobar y activar'));
      expect(recorder.approved, 1);

      await _tap(tester, _button('Devolver a borrador'));
      await tester.enterText(_reason, ' Falta evidencia ');
      await tester.pump();
      await _tap(tester, _button('Devolver'));
      expect(recorder.rejected, ['Falta evidencia']);

      await _tap(tester, _versionRow('v1'));
      expect(recorder.selected, [1]);
    });

    testWidgets('uses the singular for one match and one change', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        versions: [
          _fakeVersion(
            shadowStats: ShadowStats(
              since: kTestNow.subtract(const Duration(days: 1)),
              evaluated: 10,
              matched: 1,
              verdictChanges: 1,
            ),
          ),
        ],
      );

      expect(
        find.text('1 día en shadow: 1 coincidencia, 1 decisión cambiaría.'),
        findsOneWidget,
      );
      expect(find.text('Shadow · 1 d'), findsOneWidget);
    });

    testWidgets('without a known creator the meta is only the date', (
      tester,
    ) async {
      await _pumpPage(tester, versions: [_fakeVersion()]);

      expect(find.text('Creada por Ana Pérez'), findsOneWidget);
      expect(find.text('1 oct'), findsOneWidget);
    });

    testWidgets('the summary falls back to the first condition', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        versions: [
          _fakeVersion(
            conditions: const [
              Condition('km_from_home', ConditionOp.gt, 300),
              Condition('is_night', ConditionOp.eq, true),
            ],
          ),
        ],
      );

      expect(find.text('> 300 · Revisar'), findsOneWidget);
    });

    testWidgets('a retired latest version with one in progress has no action', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        canApprove: false,
        canWrite: true,
        versions: [
          _fakeVersion(status: RuleStatus.RETIRED, version: 2),
          _fakeVersion(status: RuleStatus.DRAFT),
        ],
      );

      expect(_button('Crear nueva versión'), findsNothing);
    });
  });
}
