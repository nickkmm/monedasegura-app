import 'enums.dart';

class Device {
  const Device({
    required this.id,
    required this.fingerprint,
    required this.os,
    required this.firstSeenAt,
  });

  final String id;
  final String fingerprint;
  final DeviceOs os;
  final DateTime firstSeenAt;
}

class Transaction {
  const Transaction({
    required this.id,
    required this.customerId,
    required this.deviceId,
    required this.type,
    this.category,
    required this.amount,
    this.currency = 'COP',
    required this.latitude,
    required this.longitude,
    this.counterparty,
    required this.source,
    this.scenario,
    required this.occurredAt,
  });

  final String id;
  final String customerId;
  final String deviceId;
  final TransactionType type;
  final String? category;

  /// In COP.
  final int amount;
  final String currency;
  final double latitude;
  final double longitude;
  final String? counterparty;
  final TransactionSource source;
  final Scenario? scenario;
  final DateTime occurredAt;
}

class SessionEvent {
  const SessionEvent({
    required this.id,
    required this.customerId,
    required this.deviceId,
    required this.eventType,
    this.ipAddress,
    required this.occurredAt,
  });

  final String id;
  final String customerId;
  final String deviceId;
  final SessionEventType eventType;
  final String? ipAddress;
  final DateTime occurredAt;
}
