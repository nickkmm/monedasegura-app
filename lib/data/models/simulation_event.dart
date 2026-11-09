import 'customer.dart';
import 'decision.dart';
import 'transaction.dart';

/// What one simulated transaction produced.
class SimulationEvent {
  const SimulationEvent({
    required this.transaction,
    required this.decision,
    required this.customer,
  });

  final Transaction transaction;
  final Decision decision;
  final Customer customer;
}
