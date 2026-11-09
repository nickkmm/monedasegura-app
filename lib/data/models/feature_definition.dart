class FeatureDefinition {
  const FeatureDefinition({
    required this.name,
    required this.type,
    required this.description,
    this.allowedValues,
  });

  final String name;

  /// One of `number`, `integer`, `boolean` or `string`.
  final String type;
  final String description;
  final List<String>? allowedValues;
}

/// The "Catalog (v1)" of `features.md`, in order, plus the model's `score`.
const List<FeatureDefinition> featureCatalog = [
  FeatureDefinition(
    name: 'amount',
    type: 'number',
    description: 'Transaction amount in COP',
  ),
  FeatureDefinition(
    name: 'amount_vs_avg_30d',
    type: 'number',
    description: "`amount` / customer's average amount over the last 30 days",
  ),
  FeatureDefinition(
    name: 'spend_24h',
    type: 'number',
    description: "Sum of the customer's amounts in the last 24 h",
  ),
  FeatureDefinition(
    name: 'tx_count_5m',
    type: 'integer',
    description: "Customer's transactions in the last 5 minutes",
  ),
  FeatureDefinition(
    name: 'tx_count_1h',
    type: 'integer',
    description: "Customer's transactions in the last hour",
  ),
  FeatureDefinition(
    name: 'same_amount_counterparty_10m',
    type: 'integer',
    description:
        "Customer's transactions in the last 10 minutes with the same `amount` "
        'and the same `counterparty` as this one (`BALANCE_QUERY` and empty '
        'counterparties never match)',
  ),
  FeatureDefinition(
    name: 'minutes_since_prev',
    type: 'number',
    description:
        "Minutes since the customer's previous transaction (default: one week)",
  ),
  FeatureDefinition(
    name: 'km_from_home',
    type: 'number',
    description:
        'Distance from `customer.home_latitude/longitude` to the transaction',
  ),
  FeatureDefinition(
    name: 'km_from_prev',
    type: 'number',
    description: "Distance from the previous transaction's location",
  ),
  FeatureDefinition(
    name: 'implied_speed_kmh',
    type: 'number',
    description: '`km_from_prev` / (`minutes_since_prev` / 60), capped at 2000',
  ),
  FeatureDefinition(
    name: 'hour_of_day',
    type: 'integer',
    description: 'Local hour 0–23 of `occurred_at`',
  ),
  FeatureDefinition(
    name: 'is_night',
    type: 'boolean',
    description: '`hour_of_day` in 22–03',
  ),
  FeatureDefinition(
    name: 'category',
    type: 'string',
    description: 'Merchant category (`transaction.category`)',
    allowedValues: [
      'shopping_net',
      'shopping_pos',
      'grocery_pos',
      'grocery_net',
      'gas_transport',
      'food_dining',
      'misc_net',
      'misc_pos',
      'entertainment',
      'health_fitness',
      'travel',
      'home',
      'kids_pets',
      'personal_care',
    ],
  ),
  FeatureDefinition(
    name: 'is_new_device',
    type: 'boolean',
    description:
        "The device never appeared before in the customer's transactions or "
        'session events',
  ),
  FeatureDefinition(
    name: 'device_age_days',
    type: 'number',
    description: 'Days since `device.first_seen_at`',
  ),
  FeatureDefinition(
    name: 'customers_on_device',
    type: 'integer',
    description: 'Distinct customers seen on this device in the last 30 days',
  ),
  FeatureDefinition(
    name: 'failed_logins_1h',
    type: 'integer',
    description: "Customer's `LOGIN_FAILED` session events in the last hour",
  ),
  FeatureDefinition(
    name: 'password_changed_24h',
    type: 'boolean',
    description: 'A `PASSWORD_CHANGED` event in the last 24 h',
  ),
  FeatureDefinition(
    name: 'account_age_days',
    type: 'number',
    description: 'Days since `customer.created_at`',
  ),
  FeatureDefinition(
    name: 'score',
    type: 'number',
    description: 'Model output 0-1, usable in rules',
  ),
];
