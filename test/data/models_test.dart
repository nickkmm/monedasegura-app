import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/format.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';

AppUser _user(List<RoleCode> roles, {String fullName = 'Valentina Ríos'}) {
  return AppUser(
    id: 'a1000000-0000-4000-8000-000000000099',
    fullName: fullName,
    email: 'valentina.rios@monedasegura.co',
    active: true,
    roles: roles,
  );
}

void _expectRoundTrip<T>(
  String name,
  List<T> values,
  String Function(T) code,
  T Function(String) fromCode,
) {
  test('$name round-trips its codes and rejects unknown ones', () {
    for (final value in values) {
      expect(fromCode(code(value)), value);
    }
    expect(() => fromCode('UNKNOWN'), throwsArgumentError);
  });
}

void main() {
  group('RBAC', () {
    test('ADMIN has all 10 permissions', () {
      final permissions = _user([RoleCode.ADMIN]).permissions;
      expect(permissions, PermissionCode.values.toSet());
      expect(permissions, hasLength(10));
    });

    test('RISK_LEAD has RULE_APPROVE', () {
      expect(
        _user([RoleCode.RISK_LEAD]).can(PermissionCode.RULE_APPROVE),
        isTrue,
      );
    });

    test('ANALYST lacks RULE_WRITE and SIMULATOR_RUN', () {
      final analyst = _user([RoleCode.ANALYST]);
      expect(analyst.can(PermissionCode.RULE_WRITE), isFalse);
      expect(analyst.can(PermissionCode.SIMULATOR_RUN), isFalse);
    });

    test('AUDITOR has exactly 4', () {
      expect(_user([RoleCode.AUDITOR]).permissions, hasLength(4));
    });

    test('DATA_SCIENTIST has its 5 permissions', () {
      expect(_user([RoleCode.DATA_SCIENTIST]).permissions, {
        PermissionCode.MODEL_READ,
        PermissionCode.MODEL_TRAIN,
        PermissionCode.RULE_READ,
        PermissionCode.CASE_READ,
        PermissionCode.DASHBOARD_READ,
      });
    });

    test('a user with two roles gets the union', () {
      expect(_user([RoleCode.AUDITOR, RoleCode.DATA_SCIENTIST]).permissions, {
        ...rolePermissions[RoleCode.AUDITOR]!,
        ...rolePermissions[RoleCode.DATA_SCIENTIST]!,
      });
    });
  });

  group('AppUser', () {
    test('initials use the first two words', () {
      expect(_user(const []).initials, 'VR');
      expect(_user(const [], fullName: 'Valentina').initials, 'V');
      expect(_user(const [], fullName: 'ana maría ríos').initials, 'AM');
    });

    test('can agrees with permissions', () {
      final user = _user([RoleCode.ANALYST]);
      for (final permission in PermissionCode.values) {
        expect(user.can(permission), user.permissions.contains(permission));
      }
    });

    test('ref carries the id and the name', () {
      final user = _user(const []);
      expect(user.ref.id, user.id);
      expect(user.ref.fullName, user.fullName);
    });

    test('app_user.dart has no credential field', () {
      final source = File('lib/data/models/app_user.dart').readAsStringSync();
      expect(source.toLowerCase().contains('password'), isFalse);
    });
  });

  group('enums', () {
    _expectRoundTrip(
      'Verdict',
      Verdict.values,
      (x) => x.code,
      Verdict.fromCode,
    );
    _expectRoundTrip(
      'DecisionKind',
      DecisionKind.values,
      (x) => x.code,
      DecisionKind.fromCode,
    );
    _expectRoundTrip(
      'TransactionType',
      TransactionType.values,
      (x) => x.code,
      TransactionType.fromCode,
    );
    _expectRoundTrip(
      'TransactionSource',
      TransactionSource.values,
      (x) => x.code,
      TransactionSource.fromCode,
    );
    _expectRoundTrip(
      'Scenario',
      Scenario.values,
      (x) => x.code,
      Scenario.fromCode,
    );
    _expectRoundTrip(
      'SessionEventType',
      SessionEventType.values,
      (x) => x.code,
      SessionEventType.fromCode,
    );
    _expectRoundTrip(
      'CaseStatus',
      CaseStatus.values,
      (x) => x.code,
      CaseStatus.fromCode,
    );
    _expectRoundTrip(
      'CaseLabel',
      CaseLabel.values,
      (x) => x.code,
      CaseLabel.fromCode,
    );
    _expectRoundTrip(
      'RuleAction',
      RuleAction.values,
      (x) => x.code,
      RuleAction.fromCode,
    );
    _expectRoundTrip(
      'RuleStatus',
      RuleStatus.values,
      (x) => x.code,
      RuleStatus.fromCode,
    );
    _expectRoundTrip(
      'ModelStatus',
      ModelStatus.values,
      (x) => x.code,
      ModelStatus.fromCode,
    );
    _expectRoundTrip(
      'ModelTrigger',
      ModelTrigger.values,
      (x) => x.code,
      ModelTrigger.fromCode,
    );
    _expectRoundTrip(
      'RoleCode',
      RoleCode.values,
      (x) => x.code,
      RoleCode.fromCode,
    );
    _expectRoundTrip(
      'PermissionCode',
      PermissionCode.values,
      (x) => x.code,
      PermissionCode.fromCode,
    );
    _expectRoundTrip(
      'DeviceOs',
      DeviceOs.values,
      (x) => x.code,
      DeviceOs.fromCode,
    );
    _expectRoundTrip(
      'ConditionOp',
      ConditionOp.values,
      (x) => x.code,
      ConditionOp.fromCode,
    );

    test('ConditionOp codes and symbols', () {
      expect(ConditionOp.values.map((op) => op.code), [
        '>',
        '>=',
        '<',
        '<=',
        '=',
        '!=',
        'in',
      ]);
      expect(ConditionOp.values.map((op) => op.symbol), [
        '>',
        '≥',
        '<',
        '≤',
        '=',
        '≠',
        'en',
      ]);
    });
  });

  group('model getters', () {
    const userRef = UserRef(id: 'u', fullName: 'Laura Méndez');
    final createdAt = DateTime(2026, 10, 1);

    RuleVersion version(int number, RuleStatus status, {Backtest? backtest}) {
      return RuleVersion(
        ruleId: 'r',
        version: number,
        conditions: const [Condition('is_night', ConditionOp.eq, true)],
        action: RuleAction.REVIEW,
        status: status,
        createdBy: userRef,
        createdAt: createdAt,
        backtest: backtest,
      );
    }

    final rule = Rule(
      id: 'r',
      code: 'RULE',
      name: 'Regla',
      description: 'Regla',
      createdAt: createdAt,
    );

    test('BacktestCounts matches and precision', () {
      const counts = BacktestCounts(
        truePositives: 41,
        falsePositives: 38,
        falseNegatives: 22,
        trueNegatives: 1819,
      );
      expect(counts.matches, 79);
      expect(formatDecimal(counts.precision), '0,52');
    });

    test('BacktestCounts precision is 0 with no matches', () {
      const counts = BacktestCounts(
        truePositives: 0,
        falsePositives: 0,
        falseNegatives: 3,
        trueNegatives: 7,
      );
      expect(counts.precision, 0);
    });

    test('RuleView latest, active and version', () {
      final newest = version(2, RuleStatus.PENDING_APPROVAL);
      final oldest = version(1, RuleStatus.ACTIVE);
      final view = RuleView(rule: rule, versions: [newest, oldest]);
      expect(view.latest, same(newest));
      expect(view.active, same(oldest));
      expect(view.version(1), same(oldest));
      expect(view.version(9), isNull);
    });

    test('RuleView active is null without an ACTIVE version', () {
      final view = RuleView(
        rule: rule,
        versions: [version(1, RuleStatus.DRAFT)],
      );
      expect(view.active, isNull);
    });

    test('RuleVersion copyWith clears fields only when asked', () {
      final full = version(1, RuleStatus.SHADOW).copyWith(
        backtest: Backtest(
          runAt: createdAt,
          casesEvaluated: 0,
          candidate: const BacktestCounts(
            truePositives: 0,
            falsePositives: 0,
            falseNegatives: 0,
            trueNegatives: 0,
          ),
        ),
        shadowStats: ShadowStats(
          since: createdAt,
          evaluated: 0,
          matched: 0,
          verdictChanges: 0,
        ),
        submittedAt: createdAt,
      );
      expect(full.copyWith(status: RuleStatus.DRAFT).backtest, isNotNull);
      expect(full.copyWith(clearBacktest: true).backtest, isNull);
      expect(full.copyWith(clearBacktest: true).shadowStats, isNotNull);
      expect(full.copyWith(clearShadowStats: true).shadowStats, isNull);
      expect(full.copyWith(clearSubmittedAt: true).submittedAt, isNull);
    });

    test('CaseView shortId and typeLabel', () {
      final cases = MockSeed.build(DateTime(2026, 10, 25, 9, 45)).cases;
      final b204e7 = cases.firstWhere((c) => c.id.startsWith('b204e7'));
      final f0b6a = cases.firstWhere((c) => c.id.startsWith('7f0b6a'));
      expect(b204e7.shortId, '#B204E7');
      expect(b204e7.typeLabel, 'Compra en línea');
      expect(f0b6a.typeLabel, 'Transferencia');
    });

    test('CaseView copyWith replaces one part', () {
      final view = MockSeed.build(DateTime(2026, 10, 25, 9, 45)).cases.first;
      final copy = view.copyWith(
        fraudCase: view.fraudCase.copyWith(status: CaseStatus.IN_REVIEW),
      );
      expect(copy.status, CaseStatus.IN_REVIEW);
      expect(copy.decision, same(view.decision));
    });
  });

  group('feature catalog', () {
    test('has 20 entries, in order', () {
      expect(featureCatalog, hasLength(20));
      expect(featureCatalog.first.name, 'amount');
      expect(featureCatalog[18].name, 'account_age_days');
      expect(featureCatalog.last.name, 'score');
      expect(
        featureCatalog.last.description,
        'Model output 0-1, usable in rules',
      );
    });

    test('category lists the 14 category codes', () {
      final category = featureCatalog.firstWhere((f) => f.name == 'category');
      expect(category.allowedValues, hasLength(14));
    });
  });
}
