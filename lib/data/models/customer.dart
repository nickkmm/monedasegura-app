class Customer {
  const Customer({
    required this.id,
    required this.maskedName,
    required this.maskedDocument,
    required this.homeCity,
    required this.createdAt,
    required this.transactions30d,
    required this.previousFrauds,
  });

  final String id;
  final String maskedName;
  final String maskedDocument;
  final String homeCity;
  final DateTime createdAt;

  // Prototype-only: not in decision-api.yaml.
  final int transactions30d;

  // Prototype-only: not in decision-api.yaml.
  final int previousFrauds;
}
