import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/rules/rule_editor_page.dart';
import 'package:monedasegura_app/theme/app_icons.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _laura = 'laura.mendez@monedasegura.co';
const _diego = 'diego.salazar@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';

const _ato = 'ATO_PASSWORD_RESET';
const _scoreBlock = 'SCORE_BLOCK';

const _incomplete = 'Completa todas las condiciones antes de guardar.';

/// Opens the editor of the rule [code], signed in as [email].
Future<AppStore> _open(
  WidgetTester tester,
  String code,
  String email, {
  AppStore? store,
}) async {
  final appStore = store ?? AppStore.seeded(clock: () => kTestNow);
  await pumpApp(
    tester,
    store: appStore,
    signInAs: email,
    initialRoute: AppRoutes.ruleEditor(appStore.ruleByCode(code)!.rule.id),
  );
  return appStore;
}

Future<AppStore> _openNew(WidgetTester tester) =>
    pumpApp(tester, signInAs: _laura, initialRoute: AppRoutes.newRule);

Finder _button(String label) => find.widgetWithText(AppButton, label);

AppButton _appButton(WidgetTester tester, String label) =>
    tester.widget<AppButton>(_button(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _title(WidgetTester tester) =>
    tester.widget<TopBar>(find.byType(TopBar)).title;

String? _routeName(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byType(AppShell)))!.settings.name;

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(AppTextField, label),
  matching: find.byType(TextField),
);

Finder _row(int index) => find.byType(ConditionRow).at(index);

Finder _valueOf(int index) =>
    find.descendant(of: _row(index), matching: find.byType(TextField));

Future<void> _enter(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

/// Picks [item] in the dropdown of type [T] in condition row [index].
Future<void> _pick<T>(WidgetTester tester, int index, String item) async {
  await _tap(
    tester,
    find.descendant(of: _row(index), matching: find.byType(DropdownButton<T>)),
  );
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _create(
  WidgetTester tester, {
  String code = '',
  String name = '',
}) async {
  await _enter(tester, _field('Código'), code);
  await _enter(tester, _field('Nombre'), name);
  await _tap(tester, _button('Crear borrador'));
}

Future<void> _discard(WidgetTester tester) async {
  await _tap(tester, _button('Descartar borrador'));
  await _tap(tester, _button('Descartar'));
}

void main() {
  setUpAll(loadInterFont);

  group('new rule', () {
    testWidgets('shows the form and checks the fields', (tester) async {
      final store = await _openNew(tester);

      for (final text in [
        'Nueva regla',
        'Borrador sin guardar',
        'Datos de la regla',
        'Código',
        'Nombre',
        'Descripción',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(_button('Agregar condición'), findsOneWidget);
      expect(_button('Crear borrador'), findsOneWidget);
      expect(find.text('Correr backtest'), findsNothing);
      expect(find.byType(ConditionRow), findsOneWidget);
      expect(
        tester
            .widget<AppSegmentedControl<RuleAction>>(
              find.byType(AppSegmentedControl<RuleAction>),
            )
            .selected,
        RuleAction.REVIEW,
      );

      await _create(tester, code: 'night');
      expect(
        find.text('Usa mayúsculas, números y _ (3 a 40 caracteres).'),
        findsOneWidget,
      );

      await _create(tester, code: _scoreBlock);
      expect(find.text('Ya existe una regla con ese código.'), findsOneWidget);

      await _create(tester, code: 'NIGHT_ATM');
      expect(find.text('Escribe un nombre.'), findsOneWidget);
      expect(find.text('Ya existe una regla con ese código.'), findsNothing);

      expect(store.rules, hasLength(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a field error clears when that field changes', (tester) async {
      await _openNew(tester);
      await _create(tester, code: 'night');
      expect(find.text('Escribe un nombre.'), findsOneWidget);

      await _enter(tester, _field('Código'), 'NIGHT');
      expect(
        find.text('Usa mayúsculas, números y _ (3 a 40 caracteres).'),
        findsNothing,
      );
      expect(find.text('Escribe un nombre.'), findsOneWidget);
    });

    testWidgets('creating a valid rule opens it and lists it', (tester) async {
      final store = await _openNew(tester);

      await _pick<String>(tester, 0, 'is_night');
      await _pick<ConditionOp>(tester, 0, '=');
      await _enter(tester, _valueOf(0), 'sí');
      await _create(tester, code: 'NIGHT_ATM', name: 'Retiro nocturno');

      expect(_title(tester), 'NIGHT_ATM · v1');
      expect(
        find.byWidgetPredicate(
          (w) => w is RuleStatusBadge && w.status == RuleStatus.DRAFT,
        ),
        findsWidgets,
      );
      final created = store.ruleByCode('NIGHT_ATM')!;
      expect(created.rule.name, 'Retiro nocturno');
      final condition = created.latest.conditions.single;
      expect(condition.feature, 'is_night');
      expect(condition.op, ConditionOp.eq);
      expect(condition.value, true);
      expect(created.latest.action, RuleAction.REVIEW);

      await _tap(tester, _button('Reglas'));
      expect(find.byType(RuleRow), findsNWidgets(9));
      expect(find.text('Borradores · 2'), findsOneWidget);
    });

    testWidgets('an empty condition blocks creating', (tester) async {
      final store = await _openNew(tester);

      await _create(tester, code: 'NIGHT_ATM', name: 'Retiro nocturno');

      expect(find.text(_incomplete), findsOneWidget);
      expect(tester.widget<ConditionRow>(_row(0)).error, isTrue);
      expect(store.rules, hasLength(8));
      expect(store.ruleByCode('NIGHT_ATM'), isNull);
    });
  });

  group('editing a draft', () {
    testWidgets('adds a condition and saves it with the action', (
      tester,
    ) async {
      final store = await _open(tester, _ato, _diego);

      await _tap(tester, _button('Agregar condición'));
      expect(find.byType(ConditionRow), findsNWidgets(3));
      expect(tester.widget<ConditionRow>(_row(2)).editable, isTrue);

      await _enter(tester, _valueOf(2), '1.000.000');
      await _tap(tester, find.text('Revisar'));
      await _tap(tester, _button('Guardar borrador'));

      final saved = store.ruleByCode(_ato)!.version(1)!;
      expect(saved.conditions, hasLength(3));
      final third = saved.conditions[2];
      expect(third.feature, 'amount');
      expect(third.op, ConditionOp.gte);
      expect(third.value, 1000000);
      expect(saved.action, RuleAction.REVIEW);
      expect(find.widgetWithText(TextField, '1.000.000'), findsOneWidget);

      await _tap(tester, _button('Reglas'));
      final row = find.ancestor(
        of: find.text(_ato),
        matching: find.byType(RuleRow),
      );
      expect(
        find.descendant(of: row, matching: find.text('Revisar')),
        findsOneWidget,
      );
    });

    testWidgets('save follows changes and shadow waits for the save', (
      tester,
    ) async {
      final store = await _open(tester, _ato, _diego);

      expect(_appButton(tester, 'Guardar borrador').onPressed, isNull);
      expect(_appButton(tester, 'Iniciar shadow').onPressed, isNotNull);

      await _tap(tester, find.text('Revisar'));
      expect(_appButton(tester, 'Iniciar shadow').onPressed, isNull);
      expect(_appButton(tester, 'Guardar borrador').onPressed, isNotNull);

      await _tap(tester, _button('Guardar borrador'));
      expect(_appButton(tester, 'Iniciar shadow').onPressed, isNotNull);
      expect(_appButton(tester, 'Guardar borrador').onPressed, isNull);
      expect(store.ruleByCode(_ato)!.version(1)!.action, RuleAction.REVIEW);
    });

    testWidgets('removing a row and saving keeps one condition', (
      tester,
    ) async {
      final store = await _open(tester, _ato, _diego);

      await _tap(
        tester,
        find.descendant(of: _row(0), matching: find.byIcon(AppIcons.close)),
      );
      expect(find.byType(ConditionRow), findsOneWidget);
      await _tap(tester, _button('Guardar borrador'));

      final conditions = store.ruleByCode(_ato)!.version(1)!.conditions;
      expect(conditions, hasLength(1));
      expect(conditions.single.feature, 'is_new_device');
    });

    testWidgets('an empty value blocks saving', (tester) async {
      final store = await _open(tester, _ato, _diego);

      await _tap(tester, _button('Agregar condición'));
      expect(find.text(_incomplete), findsNothing);
      await _tap(tester, _button('Guardar borrador'));

      expect(find.text(_incomplete), findsOneWidget);
      expect(tester.widget<ConditionRow>(_row(2)).error, isTrue);
      expect(tester.widget<ConditionRow>(_row(0)).error, isFalse);
      expect(store.ruleByCode(_ato)!.version(1)!.conditions, hasLength(2));
    });

    testWidgets('discarding asks first and then removes the rule', (
      tester,
    ) async {
      final store = await _open(tester, _ato, _diego);

      await _tap(tester, _button('Descartar borrador'));
      expect(find.text('¿Descartar este borrador?'), findsOneWidget);
      expect(
        find.text('Esta versión se elimina y no se puede recuperar.'),
        findsOneWidget,
      );

      await _tap(tester, _button('Cancelar'));
      expect(find.byType(Dialog), findsNothing);
      expect(store.ruleByCode(_ato), isNotNull);

      await _discard(tester);
      expect(store.ruleByCode(_ato), isNull);
      expect(_routeName(tester), AppRoutes.rules);
      expect(_title(tester), 'Reglas');
      expect(find.byType(RuleRow), findsNWidgets(7));
    });
  });

  group('versions and permissions', () {
    testWidgets('an active version is read-only, a new one is editable', (
      tester,
    ) async {
      final store = await _open(tester, _scoreBlock, _laura);

      expect(
        find.descendant(
          of: find.byType(ConditionRow),
          matching: find.byIcon(AppIcons.close),
        ),
        findsNothing,
      );
      expect(_button('Agregar condición'), findsNothing);
      expect(_button('Guardar borrador'), findsNothing);
      expect(
        tester
            .widget<AppSegmentedControl<RuleAction>>(
              find.byType(AppSegmentedControl<RuleAction>),
            )
            .onChanged,
        isNull,
      );

      await _tap(tester, _button('Crear nueva versión'));
      expect(_title(tester), 'SCORE_BLOCK · v3');
      for (final row in tester.widgetList<ConditionRow>(
        find.byType(ConditionRow),
      )) {
        expect(row.editable, isTrue);
      }
      expect(_button('Agregar condición'), findsOneWidget);
      expect(_button('Guardar borrador'), findsOneWidget);

      await _discard(tester);
      expect(store.ruleByCode(_scoreBlock), isNotNull);
      expect(_title(tester), 'SCORE_BLOCK · v2');
      expect(_button('Agregar condición'), findsNothing);
    });

    testWidgets('without RULE_WRITE a draft is read-only', (tester) async {
      await _open(tester, _ato, _camilo);

      final rows = tester.widgetList<ConditionRow>(find.byType(ConditionRow));
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.editable, isFalse);
      }
      for (final label in [
        'Agregar condición',
        'Guardar borrador',
        'Descartar borrador',
        'Iniciar shadow',
      ]) {
        expect(_button(label), findsNothing, reason: label);
      }
    });

    testWidgets('a rejected draft can be saved but not discarded', (
      tester,
    ) async {
      final store = AppStore.seeded(clock: () => kTestNow);
      final id = store.ruleByCode(_ato)!.rule.id;
      store.signIn(_diego, MockSeed.demoPassword);
      store.startShadow(id, 1);
      store.runBacktest(id, 1);
      store.submitForApproval(id, 1);
      store.signIn(_laura, MockSeed.demoPassword);
      store.reject(id, 1, 'Falta un umbral de monto');

      await _open(tester, _ato, _laura, store: store);

      expect(store.ruleById(id)!.version(1)!.status, RuleStatus.DRAFT);
      expect(_button('Guardar borrador'), findsOneWidget);
      expect(_button('Descartar borrador'), findsNothing);
    });
  });

  group('the page alone', () {
    final rule = Rule(
      id: 'r1',
      code: 'FAKE_RULE',
      name: 'Regla de prueba',
      description: '',
      createdAt: DateTime(2026, 10, 1),
    );
    final draft = RuleVersion(
      ruleId: 'r1',
      version: 1,
      conditions: const [Condition('amount', ConditionOp.gte, 2000000)],
      action: RuleAction.REVIEW,
      status: RuleStatus.DRAFT,
      createdBy: const UserRef(id: 'creator', fullName: 'Ana Pérez'),
      createdAt: DateTime(2026, 10, 1),
    );

    Future<List<String>> pumpPage(
      WidgetTester tester, {
      required bool isNew,
    }) async {
      await setDesktopView(tester);
      final calls = <String>[];
      final code = TextEditingController();
      final name = TextEditingController();
      final description = TextEditingController();
      addTearDown(code.dispose);
      addTearDown(name.dispose);
      addTearDown(description.dispose);
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: SizedBox(
              width: 1136,
              child: RuleEditorPage(
                view: isNew ? null : RuleView(rule: rule, versions: [draft]),
                version: isNew ? null : draft,
                now: kTestNow,
                creator: null,
                approver: null,
                canWrite: true,
                canApprove: false,
                onBack: () {},
                onSelectVersion: (_) {},
                onStartShadow: () => calls.add('startShadow'),
                onRunBacktest: () {},
                onSubmit: () {},
                onApprove: () {},
                onReject: (_) {},
                onNewVersion: () {},
                draftConditions: draft.conditions,
                dirty: true,
                onFeatureChanged: (_, _) {},
                onOpChanged: (_, _) {},
                onValueChanged: (_, _) {},
                onRemoveCondition: (_) {},
                onAddCondition: () => calls.add('addCondition'),
                onActionChanged: (_) {},
                onSaveDraft: () => calls.add('saveDraft'),
                onDiscardDraft: () {},
                onCreateRule: () => calls.add('createRule'),
                codeController: code,
                nameController: name,
                descriptionController: description,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return calls;
    }

    testWidgets('an editable draft reports save and add', (tester) async {
      final calls = await pumpPage(tester, isNew: false);

      await _tap(tester, _button('Guardar borrador'));
      await _tap(tester, _button('Agregar condición'));

      expect(calls, ['saveDraft', 'addCondition']);
      expect(_appButton(tester, 'Iniciar shadow').onPressed, isNull);
    });

    testWidgets('the new-rule form reports create', (tester) async {
      final calls = await pumpPage(tester, isNew: true);

      expect(find.text('Datos de la regla'), findsOneWidget);
      expect(find.text('Versiones'), findsNothing);
      expect(
        find.text(
          'La regla se crea como borrador v1. Después podrás correr el '
          'backtest e iniciar shadow.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _button('Crear borrador'));

      expect(calls, ['createRule']);
    });
  });
}
