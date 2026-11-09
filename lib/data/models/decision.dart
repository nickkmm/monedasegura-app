import 'enums.dart';

class RuleHit {
  const RuleHit({
    required this.ruleId,
    required this.ruleCode,
    required this.version,
    required this.action,
    required this.matched,
    required this.shadow,
  });

  final String ruleId;
  final String ruleCode;
  final int version;
  final RuleAction action;
  final bool matched;
  final bool shadow;
}

class Decision {
  const Decision({
    required this.id,
    required this.transactionId,
    required this.kind,
    required this.verdict,
    this.score,
    this.modelVersion,
    required this.degraded,
    required this.features,
    required this.ruleHits,
    required this.latencyMs,
    required this.decidedAt,
    this.caseId,
  });

  final String id;
  final String transactionId;
  final DecisionKind kind;
  final Verdict verdict;
  final double? score;
  final String? modelVersion;
  final bool degraded;
  final Map<String, Object> features;
  final List<RuleHit> ruleHits;
  final int latencyMs;
  final DateTime decidedAt;
  final String? caseId;
}
