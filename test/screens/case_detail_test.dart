import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/app_scope.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/cases/case_detail_page.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _mateo = 'mateo.rojas@monedasegura.co';
const _b204Case = 'b204e7c1-3f5a-4d2e-9b8a-6c7d8e9f0a12';
const _camiloCase = '3a91c2d4-7e10-4b6a-8f25-2e3f4a5b6c71';

Finder _button(String label) => find.widgetWithText(AppButton, label);

AppButton _appButton(WidgetTester tester, String label) =>
    tester.widget<AppButton>(_button(label));

void _expectTexts(List<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget, reason: text);
  }
}

CaseView _fakeCase({
  CaseStatus status = CaseStatus.OPEN,
  CaseLabel? label,
  UserRef? assignedTo,
  DateTime? resolvedAt,
}) {
  final now = DateTime(2026, 1, 10, 12);
  return CaseView(
    fraudCase: FraudCase(
      id: 'abcdef12-0000-0000-0000-000000000000',
      decisionId: 'decision-1',
      status: status,
      label: label,
      assignedTo: assignedTo,
      openedAt: now.subtract(const Duration(minutes: 10)),
      resolvedAt: resolvedAt,
    ),
    transaction: Transaction(
      id: 'tx-1',
      customerId: 'customer-1',
      deviceId: 'device-1',
      type: TransactionType.DEBIT,
      category: 'shopping_net',
      amount: 120000,
      latitude: 0,
      longitude: 0,
      source: TransactionSource.SIMULATOR,
      occurredAt: now.subtract(const Duration(minutes: 11)),
    ),
    decision: Decision(
      id: 'decision-1',
      transactionId: 'tx-1',
      kind: DecisionKind.ORIGINAL,
      verdict: Verdict.BLOCK,
      degraded: true,
      features: const {'is_new_device': false, 'km_from_home': 0.4},
      ruleHits: const [
        RuleHit(
          ruleId: 'rule-1',
          ruleCode: 'TEST_RULE',
          version: 1,
          action: RuleAction.BLOCK,
          matched: true,
          shadow: false,
        ),
      ],
      latencyMs: 12,
      decidedAt: now,
    ),
    customer: Customer(
      id: 'customer-1',
      maskedName: 'Laura G.',
      maskedDocument: '****1234',
      homeCity: 'Cali',
      createdAt: DateTime(2020, 5, 1),
      transactions30d: 7,
      previousFrauds: 1,
    ),
    device: Device(
      id: 'device-1',
      fingerprint: 'fp',
      os: DeviceOs.IOS,
      firstSeenAt: DateTime(2024, 2, 1),
    ),
  );
}

void main() {
  group('signed in as Valentina on #B204E7', () {
    Future<void> pumpB204(WidgetTester tester) => pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.caseDetail(_b204Case),
    );

    testWidgets('shows the header and the transaction', (tester) async {
      await pumpB204(tester);
      _expectTexts([
        'Caso #B204E7',
        'Abierto hace 4 min · sin asignar',
        'Volver a la cola',
        'En revisión',
        'Tomar caso',
        '\$ 3.250.000',
        'COP · 25 oct 2026, 09:41',
        'Compra',
        'ElectroHogar Bogotá',
        'Compra en línea',
        'Nuevo · primera vez hoy',
        'A 412 km de su ciudad',
        'Android',
      ]);
    });

    testWidgets('shows why it was flagged', (tester) async {
      await pumpB204(tester);
      _expectTexts([
        'Por qué se marcó',
        '0,67 · modelo v5',
        'SCORE_REVIEW',
        'HIGH_AMOUNT_NEW_DEVICE',
        'VELOCITY_1H',
        'FAR_FROM_HOME',
        'Score del modelo ≥ 0,60 → Revisar',
        'amount_vs_avg_30d × 4,1',
        'is_new_device = sí',
        'km_from_home = 412',
        'tx_count_1h = 3',
      ]);
      expect(find.text('Coincide'), findsNWidgets(2));
      expect(find.text('No coincide'), findsOneWidget);
      expect(find.text('Shadow'), findsOneWidget);
    });

    testWidgets('shows the customer and the label card', (tester) async {
      await pumpB204(tester);
      _expectTexts([
        'Andrés P.',
        'Documento •••• 4821',
        'Bogotá',
        'mar 2023',
        '41',
        '0',
        'Etiquetar caso',
        'Fraude confirmado',
        'Legítima',
        'Notas',
        'La etiqueta entra al reentrenamiento de las 02:00',
      ]);
      expect(
        tester.widget<AppAvatar>(find.byType(AppAvatar).last).initials,
        'AP',
      );
    });

    testWidgets('selecting a label enables Guardar etiqueta', (tester) async {
      await pumpB204(tester);
      expect(_appButton(tester, 'Guardar etiqueta').onPressed, isNull);

      await tester.tap(find.text('Fraude confirmado'));
      await tester.pump();

      final option = find.widgetWithText(OptionCard, 'Fraude confirmado');
      expect(tester.widget<OptionCard>(option).selected, isTrue);
      final container = tester.widget<Container>(
        find.descendant(of: option, matching: find.byType(Container)),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        AppColors.statusBlockBg,
      );
      expect(_appButton(tester, 'Guardar etiqueta').onPressed, isNotNull);
    });

    testWidgets('Tomar caso assigns the case to her', (tester) async {
      await pumpB204(tester);
      await tester.tap(_button('Tomar caso'));
      await tester.pumpAndSettle();

      expect(find.text('Abierto hace 4 min · asignado a ti'), findsOneWidget);
      expect(_button('Tomar caso'), findsNothing);
      final store = AppScope.read(tester.element(find.byType(CaseDetailPage)));
      final view = store.caseById(_b204Case)!;
      expect(view.status, CaseStatus.IN_REVIEW);
      expect(view.assignedTo?.id, store.currentUser!.id);
      expect(store.currentUser!.email, _valentina);
    });

    testWidgets('Guardar etiqueta resolves the case and goes to the queue', (
      tester,
    ) async {
      final store = await pumpApp(
        tester,
        signInAs: _valentina,
        initialRoute: AppRoutes.caseDetail(_b204Case),
      );
      await tester.tap(find.text('Fraude confirmado'));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppTextField),
          matching: find.byType(TextField),
        ),
        'Cliente no reconoce',
      );
      await tester.tap(_button('Guardar etiqueta'));
      await tester.pumpAndSettle();

      expect(find.text('Cola de casos'), findsOneWidget);
      expect(
        find.text('Caso #B204E7 etiquetado como Fraude confirmado'),
        findsOneWidget,
      );
      final view = store.caseById(_b204Case)!;
      expect(view.status, CaseStatus.RESOLVED);
      expect(view.label, CaseLabel.CONFIRMED_FRAUD);
      expect(view.fraudCase.notes, 'Cliente no reconoce');
      expect(store.openCases.length, 8);
    });
  });

  testWidgets('Mateo sees no Tomar caso and no label card', (tester) async {
    await pumpApp(
      tester,
      signInAs: _mateo,
      initialRoute: AppRoutes.caseDetail(_b204Case),
    );
    expect(find.text('Caso #B204E7'), findsOneWidget);
    expect(find.text('Tomar caso'), findsNothing);
    expect(find.text('Etiquetar caso'), findsNothing);
  });

  testWidgets('a case assigned to someone else is read-only', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.caseDetail(_camiloCase),
    );
    expect(find.textContaining('asignado a Camilo Torres'), findsOneWidget);
    expect(find.text('Asignado a Camilo Torres'), findsOneWidget);
    expect(_appButton(tester, 'Guardar etiqueta').onPressed, isNull);
    for (final option in tester.widgetList<OptionCard>(
      find.byType(OptionCard),
    )) {
      expect(option.onTap, isNull);
    }
  });

  testWidgets('an unknown id shows the empty state', (tester) async {
    await pumpApp(
      tester,
      signInAs: _valentina,
      initialRoute: AppRoutes.caseDetail('does-not-exist'),
    );
    expect(find.text('No encontramos este caso'), findsOneWidget);
    expect(find.text('Volver a la cola'), findsOneWidget);

    await tester.tap(_button('Volver a la cola'));
    await tester.pumpAndSettle();
    expect(find.text('Cola de casos'), findsOneWidget);
  });

  group('CaseDetailPage alone', () {
    testWidgets('reports Guardar etiqueta and Tomar caso', (tester) async {
      await setDesktopView(tester);
      final notes = TextEditingController();
      addTearDown(notes.dispose);
      var saves = 0;
      var takes = 0;
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: CaseDetailPage(
              view: _fakeCase(),
              rules: const {},
              now: DateTime(2026, 1, 10, 12),
              currentUserId: 'user-1',
              canResolve: true,
              selectedLabel: CaseLabel.DISMISSED,
              notes: notes,
              onBack: () {},
              onTake: () => takes++,
              onSelectLabel: (_) {},
              onSave: () => saves++,
            ),
          ),
        ),
      );

      expect(find.byType(AppScope), findsNothing);
      expect(find.text('Degradada'), findsOneWidget);
      expect(find.text('— · solo reglas'), findsOneWidget);
      expect(find.text('Conocido · desde feb 2024'), findsOneWidget);
      expect(find.text('En su ciudad'), findsOneWidget);
      expect(find.text('Documento •••• 1234'), findsOneWidget);

      await tester.tap(_button('Guardar etiqueta'));
      await tester.tap(_button('Tomar caso'));
      expect(saves, 1);
      expect(takes, 1);
    });

    testWidgets('a resolved case is read-only', (tester) async {
      await setDesktopView(tester);
      final notes = TextEditingController(text: 'Revisado');
      addTearDown(notes.dispose);
      final now = DateTime(2026, 1, 10, 12);
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: CaseDetailPage(
              view: _fakeCase(
                status: CaseStatus.RESOLVED,
                label: CaseLabel.DISMISSED,
                assignedTo: const UserRef(id: 'user-1', fullName: 'Ana'),
                resolvedAt: now.subtract(const Duration(hours: 2)),
              ),
              rules: const {},
              now: now,
              currentUserId: 'user-1',
              canResolve: true,
              selectedLabel: CaseLabel.DISMISSED,
              notes: notes,
              onBack: () {},
              onTake: null,
              onSelectLabel: (_) {},
              onSave: null,
            ),
          ),
        ),
      );

      expect(_button('Guardar etiqueta'), findsNothing);
      expect(_button('Tomar caso'), findsNothing);
      expect(find.text('Resuelto hace 2 h'), findsOneWidget);
      final legit = tester.widget<OptionCard>(
        find.widgetWithText(OptionCard, 'Legítima'),
      );
      expect(legit.selected, isTrue);
      expect(legit.onTap, isNull);
    });
  });
}
