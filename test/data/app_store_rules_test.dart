import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/domain_error.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _laura = 'laura.mendez@monedasegura.co';
const _diego = 'diego.salazar@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';

const _unknownId = '00000000-0000-4000-8000-000000000000';
const _nightCondition = Condition('is_night', ConditionOp.eq, true);

final _now = DateTime(2026, 10, 25, 9, 45);

AppStore _storeAs(String? email) {
  final store = AppStore.seeded(clock: () => _now);
  if (email != null) store.signIn(email, MockSeed.demoPassword);
  return store;
}

void _signInAs(AppStore store, String email) =>
    store.signIn(email, MockSeed.demoPassword);

Matcher _throwsDomainError(String code) =>
    throwsA(isA<DomainError>().having((error) => error.code, 'code', code));

RuleView _rule(AppStore store, String code) => store.ruleByCode(code)!;

String _ruleId(AppStore store, String code) => _rule(store, code).rule.id;

RuleView _createNightAtm(AppStore store) => store.createRule(
  code: 'NIGHT_ATM',
  name: 'Retiro nocturno',
  conditions: const [_nightCondition],
  action: RuleAction.REVIEW,
);

void _createWith(AppStore store, Condition condition) => store.createRule(
  code: 'NEW_RULE',
  name: 'Regla nueva',
  conditions: [condition],
  action: RuleAction.REVIEW,
);

String _sofia(AppStore store) => store.customers
    .firstWhere((customer) => customer.maskedName == 'Sofía V.')
    .id;

List<SimulationEvent> _simulate(
  AppStore store,
  Scenario scenario, {
  int runNumber = 18,
  int count = 30,
}) => [
  for (var index = 0; index < count; index++)
    store.simulateOne(
      scenario: scenario,
      customerId: _sofia(store),
      runNumber: runNumber,
      index: index,
    ),
];

int _bucketTotal(HourBucket bucket) =>
    bucket.approve + bucket.review + bucket.block;

void main() {
  group('createRule', () {
    test('adds a 9th rule with v1 DRAFT created by the current user', () {
      final store = _storeAs(_laura);

      final created = _createNightAtm(store);

      expect(store.rules, hasLength(9));
      expect(store.rules.last.rule.code, 'NIGHT_ATM');
      expect(store.rules.last.rule.id, created.rule.id);
      expect(store.ruleById(created.rule.id)?.rule.name, 'Retiro nocturno');
      final version = created.latest;
      expect(version.version, 1);
      expect(version.status, RuleStatus.DRAFT);
      expect(version.createdBy.fullName, 'Laura Méndez');
      expect(version.createdAt, _now);
    });

    test('refuses a bad code, a taken code and an unknown feature', () {
      final store = _storeAs(_laura);

      expect(
        () => store.createRule(
          code: 'night',
          name: 'Regla',
          conditions: const [_nightCondition],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('invalid'),
      );
      expect(
        () => store.createRule(
          code: 'SCORE_BLOCK',
          name: 'Regla',
          conditions: const [_nightCondition],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('conflict'),
      );
      expect(
        () => _createWith(store, const Condition('type', ConditionOp.eq, 'x')),
        _throwsDomainError('invalid'),
      );
    });

    test('a taken code gives conflict before any other input is checked', () {
      final store = _storeAs(_laura);

      expect(
        () => store.createRule(
          code: 'SCORE_BLOCK',
          name: '',
          conditions: const [],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('conflict'),
      );
    });

    test('rules cannot be changed from outside the store', () {
      final store = _storeAs(_laura);

      expect(() => store.rules.clear(), throwsUnsupportedError);
    });
  });

  group('condition validation', () {
    for (final (description, condition) in const [
      ('an order on a boolean', Condition('is_night', ConditionOp.gt, true)),
      ('in on a number', Condition('amount', ConditionOp.inList, ['a'])),
      ('a string for a number', Condition('amount', ConditionOp.gte, 'x')),
      (
        'a plain string for in',
        Condition('category', ConditionOp.inList, 'grocery_pos'),
      ),
      ('a list for =', Condition('category', ConditionOp.eq, ['grocery_pos'])),
      ('a number for a boolean', Condition('is_night', ConditionOp.eq, 1)),
    ]) {
      test('refuses $description', () {
        final store = _storeAs(_laura);

        expect(
          () => _createWith(store, condition),
          _throwsDomainError('invalid'),
        );
      });
    }

    test('refuses an empty conditions list and a 121-character name', () {
      final store = _storeAs(_laura);

      expect(
        () => store.createRule(
          code: 'NEW_RULE',
          name: 'Regla',
          conditions: const [],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('invalid'),
      );
      expect(
        () => store.createRule(
          code: 'NEW_RULE',
          name: 'a' * 121,
          conditions: const [_nightCondition],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('invalid'),
      );
    });

    test('accepts in on a string and a number on score', () {
      final store = _storeAs(_laura);

      store.createRule(
        code: 'IN_CATEGORY',
        name: 'Categoría',
        conditions: const [
          Condition('category', ConditionOp.inList, ['grocery_pos']),
        ],
        action: RuleAction.REVIEW,
      );
      store.createRule(
        code: 'ON_SCORE',
        name: 'Score',
        conditions: const [Condition('score', ConditionOp.gte, 0.5)],
        action: RuleAction.REVIEW,
      );

      expect(store.rules, hasLength(10));
    });
  });

  group('updateDraft', () {
    test('changes the conditions and clears a previous backtest', () {
      final store = _storeAs(_laura);
      final id = _createNightAtm(store).rule.id;
      store.runBacktest(id, 1);
      expect(store.ruleById(id)!.latest.backtest, isNotNull);

      store.updateDraft(
        id,
        1,
        conditions: const [Condition('amount', ConditionOp.gte, 100)],
        action: RuleAction.BLOCK,
      );

      final version = store.ruleById(id)!.latest;
      expect(version.conditions.single.feature, 'amount');
      expect(version.action, RuleAction.BLOCK);
      expect(version.backtest, isNull);
    });

    test('refuses an ACTIVE version', () {
      final store = _storeAs(_laura);

      expect(
        () => store.updateDraft(
          _ruleId(store, 'SCORE_BLOCK'),
          2,
          conditions: const [_nightCondition],
          action: RuleAction.BLOCK,
        ),
        _throwsDomainError('conflict'),
      );
    });

    test('an unknown version gives not_found', () {
      final store = _storeAs(_laura);

      expect(
        () => store.updateDraft(
          _ruleId(store, 'SCORE_BLOCK'),
          99,
          conditions: const [_nightCondition],
          action: RuleAction.BLOCK,
        ),
        _throwsDomainError('not_found'),
      );
    });
  });

  group('deleteDraft', () {
    test('removes the rule with its only version', () {
      final store = _storeAs(_laura);
      final id = _createNightAtm(store).rule.id;

      store.deleteDraft(id, 1);

      expect(store.rules, hasLength(8));
      expect(store.ruleByCode('NIGHT_ATM'), isNull);
    });

    test('refuses an ACTIVE version', () {
      final store = _storeAs(_laura);

      expect(
        () => store.deleteDraft(_ruleId(store, 'SCORE_BLOCK'), 2),
        _throwsDomainError('conflict'),
      );
    });

    test('removes only the new version of a rule with others', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      store.deleteDraft(id, 5);

      final view = store.ruleById(id)!;
      expect(view.versions, hasLength(4));
      expect(view.version(5), isNull);
      expect(view.active?.version, 4);
    });
  });

  group('createVersion', () {
    test('creates v5 DRAFT at the front, copying only the rule', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');

      final created = store.createVersion(id);

      expect(created.version, 5);
      expect(created.status, RuleStatus.DRAFT);
      expect(store.ruleById(id)!.versions.first, same(created));
      final condition = created.conditions.single;
      expect(condition.feature, 'score');
      expect(condition.op, ConditionOp.gte);
      expect(condition.value, 0.6);
      expect(created.action, RuleAction.REVIEW);
      expect(created.createdBy.fullName, 'Laura Méndez');
      expect(created.createdAt, _now);
      expect(created.backtest, isNull);
      expect(created.shadowStats, isNull);
      expect(created.hits7d, isNull);
      expect(created.approvedBy, isNull);
    });

    test('refuses a second open version', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      expect(() => store.createVersion(id), _throwsDomainError('conflict'));
    });
  });

  group('lifecycle', () {
    test('goes from draft to active with two people', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      expect(
        () => store.submitForApproval(id, 5),
        _throwsDomainError('conflict'),
      );

      store.startShadow(id, 5);
      final shadow = store.ruleById(id)!.version(5)!;
      expect(shadow.status, RuleStatus.SHADOW);
      expect(shadow.shadowStats?.since, _now);
      expect(shadow.shadowStats?.evaluated, 0);

      store.runBacktest(id, 5);
      store.submitForApproval(id, 5);

      final pending = store.ruleById(id)!.version(5)!;
      expect(pending.status, RuleStatus.PENDING_APPROVAL);
      expect(pending.submittedAt, _now);

      expect(() => store.approve(id, 5), _throwsDomainError('forbidden'));
      expect(store.canApprove(pending), isFalse);

      _signInAs(store, _diego);
      expect(store.canApprove(pending), isTrue);

      store.approve(id, 5);

      final view = store.ruleById(id)!;
      final approved = view.version(5)!;
      expect(approved.status, RuleStatus.ACTIVE);
      expect(approved.approvedBy?.fullName, 'Diego Salazar');
      expect(approved.approvedAt, _now);
      expect(view.version(4)!.status, RuleStatus.RETIRED);
      expect(view.active?.version, 5);
    });

    test('submitting in SHADOW without a backtest gives conflict', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);
      store.startShadow(id, 5);

      expect(
        () => store.submitForApproval(id, 5),
        _throwsDomainError('conflict'),
      );
    });

    test('the state check comes before the approver check', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      expect(() => store.approve(id, 5), _throwsDomainError('conflict'));
    });
  });

  group('runBacktest', () {
    test('gives the formula numbers on SCORE_REVIEW v5', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      final backtest = store.runBacktest(id, 5);

      expect(backtest.runAt, _now);
      expect(backtest.casesEvaluated, 1920);
      expect(backtest.candidate.truePositives, 26);
      expect(backtest.candidate.falsePositives, 45);
      expect(backtest.candidate.falseNegatives, 37);
      expect(backtest.candidate.trueNegatives, 1812);
      expect(backtest.active?.truePositives, 41);
      expect(backtest.systemRecallBefore, 0.74);
      expect(backtest.systemRecallAfter, 0.73);
      expect(store.ruleById(id)!.version(5)!.backtest, same(backtest));
    });

    test('running it twice gives equal counts', () {
      final store = _storeAs(_laura);
      final id = _ruleId(store, 'SCORE_REVIEW');
      store.createVersion(id);

      final first = store.runBacktest(id, 5).candidate;
      final second = store.runBacktest(id, 5).candidate;

      expect(second.truePositives, first.truePositives);
      expect(second.falsePositives, first.falsePositives);
      expect(second.falseNegatives, first.falseNegatives);
      expect(second.trueNegatives, first.trueNegatives);
    });

    test('a rule with no ACTIVE version keeps the recall', () {
      final store = _storeAs(_laura);
      final id = _createNightAtm(store).rule.id;

      final backtest = store.runBacktest(id, 1);

      expect(backtest.active, isNull);
      expect(backtest.systemRecallAfter, 0.74);
    });

    test('refuses an ACTIVE version', () {
      final store = _storeAs(_laura);

      expect(
        () => store.runBacktest(_ruleId(store, 'SCORE_BLOCK'), 2),
        _throwsDomainError('conflict'),
      );
    });
  });

  group('reject', () {
    test('returns the version to DRAFT with the reason', () {
      final store = _storeAs(_valentina);
      final id = _ruleId(store, 'NIGHT_TRANSFER');

      store.reject(id, 2, 'Falta evidencia');

      final version = store.ruleById(id)!.version(2)!;
      expect(version.status, RuleStatus.DRAFT);
      expect(version.rejectionReason, 'Falta evidencia');
      expect(version.submittedAt, isNull);
      expect(version.shadowStats, isNull);
      expect(version.backtest, isNotNull);
    });

    test('refuses an empty reason and one of 1001 characters', () {
      final store = _storeAs(_valentina);
      final id = _ruleId(store, 'NIGHT_TRANSFER');

      expect(() => store.reject(id, 2, ''), _throwsDomainError('invalid'));
      expect(
        () => store.reject(id, 2, 'a' * 1001),
        _throwsDomainError('invalid'),
      );
      expect(
        store.ruleById(id)!.version(2)!.status,
        RuleStatus.PENDING_APPROVAL,
      );
    });

    test('a rejected draft cannot be deleted but can be resubmitted', () {
      final store = _storeAs(_valentina);
      final id = _ruleId(store, 'NIGHT_TRANSFER');
      store.reject(id, 2, 'Falta evidencia');

      expect(() => store.deleteDraft(id, 2), _throwsDomainError('conflict'));
      expect(store.ruleById(id)!.version(2), isNotNull);

      store.updateDraft(
        id,
        2,
        conditions: const [_nightCondition],
        action: RuleAction.REVIEW,
      );
      store.startShadow(id, 2);
      store.runBacktest(id, 2);
      store.submitForApproval(id, 2);

      final version = store.ruleById(id)!.version(2)!;
      expect(version.status, RuleStatus.PENDING_APPROVAL);
      expect(version.rejectionReason, 'Falta evidencia');
    });
  });

  group('permissions', () {
    for (final (who, email) in const [
      ('Camilo Torres', _camilo),
      ('signed out', null),
    ]) {
      test('$who gets forbidden, even with an unknown id', () {
        final store = _storeAs(email);
        final forbidden = _throwsDomainError('forbidden');

        expect(() => _createNightAtm(store), forbidden);
        expect(() => store.createVersion(_unknownId), forbidden);
        expect(
          () => store.updateDraft(
            _unknownId,
            1,
            conditions: const [_nightCondition],
            action: RuleAction.REVIEW,
          ),
          forbidden,
        );
        expect(() => store.deleteDraft(_unknownId, 1), forbidden);
        expect(() => store.startShadow(_unknownId, 1), forbidden);
        expect(() => store.runBacktest(_unknownId, 1), forbidden);
        expect(() => store.submitForApproval(_unknownId, 1), forbidden);
        expect(() => store.approve(_unknownId, 1), forbidden);
        expect(() => store.reject(_unknownId, 1, 'Motivo'), forbidden);
        expect(() => store.startRun(), forbidden);
        expect(() => store.createOriginationCustomer(), forbidden);
        expect(
          () => store.simulateOne(
            scenario: Scenario.ATO,
            customerId: _unknownId,
            runNumber: 18,
            index: 0,
          ),
          forbidden,
        );
      });
    }

    test('an unknown rule id on updateDraft gives not_found', () {
      final store = _storeAs(_laura);

      expect(
        () => store.updateDraft(
          _unknownId,
          1,
          conditions: const [_nightCondition],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('not_found'),
      );
    });
  });

  group('notifications', () {
    test('a successful operation notifies once, a failed one never', () {
      final store = _storeAs(_valentina);
      var calls = 0;
      store.addListener(() => calls++);

      expect(
        () => store.createRule(
          code: 'SCORE_BLOCK',
          name: 'Regla',
          conditions: const [_nightCondition],
          action: RuleAction.REVIEW,
        ),
        _throwsDomainError('conflict'),
      );
      expect(calls, 0);
      expect(store.rules, hasLength(8));

      _createNightAtm(store);
      expect(calls, 1);

      store.simulateOne(
        scenario: Scenario.ATO,
        customerId: _sofia(store),
        runNumber: 18,
        index: 0,
      );
      expect(calls, 2);
    });
  });

  group('approvers and thresholds', () {
    test('approversFor returns the other users who can approve', () {
      final store = _storeAs(_valentina);
      final version = _rule(store, 'NIGHT_TRANSFER').version(2)!;

      expect(store.approversFor(version).map((user) => user.fullName), [
        'Valentina Ríos',
        'Diego Salazar',
      ]);
    });

    test('scoreThresholds reads the active score rules', () {
      final thresholds = _storeAs(null).scoreThresholds;

      expect(thresholds.review, 0.6);
      expect(thresholds.block, 0.9);
    });
  });

  group('evaluate', () {
    const features = <String, Object>{'km_from_home': 400.0};

    ShadowStats farFromHome(AppStore store) =>
        _rule(store, 'FAR_FROM_HOME').version(1)!.shadowStats!;

    test('records every version and counts a verdict change', () {
      final store = _storeAs(null);
      final hits = <RuleHit>[];

      final verdict = store.evaluate(features, 0.1, hits);

      expect(verdict, Verdict.APPROVE);
      expect(hits.map((hit) => '${hit.ruleCode} v${hit.version}'), [
        'SCORE_BLOCK v2',
        'SCORE_REVIEW v4',
        'HIGH_AMOUNT_NEW_DEVICE v3',
        'VELOCITY_1H v1',
        'FAR_FROM_HOME v1',
        'NIGHT_TRANSFER v1',
      ]);
      final shadow = hits.where((hit) => hit.shadow).single;
      expect(shadow.ruleCode, 'FAR_FROM_HOME');
      expect(shadow.matched, isTrue);
      final stats = farFromHome(store);
      expect(stats.evaluated, 9801);
      expect(stats.matched, 1103);
      expect(stats.verdictChanges, 15);
    });

    test('a shadow match at the active verdict changes nothing', () {
      final store = _storeAs(null);

      expect(store.evaluate(features, 0.7, []), Verdict.REVIEW);

      expect(farFromHome(store).evaluated, 9801);
      expect(farFromHome(store).matched, 1103);
      expect(farFromHome(store).verdictChanges, 14);
    });

    test('a high score blocks', () {
      expect(_storeAs(null).evaluate(features, 0.95, []), Verdict.BLOCK);
    });

    test('rules on score do not match a null score', () {
      final hits = <RuleHit>[];

      _storeAs(null).evaluate(features, null, hits);

      for (final code in ['SCORE_BLOCK', 'SCORE_REVIEW']) {
        expect(hits.firstWhere((hit) => hit.ruleCode == code).matched, isFalse);
      }
    });

    test('does not notify', () {
      final store = _storeAs(null);
      var calls = 0;
      store.addListener(() => calls++);

      store.evaluate(features, 0.1, []);

      expect(calls, 0);
    });
  });

  group('runs and origination customers', () {
    test('startRun returns the next number', () {
      final store = _storeAs(_valentina);

      expect(store.nextRunNumber, 18);
      expect(store.startRun(), 18);
      expect(store.nextRunNumber, 19);
    });

    test('createOriginationCustomer adds a customer of the run', () {
      final store = _storeAs(_valentina);
      final before = store.customers.length;
      store.startRun();

      final customer = store.createOriginationCustomer();

      expect(store.customers, hasLength(before + 1));
      expect(store.customerById(customer.id), same(customer));
      expect(customer.maskedName, 'Cliente nuevo 18.');
      expect(customer.maskedDocument, '****0018');
      expect(customer.homeCity, 'Bogotá');
      expect(customer.createdAt, _now);
      expect(customer.transactions30d, 0);
      expect(customer.previousFrauds, 0);
    });

    test('a simulated origination customer can be used right away', () {
      final store = _storeAs(_valentina);
      store.startRun();
      final customer = store.createOriginationCustomer();

      final event = store.simulateOne(
        scenario: Scenario.ORIGINATION,
        customerId: customer.id,
        runNumber: 18,
        index: 0,
      );

      expect(event.customer, same(customer));
      expect(event.transaction.customerId, customer.id);
    });
  });

  group('simulateOne', () {
    test('20 ATO events open 7 cases and update the metrics', () {
      final store = _storeAs(_valentina);
      final before = store.metrics;
      final openBefore = store.openCases.length;

      final events = _simulate(store, Scenario.ATO, count: 20);

      expect(events, hasLength(20));
      final flagged = [
        for (var index = 0; index < 20; index++)
          if (events[index].decision.verdict != Verdict.APPROVE) index,
      ];
      expect(flagged, [0, 3, 6, 9, 12, 15, 18]);
      expect(store.openCases, hasLength(openBefore + 7));
      for (final index in flagged) {
        final caseId = events[index].decision.caseId!;
        final view = store.caseById(caseId)!;
        expect(store.openCases, contains(view));
        expect(view.id, caseId);
        expect(view.status, CaseStatus.OPEN);
        expect(view.assignedTo, isNull);
      }

      int count(Verdict verdict) =>
          events.where((event) => event.decision.verdict == verdict).length;
      final after = store.metrics;
      expect(after.decisions, before.decisions + 20);
      for (final verdict in Verdict.values) {
        expect(
          after.verdicts[verdict],
          before.verdicts[verdict]! + count(verdict),
        );
      }
      expect(
        after.hourly[9].approve,
        before.hourly[9].approve + count(Verdict.APPROVE),
      );
      expect(
        after.hourly[9].review,
        before.hourly[9].review + count(Verdict.REVIEW),
      );
      expect(
        after.hourly[9].block,
        before.hourly[9].block + count(Verdict.BLOCK),
      );
      expect(_bucketTotal(after.hourly[10]), _bucketTotal(before.hourly[10]));
      expect(after.openCases, before.openCases);
    });

    test('re-running gives the same verdicts and new unique ids', () {
      final store = _storeAs(_valentina);

      final first = _simulate(store, Scenario.ATO, count: 20);
      final second = _simulate(store, Scenario.ATO, count: 20);

      expect(
        second.map((event) => event.decision.verdict),
        first.map((event) => event.decision.verdict),
      );
      final all = [...first, ...second];
      expect(all.map((event) => event.transaction.id).toSet(), hasLength(40));
      expect(all.map((event) => event.decision.id).toSet(), hasLength(40));
      expect(
        all.map((event) => event.transaction.deviceId).toSet(),
        hasLength(40),
      );
      final caseIds = all
          .map((event) => event.decision.caseId)
          .nonNulls
          .toList();
      expect(caseIds, hasLength(14));
      expect(caseIds.toSet(), hasLength(14));
      final shortIds = store.openCases.map((view) => view.shortId).toList();
      expect(shortIds.toSet(), hasLength(shortIds.length));
    });

    test('checks the permission, then the customer, then the scenario', () {
      final camilo = _storeAs(_camilo);
      expect(
        () => camilo.simulateOne(
          scenario: Scenario.ATO,
          customerId: _sofia(camilo),
          runNumber: 18,
          index: 0,
        ),
        _throwsDomainError('forbidden'),
      );

      final store = _storeAs(_valentina);
      expect(
        () => store.simulateOne(
          scenario: Scenario.DATASET_FRAUD,
          customerId: _unknownId,
          runNumber: 18,
          index: 0,
        ),
        _throwsDomainError('not_found'),
      );
      expect(
        () => store.simulateOne(
          scenario: Scenario.DATASET_FRAUD,
          customerId: _sofia(store),
          runNumber: 18,
          index: 0,
        ),
        _throwsDomainError('invalid'),
      );
    });

    test('20 events count on the shadow rule', () {
      final store = _storeAs(_valentina);

      _simulate(store, Scenario.ATO, count: 20);

      final stats = _rule(store, 'FAR_FROM_HOME').version(1)!.shadowStats!;
      expect(stats.evaluated, 9820);
    });

    test('builds the decision and the records as specified', () {
      final store = _storeAs(_valentina);

      for (final event in _simulate(store, Scenario.ATO)) {
        final decision = event.decision;
        expect(decision.kind, DecisionKind.ORIGINAL);
        expect(decision.degraded, isFalse);
        expect(decision.modelVersion, store.activeModel?.version);
        expect(decision.latencyMs, inInclusiveRange(80, 160));
        expect(decision.decidedAt, _now);
        expect(decision.transactionId, event.transaction.id);
        expect(decision.ruleHits, hasLength(6));
        final score = decision.score!;
        expect(score, (score * 100).round() / 100);
        expect(event.transaction.occurredAt, _now);
        // Sofía V. lives in Pereira.
        final home = MockSeed.homeCoordinates['Pereira']!;
        final km = decision.features['km_from_home'] as num;
        expect(event.transaction.latitude, home.$1 - km / 111);
        expect(event.transaction.longitude, home.$2);
        final counterparty = event.transaction.counterparty;
        if (event.transaction.type == TransactionType.TRANSFER) {
          expect(counterparty, matches(RegExp(r'^\*{4}\d{4}$')));
        } else {
          expect(counterparty, isNull);
        }
      }
    });
  });

  group('profiles', () {
    final featureNames = {
      for (final feature in featureCatalog)
        if (feature.name != 'score') feature.name,
    };

    List<SimulationEvent> run(Scenario scenario) {
      final events = _simulate(_storeAs(_valentina), scenario);
      for (final event in events) {
        expect(event.decision.features.keys.toSet(), featureNames);
        expect(event.transaction.source, TransactionSource.SIMULATOR);
        expect(event.transaction.scenario, scenario);
      }
      return events;
    }

    test('NORMAL', () {
      for (final event in run(Scenario.NORMAL)) {
        final transaction = event.transaction;
        final features = event.decision.features;
        expect(transaction.type, TransactionType.DEBIT);
        expect(
          transaction.category,
          isIn(['grocery_pos', 'gas_transport', 'food_dining']),
        );
        expect(transaction.amount, inInclusiveRange(20000, 600000));
        expect(event.decision.score, inInclusiveRange(0.02, 0.35));
        expect(features['is_night'], isFalse);
        expect(features['is_new_device'], isFalse);
        expect(features['km_from_home'] as num, inInclusiveRange(0, 15));
        expect(event.decision.verdict, Verdict.APPROVE);
        expect(event.decision.caseId, isNull);
      }
    });

    test('CARD_FRAUD', () {
      for (final event in run(Scenario.CARD_FRAUD)) {
        final transaction = event.transaction;
        final features = event.decision.features;
        expect(transaction.type, TransactionType.DEBIT);
        expect(transaction.category, 'shopping_net');
        expect(transaction.amount, inInclusiveRange(800000, 6000000));
        expect(event.decision.score, inInclusiveRange(0.55, 0.98));
        expect(features['is_night'], isTrue);
        expect(features['is_new_device'], isTrue);
        expect(features['tx_count_5m'] as num, inInclusiveRange(2, 6));
        expect(features['amount_vs_avg_30d'] as num, inInclusiveRange(3, 9));
      }
    });

    test('ATO', () {
      final events = run(Scenario.ATO);
      for (var index = 0; index < events.length; index++) {
        final event = events[index];
        final transaction = event.transaction;
        final features = event.decision.features;
        if (index % 3 == 0) {
          expect(transaction.type, TransactionType.TRANSFER);
          expect(transaction.category, isNull);
          expect(features['category'], 'unknown');
          expect(transaction.amount, inInclusiveRange(2000000, 7000000));
          expect(event.decision.score, inInclusiveRange(0.62, 0.97));
          expect(features['is_new_device'], isTrue);
          expect(features['password_changed_24h'], isTrue);
          expect(features['failed_logins_1h'] as num, inInclusiveRange(3, 6));
          expect(features['km_from_home'] as num, inInclusiveRange(250, 600));
        } else {
          expect(transaction.type, TransactionType.DEBIT);
          expect(transaction.category, 'grocery_pos');
          expect(features['category'], 'grocery_pos');
          expect(transaction.amount, inInclusiveRange(40000, 1200000));
          expect(event.decision.score, inInclusiveRange(0.05, 0.4));
        }
      }
    });

    test('ORIGINATION', () {
      for (final event in run(Scenario.ORIGINATION)) {
        final transaction = event.transaction;
        final features = event.decision.features;
        expect(transaction.type, TransactionType.TRANSFER);
        expect(transaction.amount, inInclusiveRange(500000, 4000000));
        expect(event.decision.score, inInclusiveRange(0.4, 0.9));
        expect(features['account_age_days'], 0);
        expect(features['is_new_device'], isTrue);
      }
    });

    test('derives the time and customer features', () {
      final features = _simulate(
        _storeAs(_valentina),
        Scenario.ATO,
        count: 2,
      )[1].decision.features;

      expect(features['hour_of_day'], 9);
      expect(features['is_night'], isFalse);
      expect(features['amount_vs_avg_30d'], 1.0);
      expect(features['minutes_since_prev'], 10080);
      expect(features['customers_on_device'], 1);
      // Sofía V. was created on 2023-10-25.
      expect(
        features['account_age_days'],
        _now.difference(DateTime(2023, 10, 25)).inDays,
      );
    });
  });
}
