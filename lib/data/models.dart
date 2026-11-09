/// In-memory models consistent with monedasegura-infra/docs/model.md.
/// Enum values mirror the API codes; Spanish display text lives in labels.dart.
library;

enum Verdict { approve, review, block }

enum CaseStatus { open, inReview, resolved }

enum CaseLabel { confirmedFraud, dismissed }

enum RuleStatus { draft, shadow, pendingApproval, active, retired }

enum RuleAction { review, block }

enum ModelStatus { candidate, active, retired }

enum Permission {
  caseRead,
  caseResolve,
  ruleRead,
  ruleWrite,
  ruleApprove,
  modelRead,
  modelTrain,
  simulatorRun,
  dashboardRead,
  userAdmin,
}

enum RoleCode { analyst, riskLead, dataScientist, auditor, admin }

/// Permissions of each role (model.md §4).
const Map<RoleCode, Set<Permission>> rolePermissions = {
  RoleCode.analyst: {
    Permission.caseRead,
    Permission.caseResolve,
    Permission.ruleRead,
    Permission.modelRead,
    Permission.dashboardRead,
  },
  RoleCode.riskLead: {
    Permission.caseRead,
    Permission.caseResolve,
    Permission.ruleRead,
    Permission.modelRead,
    Permission.dashboardRead,
    Permission.ruleWrite,
    Permission.ruleApprove,
  },
  RoleCode.dataScientist: {
    Permission.modelRead,
    Permission.modelTrain,
    Permission.ruleRead,
    Permission.caseRead,
    Permission.dashboardRead,
  },
  RoleCode.auditor: {
    Permission.caseRead,
    Permission.ruleRead,
    Permission.modelRead,
    Permission.dashboardRead,
  },
  RoleCode.admin: {
    Permission.userAdmin,
    Permission.simulatorRun,
    Permission.caseRead,
    Permission.caseResolve,
    Permission.ruleRead,
    Permission.modelRead,
    Permission.dashboardRead,
    Permission.ruleWrite,
    Permission.ruleApprove,
    Permission.modelTrain,
  },
};

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
    required this.roleTitle,
    required this.permissions,
  });

  final String id;
  final String name;
  final String email;
  final String initials;

  /// Spanish role title shown under the name.
  final String roleTitle;
  final Set<Permission> permissions;

  bool can(Permission permission) => permissions.contains(permission);
}

/// One rule hit shown in "Por qué se marcó".
class RuleHit {
  const RuleHit({
    required this.code,
    required this.description,
    required this.matched,
    this.shadow = false,
  });

  final String code;
  final String description;
  final bool matched;

  /// A rule in SHADOW is evaluated but does not change the decision.
  final bool shadow;
}

class FraudCase {
  const FraudCase({
    required this.id,
    required this.customerName,
    required this.document,
    required this.amount,
    required this.type,
    required this.verdict,
    required this.score,
    required this.degraded,
    required this.status,
    required this.ageLabel,
    required this.occurredAt,
    required this.merchant,
    required this.category,
    required this.device,
    required this.location,
    required this.os,
    required this.city,
    required this.customerSince,
    required this.tx30d,
    required this.previousFrauds,
    required this.ruleHits,
    required this.signals,
    this.assignedTo,
    this.label,
    this.notes = '',
  });

  /// Short case id, e.g. `#B204E7`.
  final String id;
  final String customerName;

  /// Masked document, e.g. `•••• 4821`. Never unmasked.
  final String document;
  final int amount;
  final String type;
  final Verdict verdict;

  /// Model score 0–1; null when the decision used rules only (degraded).
  final double? score;
  final bool degraded;
  final CaseStatus status;
  final String ageLabel;
  final String occurredAt;
  final String merchant;
  final String category;
  final String device;
  final String location;
  final String os;
  final String city;
  final String customerSince;
  final int tx30d;
  final int previousFrauds;
  final List<RuleHit> ruleHits;
  final List<String> signals;
  final String? assignedTo;
  final CaseLabel? label;
  final String notes;

  FraudCase copyWith({
    CaseStatus? status,
    String? assignedTo,
    CaseLabel? label,
    String? notes,
  }) {
    return FraudCase(
      id: id,
      customerName: customerName,
      document: document,
      amount: amount,
      type: type,
      verdict: verdict,
      score: score,
      degraded: degraded,
      status: status ?? this.status,
      ageLabel: ageLabel,
      occurredAt: occurredAt,
      merchant: merchant,
      category: category,
      device: device,
      location: location,
      os: os,
      city: city,
      customerSince: customerSince,
      tx30d: tx30d,
      previousFrauds: previousFrauds,
      ruleHits: ruleHits,
      signals: signals,
      assignedTo: assignedTo ?? this.assignedTo,
      label: label ?? this.label,
      notes: notes ?? this.notes,
    );
  }
}

/// One clause of `condition_json` (`{"all": [...]}`).
class RuleCondition {
  const RuleCondition({
    required this.feature,
    required this.operator,
    required this.value,
  });

  final String feature;

  /// One of `> >= < <= = != in`.
  final String operator;
  final String value;

  RuleCondition copyWith({String? feature, String? operator, String? value}) {
    return RuleCondition(
      feature: feature ?? this.feature,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

class RuleVersion {
  const RuleVersion({
    required this.number,
    required this.action,
    required this.status,
    required this.conditions,
    required this.createdBy,
    required this.updatedLabel,
    this.hits7d,
    this.precision,
    this.backtestDone = false,
    this.shadowDays = 0,
  });

  final int number;
  final RuleAction action;
  final RuleStatus status;
  final List<RuleCondition> conditions;
  final String createdBy;
  final String updatedLabel;
  final int? hits7d;
  final double? precision;
  final bool backtestDone;
  final int shadowDays;

  RuleVersion copyWith({
    RuleAction? action,
    RuleStatus? status,
    List<RuleCondition>? conditions,
    String? updatedLabel,
    int? hits7d,
    double? precision,
    bool? backtestDone,
    int? shadowDays,
  }) {
    return RuleVersion(
      number: number,
      action: action ?? this.action,
      status: status ?? this.status,
      conditions: conditions ?? this.conditions,
      createdBy: createdBy,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      hits7d: hits7d ?? this.hits7d,
      precision: precision ?? this.precision,
      backtestDone: backtestDone ?? this.backtestDone,
      shadowDays: shadowDays ?? this.shadowDays,
    );
  }
}

class Rule {
  const Rule({
    required this.code,
    required this.description,
    required this.versions,
  });

  /// Unique code, e.g. `NIGHT_TRANSFER`.
  final String code;
  final String description;

  /// Oldest first; the last one is the latest version.
  final List<RuleVersion> versions;

  RuleVersion get latest => versions.last;

  Rule copyWith({String? description, List<RuleVersion>? versions}) {
    return Rule(
      code: code,
      description: description ?? this.description,
      versions: versions ?? this.versions,
    );
  }

  /// Replaces the latest version.
  Rule withLatest(RuleVersion version) {
    return copyWith(
      versions: [...versions.sublist(0, versions.length - 1), version],
    );
  }
}

class ModelVersion {
  const ModelVersion({
    required this.name,
    required this.trainedAt,
    required this.origin,
    required this.prAuc,
    required this.recall,
    required this.status,
  });

  final String name;
  final String trainedAt;
  final String origin;
  final double prAuc;
  final double recall;
  final ModelStatus status;

  ModelVersion copyWith({ModelStatus? status}) {
    return ModelVersion(
      name: name,
      trainedAt: trainedAt,
      origin: origin,
      prAuc: prAuc,
      recall: recall,
      status: status ?? this.status,
    );
  }
}

/// A decision produced by the simulator feed.
class SimEvent {
  const SimEvent({
    required this.time,
    required this.customer,
    required this.type,
    required this.amount,
    required this.verdict,
    required this.latencyMs,
  });

  final String time;
  final String customer;
  final String type;
  final int amount;
  final Verdict verdict;
  final int latencyMs;
}

class SimScenario {
  const SimScenario({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  /// API code of the scenario, e.g. `ACCOUNT_TAKEOVER`.
  final String code;
  final String title;
  final String subtitle;
  final String description;
}

class HourlyDecisions {
  const HourlyDecisions(this.approve, this.review, this.block);

  final double approve;
  final double review;
  final double block;
}
