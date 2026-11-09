import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/app/routes.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/screens/models/models_page.dart';
import 'package:monedasegura_app/theme/app_text_styles.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';
import '../helpers/pump_app.dart';

const _lauraCardenas = 'laura.cardenas@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';
const _lauraMendez = 'laura.mendez@monedasegura.co';
const _diego = 'diego.salazar@monedasegura.co';

const _importance = {'amount_vs_avg_30d': 0.4, 'is_night': 0.2};

ModelVersion _model(
  String version,
  ModelStatus status, {
  required DateTime trainedAt,
  double prAuc = 0.8,
  int fraudsSeen = 1000,
}) => ModelVersion(
  id: version,
  version: version,
  trigger: ModelTrigger.SCHEDULED,
  status: status,
  metrics: ModelMetrics(
    prAuc: prAuc,
    precision: 0.6,
    recall: 0.7,
    featureImportance: _importance,
  ),
  trainedAt: trainedAt,
  trainingRows: 100000,
  fraudsSeen: fraudsSeen,
);

Future<void> _pumpPage(
  WidgetTester tester, {
  required List<ModelVersion> models,
  required ModelVersion? activeModel,
  VoidCallback? onRetrain,
}) async {
  await setDesktopView(tester);
  await tester.pumpWidget(
    harness(
      SingleChildScrollView(
        child: SizedBox(
          width: 1136,
          child: ModelsPage(
            models: models,
            activeModel: activeModel,
            reviewThreshold: 0.6,
            blockThreshold: 0.9,
            now: kTestNow,
            onRetrain: onRetrain,
          ),
        ),
      ),
    ),
  );
}

/// The version shown in the production card's display text.
Finder _displayText(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      widget.data == text &&
      widget.style?.fontSize == AppTextStyles.display.fontSize,
);

void main() {
  setUpAll(loadInterFont);

  testWidgets('shows the production model and its deltas', (tester) async {
    await pumpApp(
      tester,
      signInAs: _lauraCardenas,
      initialRoute: AppRoutes.models,
    );
    // "Modelos" is also the sidebar entry.
    expect(find.text('Modelos'), findsWidgets);
    for (final text in [
      'Modelo de scoring · LightGBM',
      'Modelo en producción',
      'Entrenado hoy a las 02:00 · automático · 182.400 transacciones',
      'PR-AUC',
      'Recall',
      'Precisión',
      '0,62',
      'Fraudes vistos',
      '1.940',
      '+0,01 vs. anterior',
      '+120 vs. anterior',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    // Also in the v5 row of the table.
    for (final text in ['Activo', 'v5', '0,81', '0,74']) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(_displayText('v5'), findsOneWidget);
    expect(find.text('+0,02 vs. anterior'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the decision thresholds', (tester) async {
    await pumpApp(
      tester,
      signInAs: _lauraCardenas,
      initialRoute: AppRoutes.models,
    );
    for (final text in [
      'Umbrales de decisión',
      'Según el puntaje de riesgo del modelo',
      'Aprobar',
      '< 0,60',
      'Revisar',
      '0,60 – 0,90',
      'Bloquear',
      '≥ 0,90',
      '0,60',
      '0,90',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('0'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('shows the versions table and the feature importance', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signInAs: _lauraCardenas,
      initialRoute: AppRoutes.models,
    );
    for (final version in ['v5', 'v4', 'v3', 'v2', 'v1']) {
      expect(find.text(version), findsWidgets, reason: version);
    }
    expect(
      tester.getTopLeft(find.text('v5').last).dy,
      lessThan(tester.getTopLeft(find.text('v1')).dy),
    );
    expect(find.text('25 oct · 02:00'), findsOneWidget);
    expect(find.text('Manual · Laura C.'), findsOneWidget);
    expect(find.text('Candidato'), findsOneWidget);
    expect(find.text('Retirado'), findsNWidgets(3));
    for (final text in [
      'Variables más influyentes',
      'Importancia relativa en la versión activa',
      'Monto vs. promedio 30 días',
      'Dispositivo nuevo',
      'Transacciones última hora',
      'Velocidad entre ubicaciones',
      'Horario nocturno',
      'Inicios de sesión fallidos',
      '100 %',
      '78 %',
      '27 %',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('retraining adds v6 as the active model', (tester) async {
    await pumpApp(
      tester,
      signInAs: _lauraCardenas,
      initialRoute: AppRoutes.models,
    );
    await tester.tap(find.text('Reentrenar ahora'));
    await tester.pumpAndSettle();

    expect(find.text('v6'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('v6').last).dy,
      lessThan(tester.getTopLeft(find.text('v5')).dy),
    );
    expect(find.text('Activo'), findsNWidgets(2));
    expect(find.text('Retirado'), findsNWidgets(4));
    expect(_displayText('v6'), findsOneWidget);
    expect(_displayText('v5'), findsNothing);
    expect(find.text('v6 entrenado y activado.'), findsOneWidget);
  });

  testWidgets('hides retraining without MODEL_TRAIN', (tester) async {
    await pumpApp(tester, signInAs: _camilo, initialRoute: AppRoutes.models);
    expect(find.text('Modelos'), findsWidgets);
    expect(find.text('Modelo en producción'), findsOneWidget);
    expect(find.text('Reentrenar ahora'), findsNothing);
  });

  testWidgets('reads the thresholds from the active score rules', (
    tester,
  ) async {
    final store = AppStore.seeded(clock: () => kTestNow);
    store.signIn(_lauraMendez, MockSeed.demoPassword);
    final id = store.ruleByCode('SCORE_REVIEW')!.rule.id;
    final version = store.createVersion(id).version;
    store.updateDraft(
      id,
      version,
      conditions: const [Condition('score', ConditionOp.gte, 0.5)],
      action: RuleAction.REVIEW,
    );
    store.startShadow(id, version);
    store.runBacktest(id, version);
    store.submitForApproval(id, version);
    store.signIn(_diego, MockSeed.demoPassword);
    store.approve(id, version);

    await pumpApp(
      tester,
      store: store,
      signInAs: _lauraCardenas,
      initialRoute: AppRoutes.models,
    );
    expect(find.text('< 0,50'), findsOneWidget);
    expect(find.text('0,50 – 0,90'), findsOneWidget);
    expect(find.text('0,50'), findsOneWidget);
  });

  group('ModelsPage', () {
    final active = _model(
      'v3',
      ModelStatus.ACTIVE,
      trainedAt: DateTime(2026, 10, 25, 2),
      prAuc: 0.8,
      fraudsSeen: 1000,
    );
    final retired = _model(
      'v2',
      ModelStatus.RETIRED,
      trainedAt: DateTime(2026, 10, 24, 2),
      prAuc: 0.83,
      fraudsSeen: 1050,
    );

    testWidgets('reports the retrain tap once', (tester) async {
      var taps = 0;
      await _pumpPage(
        tester,
        models: [active, retired],
        activeModel: active,
        onRetrain: () => taps++,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Reentrenar ahora'));
      await tester.pump();
      expect(taps, 1);
      expect(find.text('-0,03 vs. anterior'), findsOneWidget);
      expect(find.text('-50 vs. anterior'), findsOneWidget);
    });

    testWidgets('hides the retrain button without a callback', (tester) async {
      await _pumpPage(tester, models: [active, retired], activeModel: active);
      expect(find.text('Reentrenar ahora'), findsNothing);
    });

    testWidgets('shows the empty production and feature cards', (tester) async {
      await _pumpPage(
        tester,
        models: [
          _model('v2', ModelStatus.CANDIDATE, trainedAt: kTestNow),
          retired,
        ],
        activeModel: null,
        onRetrain: () {},
      );
      expect(find.text('Sin modelo activo'), findsNWidgets(2));
      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text('Reentrena para tener una versión en producción.'),
        findsOneWidget,
      );
      expect(find.textContaining('vs. anterior'), findsNothing);
      expect(find.byType(FeatureBar), findsNothing);
      expect(find.byType(MetricTile), findsNothing);
    });

    testWidgets('places the threshold ticks at their positions', (
      tester,
    ) async {
      // No active model, so "0,60" and "0,90" are only the ticks.
      await _pumpPage(tester, models: [retired], activeModel: null);
      final left = tester.getTopLeft(find.text('0')).dx;
      final width = tester.getTopRight(find.text('1')).dx - left;
      for (final (text, fraction) in [('0,60', 0.6), ('0,90', 0.9)]) {
        final tick = find.text(text);
        expect(
          tester.getCenter(tick).dx,
          closeTo(left + width * fraction, tester.getSize(tick).width / 2),
          reason: text,
        );
      }
    });

    testWidgets('shows a dash without an earlier retired version', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        models: [
          _model('v4', ModelStatus.RETIRED, trainedAt: kTestNow),
          active,
        ],
        activeModel: active,
      );
      expect(find.text('—'), findsNWidgets(4));
    });
  });
}
