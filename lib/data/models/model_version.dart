import 'app_user.dart';
import 'enums.dart';

class ModelMetrics {
  const ModelMetrics({
    required this.prAuc,
    required this.precision,
    required this.recall,
    required this.featureImportance,
  });

  final double prAuc;
  final double precision;
  final double recall;
  final Map<String, double> featureImportance;
}

class QualityGate {
  const QualityGate({required this.passed, required this.checks});

  final bool passed;

  /// Named MIN_NEW_LABELS, PR_AUC_NOT_WORSE and RECALL_NOT_WORSE.
  final List<({String name, bool passed})> checks;
}

class ModelVersion {
  const ModelVersion({
    required this.id,
    required this.version,
    this.algorithm = 'LIGHTGBM',
    required this.trigger,
    this.trainedBy,
    required this.status,
    required this.metrics,
    this.qualityGate,
    required this.trainedAt,
    required this.trainingRows,
    required this.fraudsSeen,
  });

  final String id;
  final String version;
  final String algorithm;
  final ModelTrigger trigger;
  final UserRef? trainedBy;
  final ModelStatus status;
  final ModelMetrics metrics;
  final QualityGate? qualityGate;
  final DateTime trainedAt;

  // Prototype-only: not in decision-api.yaml.
  final int trainingRows;

  // Prototype-only: not in decision-api.yaml.
  final int fraudsSeen;

  ModelVersion copyWith({
    String? id,
    String? version,
    String? algorithm,
    ModelTrigger? trigger,
    UserRef? trainedBy,
    ModelStatus? status,
    ModelMetrics? metrics,
    QualityGate? qualityGate,
    DateTime? trainedAt,
    int? trainingRows,
    int? fraudsSeen,
  }) {
    return ModelVersion(
      id: id ?? this.id,
      version: version ?? this.version,
      algorithm: algorithm ?? this.algorithm,
      trigger: trigger ?? this.trigger,
      trainedBy: trainedBy ?? this.trainedBy,
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      qualityGate: qualityGate ?? this.qualityGate,
      trainedAt: trainedAt ?? this.trainedAt,
      trainingRows: trainingRows ?? this.trainingRows,
      fraudsSeen: fraudsSeen ?? this.fraudsSeen,
    );
  }
}
