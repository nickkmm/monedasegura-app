import 'app_user.dart';
import 'enums.dart';

enum ConditionOp {
  gt('>', '>'),
  gte('>=', '≥'),
  lt('<', '<'),
  lte('<=', '≤'),
  eq('=', '='),
  neq('!=', '≠'),
  inList('in', 'en');

  const ConditionOp(this.code, this.symbol);

  final String code;
  final String symbol;

  static ConditionOp fromCode(String code) {
    for (final op in values) {
      if (op.code == code) return op;
    }
    throw ArgumentError.value(code, 'code', 'Unknown ConditionOp code');
  }
}

class Condition {
  const Condition(this.feature, this.op, this.value);

  final String feature;
  final ConditionOp op;

  /// A num, bool, String or List.
  final Object value;
}

class ShadowStats {
  const ShadowStats({
    required this.since,
    required this.evaluated,
    required this.matched,
    required this.verdictChanges,
  });

  final DateTime since;
  final int evaluated;
  final int matched;
  final int verdictChanges;
}

class BacktestCounts {
  const BacktestCounts({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.trueNegatives,
  });

  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final int trueNegatives;

  int get matches => truePositives + falsePositives;
  double get precision => matches == 0 ? 0 : truePositives / matches;
}

class Backtest {
  const Backtest({
    required this.runAt,
    required this.casesEvaluated,
    required this.candidate,
    this.active,
    this.systemRecallBefore,
    this.systemRecallAfter,
  });

  final DateTime runAt;
  final int casesEvaluated;
  final BacktestCounts candidate;
  final BacktestCounts? active;

  // Prototype-only: not in decision-api.yaml.
  final double? systemRecallBefore;

  // Prototype-only: not in decision-api.yaml.
  final double? systemRecallAfter;
}

class Rule {
  const Rule({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String description;

  // Prototype-only: not in decision-api.yaml.
  final DateTime createdAt;

  Rule copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Rule(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RuleVersion {
  const RuleVersion({
    required this.ruleId,
    required this.version,
    required this.conditions,
    required this.action,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.shadowStats,
    this.backtest,
    this.hits7d,
    this.submittedAt,
  });

  final String ruleId;
  final int version;
  final List<Condition> conditions;
  final RuleAction action;
  final RuleStatus status;
  final UserRef createdBy;
  final DateTime createdAt;
  final UserRef? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final ShadowStats? shadowStats;
  final Backtest? backtest;

  // Prototype-only: not in decision-api.yaml.
  final int? hits7d;

  // Prototype-only: not in decision-api.yaml.
  final DateTime? submittedAt;

  RuleVersion copyWith({
    String? ruleId,
    int? version,
    List<Condition>? conditions,
    RuleAction? action,
    RuleStatus? status,
    UserRef? createdBy,
    DateTime? createdAt,
    UserRef? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    ShadowStats? shadowStats,
    Backtest? backtest,
    int? hits7d,
    DateTime? submittedAt,
    bool clearBacktest = false,
    bool clearShadowStats = false,
    bool clearSubmittedAt = false,
  }) {
    return RuleVersion(
      ruleId: ruleId ?? this.ruleId,
      version: version ?? this.version,
      conditions: conditions ?? this.conditions,
      action: action ?? this.action,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      shadowStats: clearShadowStats ? null : shadowStats ?? this.shadowStats,
      backtest: clearBacktest ? null : backtest ?? this.backtest,
      hits7d: hits7d ?? this.hits7d,
      submittedAt: clearSubmittedAt ? null : submittedAt ?? this.submittedAt,
    );
  }
}

class RuleView {
  const RuleView({required this.rule, required this.versions});

  final Rule rule;

  /// Newest first.
  final List<RuleVersion> versions;

  RuleVersion get latest => versions.first;

  RuleVersion? get active {
    for (final candidate in versions) {
      if (candidate.status == RuleStatus.ACTIVE) return candidate;
    }
    return null;
  }

  RuleVersion? version(int n) {
    for (final candidate in versions) {
      if (candidate.version == n) return candidate;
    }
    return null;
  }

  RuleView copyWith({Rule? rule, List<RuleVersion>? versions}) {
    return RuleView(
      rule: rule ?? this.rule,
      versions: versions ?? this.versions,
    );
  }
}
