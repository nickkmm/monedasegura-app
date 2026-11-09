import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/format.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';

const _exceptionCase = '#09F35B';
const _detailCase = '#B204E7';

/// An independent evaluation of a version's conditions (`model.md` §5).
bool _evaluates(RuleVersion version, Map<String, Object> features, double? s) {
  return version.conditions.every((condition) {
    final actual = condition.feature == 'score'
        ? s
        : features[condition.feature];
    if (actual == null) return false;
    final expected = condition.value;
    switch (condition.op) {
      case ConditionOp.gt:
        return (actual as num) > (expected as num);
      case ConditionOp.gte:
        return (actual as num) >= (expected as num);
      case ConditionOp.lt:
        return (actual as num) < (expected as num);
      case ConditionOp.lte:
        return (actual as num) <= (expected as num);
      case ConditionOp.eq:
        return actual == expected;
      case ConditionOp.neq:
        return actual != expected;
      case ConditionOp.inList:
        return (expected as List).contains(actual);
    }
  });
}

Verdict _mostSevere(Decision decision) {
  final matched = decision.ruleHits.where((h) => h.matched && !h.shadow);
  if (matched.any((h) => h.action == RuleAction.BLOCK)) return Verdict.BLOCK;
  if (matched.any((h) => h.action == RuleAction.REVIEW)) return Verdict.REVIEW;
  return Verdict.APPROVE;
}

/// Every timestamp in the seed except customer `createdAt`, which is fixed.
List<DateTime> _allTimes(MockSeed seed) {
  return [
    for (final t in seed.transactions) t.occurredAt,
    for (final d in seed.decisions) d.decidedAt,
    for (final d in seed.devices) d.firstSeenAt,
    for (final c in seed.cases) ...[
      c.openedAt,
      if (c.resolvedAt != null) c.resolvedAt!,
    ],
    for (final view in seed.rules) ...[
      view.rule.createdAt,
      for (final v in view.versions) ...[
        v.createdAt,
        if (v.approvedAt != null) v.approvedAt!,
        if (v.submittedAt != null) v.submittedAt!,
        if (v.shadowStats != null) v.shadowStats!.since,
        if (v.backtest != null) v.backtest!.runAt,
      ],
    ],
    for (final m in seed.models) m.trainedAt,
    seed.metrics.from,
    seed.metrics.to,
  ];
}

void main() {
  final now = DateTime(2026, 10, 25, 9, 45);
  final seed = MockSeed.build(now);

  CaseView caseOf(String shortId) =>
      seed.cases.firstWhere((c) => c.shortId == shortId);
  RuleView ruleOf(String code) =>
      seed.rules.firstWhere((r) => r.rule.code == code);
  ModelVersion modelOf(String version) =>
      seed.models.firstWhere((m) => m.version == version);

  group('users', () {
    test('match the issue, active and with their roles', () {
      expect(seed.users.map((u) => (u.fullName, u.email, u.roles.single)), [
        ('Valentina Ríos', 'valentina.rios@monedasegura.co', RoleCode.ADMIN),
        ('Laura Méndez', 'laura.mendez@monedasegura.co', RoleCode.RISK_LEAD),
        ('Diego Salazar', 'diego.salazar@monedasegura.co', RoleCode.RISK_LEAD),
        ('Camilo Torres', 'camilo.torres@monedasegura.co', RoleCode.ANALYST),
        (
          'Laura Cárdenas',
          'laura.cardenas@monedasegura.co',
          RoleCode.DATA_SCIENTIST,
        ),
        ('Mateo Rojas', 'mateo.rojas@monedasegura.co', RoleCode.AUDITOR),
      ]);
      expect(seed.users.every((u) => u.active), isTrue);
    });
  });

  group('cases', () {
    test('12 of each record, with 9 open or in review and 3 resolved', () {
      expect(seed.transactions, hasLength(12));
      expect(seed.decisions, hasLength(12));
      expect(seed.cases, hasLength(12));
      expect(
        seed.cases.where((c) => c.status != CaseStatus.RESOLVED),
        hasLength(9),
      );
      expect(
        seed.cases.where((c) => c.status == CaseStatus.RESOLVED),
        hasLength(3),
      );
    });

    test('follow the order of the issue tables', () {
      expect(seed.cases.map((c) => c.shortId), [
        '#7F0B6A',
        '#3A91C2',
        '#B204E7',
        '#5D7A13',
        '#E1C048',
        '#09F35B',
        '#C66A2F',
        '#4B8E90',
        '#A17D3C',
        '#D4E2F1',
        '#8C3B07',
        '#F09A5E',
      ]);
    });

    test('#B204E7 is the Figma detail screen', () {
      final view = caseOf(_detailCase);
      expect(view.verdict, Verdict.REVIEW);
      expect(view.score, 0.67);
      expect(view.customer.maskedName, 'Andrés P.');
      expect(view.transaction.counterparty, 'ElectroHogar Bogotá');
      expect(view.device.os, DeviceOs.ANDROID);
      expect(formatHm(view.device.firstSeenAt), '09:30');
      expect(view.decision.modelVersion, 'v5');
      expect(view.decision.latencyMs, 142);
      expect(view.decision.features, {
        'amount': 3250000,
        'amount_vs_avg_30d': 4.1,
        'is_new_device': true,
        'km_from_home': 412,
        'tx_count_1h': 3,
        'is_night': false,
      });
      expect(
        view.decision.ruleHits.map(
          (h) => (h.ruleCode, h.version, h.action, h.matched, h.shadow),
        ),
        [
          ('SCORE_REVIEW', 4, RuleAction.REVIEW, true, false),
          ('HIGH_AMOUNT_NEW_DEVICE', 3, RuleAction.REVIEW, true, false),
          ('VELOCITY_1H', 1, RuleAction.BLOCK, false, false),
          ('FAR_FROM_HOME', 1, RuleAction.REVIEW, true, true),
        ],
      );
    });

    test('only #3A91C2 and #C66A2F are assigned among open cases', () {
      final assigned = seed.cases.where(
        (c) => c.status != CaseStatus.RESOLVED && c.assignedTo != null,
      );
      expect(assigned.map((c) => c.shortId), ['#3A91C2', '#C66A2F']);
      expect(caseOf('#3A91C2').assignedTo!.fullName, 'Camilo Torres');
      expect(caseOf('#C66A2F').assignedTo!.fullName, 'Valentina Ríos');
    });

    test('resolved cases are Camilo\'s, labeled, in the last 3 h', () {
      final labels = {
        '#D4E2F1': CaseLabel.CONFIRMED_FRAUD,
        '#8C3B07': CaseLabel.DISMISSED,
        '#F09A5E': CaseLabel.CONFIRMED_FRAUD,
      };
      labels.forEach((shortId, label) {
        final view = caseOf(shortId);
        expect(view.status, CaseStatus.RESOLVED);
        expect(view.label, label);
        expect(view.assignedTo!.fullName, 'Camilo Torres');
        expect(now.difference(view.resolvedAt!).inHours, lessThan(3));
        expect(view.resolvedAt!.isAfter(view.openedAt), isTrue);
      });
    });

    test('ages read as in the issue', () {
      expect(formatAgo(caseOf('#7F0B6A').openedAt, now), 'hace 1 min');
      expect(formatAgo(caseOf('#B204E7').openedAt, now), 'hace 4 min');
      expect(formatAgo(caseOf('#A17D3C').openedAt, now), 'hace 34 min');
    });

    test('every REVIEW or BLOCK decision has one case, linked both ways', () {
      for (final decision in seed.decisions) {
        expect(decision.verdict, isNot(Verdict.APPROVE));
        final linked = seed.cases.where((c) => c.decision.id == decision.id);
        expect(linked, hasLength(1));
        expect(decision.caseId, linked.single.id);
        expect(linked.single.fraudCase.decisionId, decision.id);
      }
    });

    test('each view holds the objects of the other lists', () {
      for (final view in seed.cases) {
        expect(seed.transactions, contains(same(view.transaction)));
        expect(seed.decisions, contains(same(view.decision)));
        expect(seed.customers, contains(same(view.customer)));
        expect(seed.devices, contains(same(view.device)));
        expect(view.transaction.customerId, view.customer.id);
        expect(view.transaction.deviceId, view.device.id);
        expect(view.decision.transactionId, view.transaction.id);
      }
    });

    test('ids are lower-case UUIDs; case ids start with their short id', () {
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      );
      final ids = [
        ...seed.users.map((x) => x.id),
        ...seed.customers.map((x) => x.id),
        ...seed.devices.map((x) => x.id),
        ...seed.transactions.map((x) => x.id),
        ...seed.decisions.map((x) => x.id),
        ...seed.cases.map((x) => x.id),
        ...seed.rules.map((x) => x.rule.id),
        ...seed.models.map((x) => x.id),
      ];
      expect(ids.every(uuid.hasMatch), isTrue);
      expect(ids.toSet(), hasLength(ids.length));
      for (final view in seed.cases) {
        expect(view.id, startsWith(view.shortId.substring(1).toLowerCase()));
      }
    });

    test('transactions follow the scenario and counterparty rules', () {
      final deviceIds = seed.devices.map((d) => d.id).toSet();
      for (final tx in seed.transactions) {
        expect(tx.source, TransactionSource.SIMULATOR);
        expect(deviceIds, contains(tx.deviceId));
        if (tx.type == TransactionType.TRANSFER) {
          expect(tx.scenario, Scenario.ATO);
          expect(tx.category, isNull);
          expect(tx.counterparty, matches(r'^\*{4}\d{4}$'));
        } else if (tx.category == 'shopping_net') {
          expect(tx.scenario, Scenario.CARD_FRAUD);
        } else {
          expect(tx.scenario, Scenario.NORMAL);
        }
      }
    });
  });

  group('customers', () {
    test('there are 10, with only masked personal data', () {
      expect(seed.customers, hasLength(10));
      for (final customer in seed.customers) {
        expect(customer.maskedDocument, matches(r'^\*{4}\d{4}$'));
        expect(customer.maskedName, matches(r'^\S+ \S\.$'));
        expect(customer.transactions30d, inInclusiveRange(10, 60));
        expect(customer.createdAt.year, inInclusiveRange(2021, 2024));
      }
    });

    test('Andrés P. and Tomás H. match the issue', () {
      final andres = seed.customers.firstWhere(
        (c) => c.maskedName == 'Andrés P.',
      );
      expect(formatMonthYear(andres.createdAt), 'mar 2023');
      expect(andres.transactions30d, 41);
      expect(andres.previousFrauds, 0);
      final tomas = seed.customers.firstWhere(
        (c) => c.maskedName == 'Tomás H.',
      );
      expect(tomas.previousFrauds, 1);
    });
  });

  group('verdicts', () {
    test('every verdict but #09F35B is the most severe matched hit', () {
      for (final view in seed.cases) {
        if (view.shortId == _exceptionCase) continue;
        expect(_mostSevere(view.decision), view.verdict, reason: view.shortId);
      }
    });

    test('#09F35B is degraded, with no matched non-shadow hit', () {
      final view = caseOf(_exceptionCase);
      expect(view.amount, 2180000);
      expect(view.score, isNull);
      expect(view.degraded, isTrue);
      expect(view.decision.modelVersion, isNull);
      expect(view.verdict, Verdict.REVIEW);
      expect(_mostSevere(view.decision), Verdict.APPROVE);
    });

    test('every hit is the truthful evaluation of its version', () {
      for (final view in seed.cases) {
        for (final hit in view.decision.ruleHits) {
          final rule = ruleOf(hit.ruleCode);
          final version = rule.version(hit.version)!;
          expect(hit.ruleId, rule.rule.id);
          expect(hit.action, version.action);
          expect(hit.shadow, version.status == RuleStatus.SHADOW);
          expect(
            hit.matched,
            _evaluates(version, view.decision.features, view.score),
            reason: '${view.shortId} ${hit.ruleCode}',
          );
        }
      }
    });

    test('other cases have the six features and six hits, in order', () {
      for (final view in seed.cases) {
        if (view.shortId == _detailCase) continue;
        expect(view.decision.features.keys.toSet(), {
          'amount',
          'amount_vs_avg_30d',
          'is_new_device',
          'km_from_home',
          'tx_count_1h',
          'is_night',
        });
        expect(view.decision.features['amount'], view.amount);
        expect(view.decision.ruleHits.map((h) => (h.ruleCode, h.version)), [
          ('SCORE_BLOCK', 2),
          ('SCORE_REVIEW', 4),
          ('HIGH_AMOUNT_NEW_DEVICE', 3),
          ('VELOCITY_1H', 1),
          ('NIGHT_TRANSFER', 1),
          ('FAR_FROM_HOME', 1),
        ]);
        expect(view.decision.latencyMs, inInclusiveRange(60, 190));
        expect(view.decision.modelVersion, view.degraded ? isNull : 'v5');
      }
    });
  });

  group('rules', () {
    test('8 rules with their latest versions', () {
      expect(
        seed.rules.map(
          (r) => (
            r.rule.code,
            r.latest.version,
            r.latest.action,
            r.latest.status,
            r.latest.hits7d,
          ),
        ),
        [
          ('SCORE_BLOCK', 2, RuleAction.BLOCK, RuleStatus.ACTIVE, 312),
          ('SCORE_REVIEW', 4, RuleAction.REVIEW, RuleStatus.ACTIVE, 2410),
          (
            'HIGH_AMOUNT_NEW_DEVICE',
            3,
            RuleAction.REVIEW,
            RuleStatus.ACTIVE,
            486,
          ),
          ('VELOCITY_1H', 1, RuleAction.BLOCK, RuleStatus.ACTIVE, 97),
          ('FAR_FROM_HOME', 1, RuleAction.REVIEW, RuleStatus.SHADOW, 1102),
          (
            'NIGHT_TRANSFER',
            2,
            RuleAction.REVIEW,
            RuleStatus.PENDING_APPROVAL,
            61,
          ),
          ('ATO_PASSWORD_RESET', 1, RuleAction.BLOCK, RuleStatus.DRAFT, null),
          ('VELOCITY_5M', 5, RuleAction.BLOCK, RuleStatus.RETIRED, null),
        ],
      );
    });

    test('latest authors and ages match the issue table', () {
      const expected = {
        'SCORE_BLOCK': ('Laura Méndez', 'hace 9 d'),
        'SCORE_REVIEW': ('Laura Méndez', 'hace 3 d'),
        'HIGH_AMOUNT_NEW_DEVICE': ('Diego Salazar', 'hace 12 d'),
        'VELOCITY_1H': ('Diego Salazar', 'hace 20 d'),
        'FAR_FROM_HOME': ('Laura Méndez', 'ayer'),
        'NIGHT_TRANSFER': ('Laura Méndez', 'hace 3 d'),
        'ATO_PASSWORD_RESET': ('Diego Salazar', 'hoy'),
        'VELOCITY_5M': ('Laura Méndez', 'hace 2 meses'),
      };
      expected.forEach((code, row) {
        final latest = ruleOf(code).latest;
        expect(latest.createdBy.fullName, row.$1, reason: code);
        expect(formatDayAgo(latest.createdAt, now), row.$2, reason: code);
      });
    });

    test('at most one ACTIVE version per rule, and versions newest first', () {
      for (final view in seed.rules) {
        final active = view.versions.where(
          (v) => v.status == RuleStatus.ACTIVE,
        );
        expect(active.length, lessThanOrEqualTo(1));
        for (var i = 1; i < view.versions.length; i++) {
          final newer = view.versions[i - 1];
          final older = view.versions[i];
          expect(older.version, newer.version - 1);
          expect(older.createdAt.isBefore(newer.createdAt), isTrue);
          expect(older.hits7d, isNull);
          expect(older.status, isNot(RuleStatus.DRAFT));
        }
        expect(
          view.rule.createdAt.isAfter(view.versions.last.createdAt),
          isFalse,
        );
      }
    });

    test('every condition feature is in the catalog', () {
      final names = featureCatalog.map((f) => f.name).toSet();
      for (final view in seed.rules) {
        for (final version in view.versions) {
          for (final condition in version.conditions) {
            expect(names, contains(condition.feature));
          }
        }
      }
    });

    test(
      'approvers can approve, differ from the creator, and only when due',
      () {
        for (final view in seed.rules) {
          for (final version in view.versions) {
            final needsApprover =
                version.status == RuleStatus.ACTIVE ||
                version.status == RuleStatus.RETIRED;
            if (!needsApprover) {
              expect(version.approvedBy, isNull);
              expect(version.approvedAt, isNull);
              continue;
            }
            expect(version.approvedAt, isNotNull);
            expect(version.approvedBy!.id, isNot(version.createdBy.id));
            final approver = seed.users.firstWhere(
              (u) => u.id == version.approvedBy!.id,
            );
            expect(approver.can(PermissionCode.RULE_APPROVE), isTrue);
          }
        }
        final v1 = ruleOf('NIGHT_TRANSFER').version(1)!;
        expect(v1.createdBy.fullName, 'Laura Méndez');
        expect(v1.approvedBy!.fullName, 'Diego Salazar');
      },
    );

    test('backtests sum to the evaluated cases and use the issue numbers', () {
      const expected = {
        ('SCORE_BLOCK', 2): (88, 12),
        ('SCORE_REVIEW', 4): (41, 59),
        ('HIGH_AMOUNT_NEW_DEVICE', 3): (57, 43),
        ('VELOCITY_1H', 1): (74, 26),
        ('FAR_FROM_HOME', 1): (33, 67),
        ('NIGHT_TRANSFER', 2): (41, 38),
        ('NIGHT_TRANSFER', 1): (32, 9),
      };
      for (final view in seed.rules) {
        for (final version in view.versions) {
          final numbers = expected[(view.rule.code, version.version)];
          if (numbers == null) {
            expect(version.backtest, isNull);
            continue;
          }
          final backtest = version.backtest!;
          final counts = backtest.candidate;
          expect(backtest.casesEvaluated, 1920);
          expect(counts.truePositives, numbers.$1);
          expect(counts.falsePositives, numbers.$2);
          expect(
            counts.truePositives +
                counts.falsePositives +
                counts.falseNegatives +
                counts.trueNegatives,
            backtest.casesEvaluated,
          );
          final isNightV2 =
              view.rule.code == 'NIGHT_TRANSFER' && version.version == 2;
          expect(backtest.active != null, isNightV2);
          expect(backtest.systemRecallBefore != null, isNightV2);
          expect(backtest.systemRecallAfter != null, isNightV2);
        }
      }
    });

    test('NIGHT_TRANSFER v2 matches its own paragraph', () {
      final v2 = ruleOf('NIGHT_TRANSFER').latest;
      expect(v2.status, RuleStatus.PENDING_APPROVAL);
      expect(formatDecimal(v2.backtest!.candidate.precision), '0,52');
      expect(formatDayMonth(v2.createdAt), '22 oct');
      expect(formatHm(v2.submittedAt!), '08:10');
      expect(formatDayAgo(v2.shadowStats!.since, now), 'hace 5 d');
      expect(v2.shadowStats!.evaluated, 4200);
      expect(v2.shadowStats!.matched, 61);
      expect(v2.shadowStats!.verdictChanges, 0);
      final active = v2.backtest!.active!;
      expect(active.truePositives, 32);
      expect(active.falsePositives, 9);
      expect(active.falseNegatives, 31);
      expect(active.trueNegatives, 1848);
      expect(v2.backtest!.candidate.falseNegatives, 22);
      expect(v2.backtest!.candidate.trueNegatives, 1819);
      expect(v2.backtest!.systemRecallBefore, 0.74);
      expect(v2.backtest!.systemRecallAfter, 0.77);
    });

    test('FAR_FROM_HOME v1 has its shadow stats', () {
      final stats = ruleOf('FAR_FROM_HOME').latest.shadowStats!;
      expect(stats.evaluated, 9800);
      expect(stats.matched, 1102);
      expect(stats.verdictChanges, 14);
    });
  });

  group('models', () {
    test('newest first, with exactly one ACTIVE', () {
      expect(seed.models.map((m) => m.version), ['v5', 'v4', 'v3', 'v2', 'v1']);
      expect(
        seed.models.where((m) => m.status == ModelStatus.ACTIVE).single.version,
        'v5',
      );
    });

    test('metrics read prAuc, recall and precision', () {
      const expected = {
        'v5': (0.81, 0.74, 0.62),
        'v4': (0.83, 0.70, 0.64),
        'v3': (0.79, 0.72, 0.61),
        'v2': (0.78, 0.72, 0.60),
        'v1': (0.77, 0.71, 0.59),
      };
      expected.forEach((version, row) {
        final metrics = modelOf(version).metrics;
        expect(
          (metrics.prAuc, metrics.recall, metrics.precision),
          row,
          reason: version,
        );
      });
    });

    test('featureImportance of every model sums to 1', () {
      for (final model in seed.models) {
        final sum = model.metrics.featureImportance.values.reduce(
          (a, b) => a + b,
        );
        expect(sum, closeTo(1, 0.001), reason: model.version);
      }
    });

    test('the quality gates match the issue', () {
      final v4 = modelOf('v4').qualityGate!;
      expect(v4.passed, isFalse);
      expect(v4.checks.map((c) => c.name), [
        'MIN_NEW_LABELS',
        'PR_AUC_NOT_WORSE',
        'RECALL_NOT_WORSE',
      ]);
      expect(v4.checks.where((c) => !c.passed).map((c) => c.name), [
        'RECALL_NOT_WORSE',
      ]);
      final v5 = modelOf('v5').qualityGate!;
      expect(v5.passed, isTrue);
      expect(v5.checks.every((c) => c.passed), isTrue);
      for (final version in ['v3', 'v2', 'v1']) {
        expect(modelOf(version).qualityGate, isNull);
      }
    });

    test('triggers, trainers and times match the issue', () {
      final v4 = modelOf('v4');
      expect(v4.trigger, ModelTrigger.MANUAL);
      expect(v4.status, ModelStatus.CANDIDATE);
      expect(v4.trainedBy!.fullName, 'Laura Cárdenas');
      expect(formatDayAgo(v4.trainedAt, now), 'ayer');
      expect(formatHm(v4.trainedAt), '16:40');
      expect(formatDayAgo(modelOf('v5').trainedAt, now), 'hoy');
      expect(formatHm(modelOf('v5').trainedAt), '02:00');
      for (final version in ['v5', 'v3', 'v2', 'v1']) {
        expect(modelOf(version).trigger, ModelTrigger.SCHEDULED);
        expect(modelOf(version).trainedBy, isNull);
      }
      expect(formatDayAgo(modelOf('v1').trainedAt, now), 'hace 3 d');
    });

    test('training counts increase with time up to v5', () {
      expect(modelOf('v5').trainingRows, 182400);
      expect(modelOf('v5').fraudsSeen, 1940);
      expect(modelOf('v3').fraudsSeen, 1820);
      for (var i = 1; i < seed.models.length; i++) {
        final newer = seed.models[i - 1];
        final older = seed.models[i];
        expect(older.trainedAt.isBefore(newer.trainedAt), isTrue);
        expect(older.trainingRows, lessThan(newer.trainingRows));
        expect(older.fraudsSeen, lessThan(newer.fraudsSeen));
      }
    });
  });

  group('metrics', () {
    test('verdict counts sum to decisions', () {
      final metrics = seed.metrics;
      expect(metrics.decisions, 12480);
      expect(metrics.verdicts.values.reduce((a, b) => a + b), 12480);
      expect(metrics.verdicts[Verdict.BLOCK], 37);
    });

    test('hold the issue values', () {
      final metrics = seed.metrics;
      expect(metrics.hourly, hasLength(24));
      expect(metrics.hourly[12].approve, 94);
      expect(metrics.hourly[23].block, 2);
      expect(metrics.alerts, isEmpty);
      expect(metrics.openCases, 214);
      expect(metrics.previousDecisions, 11534);
      expect(metrics.latencyP50, 64);
      expect(metrics.latencyP95, 182);
      expect(metrics.latencyP99, 310);
      expect(metrics.degradedRate, 3 / 12480);
      expect(metrics.from, now.subtract(const Duration(hours: 24)));
      expect(metrics.to, now.subtract(const Duration(seconds: 12)));
    });

    test('simulationRunCount is 17', () {
      expect(seed.simulationRunCount, 17);
    });
  });

  group('time', () {
    for (final clock in [
      DateTime(2026, 10, 25, 9, 45),
      DateTime(2026, 10, 25, 0, 30),
      DateTime(2026, 10, 25, 0, 0),
      DateTime(2026, 1, 1, 0, 1),
    ]) {
      test('no timestamp is after $clock', () {
        final times = _allTimes(MockSeed.build(clock));
        expect(times, isNotEmpty);
        for (final time in times) {
          expect(time.isAfter(clock), isFalse, reason: '$time');
        }
      });
    }

    test('two builds with the same now give the same ids and times', () {
      final other = MockSeed.build(now);
      expect(
        other.cases.map((c) => c.id).toList(),
        seed.cases.map((c) => c.id).toList(),
      );
      expect(
        other.rules.map((r) => r.rule.id).toList(),
        seed.rules.map((r) => r.rule.id).toList(),
      );
      expect(other.customers.first.id, seed.customers.first.id);
      expect(_allTimes(other), _allTimes(seed));
    });
  });
}
