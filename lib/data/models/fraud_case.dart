import '../labels.dart';
import 'app_user.dart';
import 'customer.dart';
import 'decision.dart';
import 'enums.dart';
import 'transaction.dart';

class FraudCase {
  const FraudCase({
    required this.id,
    required this.decisionId,
    required this.status,
    this.label,
    this.notes,
    this.assignedTo,
    required this.openedAt,
    this.resolvedAt,
  });

  final String id;

  // Prototype-only: not in decision-api.yaml.
  final String decisionId;
  final CaseStatus status;
  final CaseLabel? label;
  final String? notes;
  final UserRef? assignedTo;
  final DateTime openedAt;
  final DateTime? resolvedAt;

  FraudCase copyWith({
    String? id,
    String? decisionId,
    CaseStatus? status,
    CaseLabel? label,
    String? notes,
    UserRef? assignedTo,
    DateTime? openedAt,
    DateTime? resolvedAt,
  }) {
    return FraudCase(
      id: id ?? this.id,
      decisionId: decisionId ?? this.decisionId,
      status: status ?? this.status,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      openedAt: openedAt ?? this.openedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

/// The API's CaseDetail as one read model.
class CaseView {
  const CaseView({
    required this.fraudCase,
    required this.transaction,
    required this.decision,
    required this.customer,
    required this.device,
  });

  final FraudCase fraudCase;
  final Transaction transaction;
  final Decision decision;
  final Customer customer;

  // Prototype-only: not in decision-api.yaml.
  final Device device;

  String get id => fraudCase.id;
  String get shortId => '#${id.substring(0, 6).toUpperCase()}';
  CaseStatus get status => fraudCase.status;
  CaseLabel? get label => fraudCase.label;
  Verdict get verdict => decision.verdict;
  double? get score => decision.score;
  bool get degraded => decision.degraded;
  int get amount => transaction.amount;
  UserRef? get assignedTo => fraudCase.assignedTo;
  DateTime get openedAt => fraudCase.openedAt;
  DateTime? get resolvedAt => fraudCase.resolvedAt;

  String get typeLabel => transaction.type == TransactionType.TRANSFER
      ? 'Transferencia'
      : categoryLabel(transaction.category ?? '');

  CaseView copyWith({
    FraudCase? fraudCase,
    Transaction? transaction,
    Decision? decision,
    Customer? customer,
    Device? device,
  }) {
    return CaseView(
      fraudCase: fraudCase ?? this.fraudCase,
      transaction: transaction ?? this.transaction,
      decision: decision ?? this.decision,
      customer: customer ?? this.customer,
      device: device ?? this.device,
    );
  }
}
