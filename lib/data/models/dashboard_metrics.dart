import 'enums.dart';

// Prototype-only: not in decision-api.yaml.
class HourBucket {
  const HourBucket({
    required this.approve,
    required this.review,
    required this.block,
  });

  final int approve;
  final int review;
  final int block;
}

class DashboardAlert {
  const DashboardAlert({
    required this.type,
    required this.message,
    required this.at,
  });

  final String type;
  final String message;
  final DateTime at;
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.from,
    required this.to,
    required this.decisions,
    required this.verdicts,
    required this.latencyP50,
    required this.latencyP95,
    required this.latencyP99,
    required this.degradedRate,
    required this.openCases,
    required this.alerts,
    required this.previousDecisions,
    required this.hourly,
  });

  final DateTime from;
  final DateTime to;
  final int decisions;
  final Map<Verdict, int> verdicts;
  final int latencyP50;
  final int latencyP95;
  final int latencyP99;
  final double degradedRate;
  final int openCases;
  final List<DashboardAlert> alerts;

  // Prototype-only: not in decision-api.yaml.
  final int previousDecisions;

  // Prototype-only: not in decision-api.yaml.
  final List<HourBucket> hourly;

  DashboardMetrics copyWith({
    DateTime? from,
    DateTime? to,
    int? decisions,
    Map<Verdict, int>? verdicts,
    int? latencyP50,
    int? latencyP95,
    int? latencyP99,
    double? degradedRate,
    int? openCases,
    List<DashboardAlert>? alerts,
    int? previousDecisions,
    List<HourBucket>? hourly,
  }) {
    return DashboardMetrics(
      from: from ?? this.from,
      to: to ?? this.to,
      decisions: decisions ?? this.decisions,
      verdicts: verdicts ?? this.verdicts,
      latencyP50: latencyP50 ?? this.latencyP50,
      latencyP95: latencyP95 ?? this.latencyP95,
      latencyP99: latencyP99 ?? this.latencyP99,
      degradedRate: degradedRate ?? this.degradedRate,
      openCases: openCases ?? this.openCases,
      alerts: alerts ?? this.alerts,
      previousDecisions: previousDecisions ?? this.previousDecisions,
      hourly: hourly ?? this.hourly,
    );
  }
}
