import 'models.dart';

/// Simulated data for the prototype. Values mirror the Figma screens and stay
/// consistent with monedasegura-infra/docs/model.md.

AppUser _user(
  String id,
  String name,
  String initials,
  String roleTitle,
  RoleCode role,
) {
  final slug = name
      .toLowerCase()
      .replaceAll('í', 'i')
      .replaceAll('é', 'e')
      .replaceAll('á', 'a')
      .replaceAll('ó', 'o')
      .replaceAll(' ', '.');
  return AppUser(
    id: id,
    name: name,
    email: '$slug@monedasegura.co',
    initials: initials,
    roleTitle: roleTitle,
    permissions: rolePermissions[role]!,
  );
}

/// Demo accounts, one per role. Any non-empty password signs in.
final List<AppUser> demoUsers = [
  _user('u1', 'Valentina Ríos', 'VR', 'Administradora', RoleCode.admin),
  _user('u2', 'Laura Méndez', 'LM', 'Líder de riesgo', RoleCode.riskLead),
  _user('u3', 'Diego Salazar', 'DS', 'Líder de riesgo', RoleCode.riskLead),
  _user('u4', 'Camilo Torres', 'CT', 'Analista', RoleCode.analyst),
  _user('u5', 'Sara Gómez', 'SG', 'Auditora', RoleCode.auditor),
  _user(
    'u6',
    'Mateo Ruiz',
    'MR',
    'Científico de datos',
    RoleCode.dataScientist,
  ),
];

FraudCase _case({
  required String id,
  required String customer,
  required int amount,
  required String type,
  required Verdict verdict,
  required double? score,
  required String age,
  String merchant = 'ElectroHogar Bogotá',
  String category = 'Compras en línea',
  String device = 'Nuevo · primera vez hoy',
  String location = 'A 412 km de su ciudad',
  String os = 'Android',
  String city = 'Bogotá',
  String since = 'mar 2023',
  int tx30d = 41,
  List<RuleHit>? hits,
  List<String>? signals,
  String? document,
}) {
  final degraded = score == null;
  return FraudCase(
    id: id,
    customerName: customer,
    document:
        document ?? '•••• ${id.substring(1, 5).hashCode.abs() % 9000 + 1000}',
    amount: amount,
    type: type,
    verdict: verdict,
    score: score,
    degraded: degraded,
    status: CaseStatus.open,
    ageLabel: age,
    occurredAt: 'COP · 25 oct 2026, 09:41',
    merchant: merchant,
    category: category,
    device: device,
    location: location,
    os: os,
    city: city,
    customerSince: since,
    tx30d: tx30d,
    previousFrauds: 0,
    ruleHits: hits ?? _defaultHits(verdict, degraded),
    signals:
        signals ??
        const [
          'amount_vs_avg_30d × 4,1',
          'is_new_device = sí',
          'km_from_home = 412',
          'tx_count_1h = 3',
        ],
  );
}

List<RuleHit> _defaultHits(Verdict verdict, bool degraded) {
  final blocked = verdict == Verdict.block;
  return [
    if (!degraded)
      RuleHit(
        code: blocked ? 'SCORE_BLOCK' : 'SCORE_REVIEW',
        description: blocked
            ? 'Score del modelo ≥ 0,90 → Bloquear'
            : 'Score del modelo ≥ 0,60 → Revisar',
        matched: true,
      ),
    const RuleHit(
      code: 'HIGH_AMOUNT_NEW_DEVICE',
      description: 'Monto ≥ \$ 3.000.000 y dispositivo nuevo → Revisar',
      matched: true,
    ),
    const RuleHit(
      code: 'VELOCITY_1H',
      description: 'Más de 5 transacciones en 1 hora → Bloquear',
      matched: false,
    ),
    const RuleHit(
      code: 'FAR_FROM_HOME',
      description: 'Distancia a su ciudad > 300 km → Revisar',
      matched: true,
      shadow: true,
    ),
  ];
}

/// The nine cases of the queue, ordered by risk (BLOCK first, then score).
List<FraudCase> initialCases() {
  return [
    _case(
      id: '#7F0B6A',
      customer: 'Mariana G.',
      amount: 8900000,
      type: 'Transferencia',
      verdict: Verdict.block,
      score: 0.96,
      age: 'hace 1 min',
      merchant: 'Transferencia a tercero',
      category: 'Transferencias',
      document: '•••• 2207',
      city: 'Medellín',
    ),
    _case(
      id: '#E1C048',
      customer: 'Santiago M.',
      amount: 12400000,
      type: 'Transferencia',
      verdict: Verdict.block,
      score: 0.92,
      age: 'hace 12 min',
      merchant: 'Transferencia a tercero',
      category: 'Transferencias',
      document: '•••• 6153',
      city: 'Cali',
    ),
    _case(
      id: '#A17D3C',
      customer: 'Tomás H.',
      amount: 15000000,
      type: 'Transferencia',
      verdict: Verdict.block,
      score: 0.97,
      age: 'hace 34 min',
      merchant: 'Transferencia a tercero',
      category: 'Transferencias',
      document: '•••• 9042',
      city: 'Barranquilla',
    ),
    _case(
      id: '#3A91C2',
      customer: 'Julián R.',
      amount: 1240000,
      type: 'Compra en línea',
      verdict: Verdict.review,
      score: 0.71,
      age: 'hace 3 min',
      document: '•••• 3318',
    ),
    _case(
      id: '#B204E7',
      customer: 'Andrés P.',
      amount: 3250000,
      type: 'Compra en línea',
      verdict: Verdict.review,
      score: 0.67,
      age: 'hace 4 min',
      document: '•••• 4821',
    ),
    _case(
      id: '#5D7A13',
      customer: 'Camila O.',
      amount: 650000,
      type: 'Gasolina y transporte',
      verdict: Verdict.review,
      score: 0.63,
      age: 'hace 9 min',
      merchant: 'Estación Terpel Chía',
      category: 'Gasolina y transporte',
      document: '•••• 7764',
    ),
    _case(
      id: '#09F35B',
      customer: 'Daniela C.',
      amount: 2180000,
      type: 'Mercado',
      verdict: Verdict.review,
      score: null,
      age: 'hace 17 min',
      merchant: 'Supermercado Central',
      category: 'Mercado',
      document: '•••• 1180',
    ),
    _case(
      id: '#C66A2F',
      customer: 'Felipe A.',
      amount: 4700000,
      type: 'Restaurantes',
      verdict: Verdict.review,
      score: 0.78,
      age: 'hace 21 min',
      merchant: 'Restaurante La Brasa',
      category: 'Restaurantes',
      document: '•••• 5529',
    ),
    _case(
      id: '#4B8E90',
      customer: 'Laura C.',
      amount: 980000,
      type: 'Compra en línea',
      verdict: Verdict.review,
      score: 0.69,
      age: 'hace 26 min',
      document: '•••• 8836',
    ),
  ];
}

RuleCondition _c(String feature, String op, String value) =>
    RuleCondition(feature: feature, operator: op, value: value);

RuleVersion _v(
  int number,
  RuleAction action,
  RuleStatus status,
  List<RuleCondition> conditions,
  String by,
  String updated, {
  int? hits,
  double? precision,
  bool backtest = false,
  int shadowDays = 0,
}) {
  return RuleVersion(
    number: number,
    action: action,
    status: status,
    conditions: conditions,
    createdBy: by,
    updatedLabel: updated,
    hits7d: hits,
    precision: precision,
    backtestDone: backtest,
    shadowDays: shadowDays,
  );
}

/// The eight rules of the list. Each keeps its version history.
List<Rule> initialRules() {
  return [
    Rule(
      code: 'SCORE_BLOCK',
      description: 'Score del modelo ≥ 0,90',
      versions: [
        _v(
          2,
          RuleAction.block,
          RuleStatus.active,
          [_c('score', '≥', '0,90')],
          'Laura Méndez',
          'hace 9 d · Laura Méndez',
          hits: 312,
          precision: 0.88,
          backtest: true,
        ),
      ],
    ),
    Rule(
      code: 'SCORE_REVIEW',
      description: 'Score del modelo ≥ 0,60',
      versions: [
        _v(
          4,
          RuleAction.review,
          RuleStatus.active,
          [_c('score', '≥', '0,60')],
          'Laura Méndez',
          'hace 3 d · Laura Méndez',
          hits: 2410,
          precision: 0.41,
          backtest: true,
        ),
      ],
    ),
    Rule(
      code: 'HIGH_AMOUNT_NEW_DEVICE',
      description: 'Monto ≥ \$ 3.000.000 y dispositivo nuevo',
      versions: [
        _v(
          3,
          RuleAction.review,
          RuleStatus.active,
          [_c('amount', '≥', '\$ 3.000.000'), _c('is_new_device', '=', 'Sí')],
          'Diego Salazar',
          'hace 12 d · Diego Salazar',
          hits: 486,
          precision: 0.57,
          backtest: true,
        ),
      ],
    ),
    Rule(
      code: 'VELOCITY_1H',
      description: 'Más de 5 transacciones en 1 hora',
      versions: [
        _v(
          1,
          RuleAction.block,
          RuleStatus.active,
          [_c('tx_count_1h', '>', '5')],
          'Diego Salazar',
          'hace 20 d · Diego Salazar',
          hits: 97,
          precision: 0.74,
          backtest: true,
        ),
      ],
    ),
    Rule(
      code: 'FAR_FROM_HOME',
      description: 'Distancia a su ciudad > 300 km',
      versions: [
        _v(
          1,
          RuleAction.review,
          RuleStatus.shadow,
          [_c('km_from_home', '>', '300')],
          'Laura Méndez',
          'ayer · Laura Méndez',
          hits: 1102,
          precision: 0.33,
          backtest: true,
          shadowDays: 5,
        ),
      ],
    ),
    Rule(
      code: 'NIGHT_TRANSFER',
      description: 'Transferencia de noche ≥ \$ 2.000.000',
      versions: [
        _v(
          1,
          RuleAction.review,
          RuleStatus.active,
          [
            _c('type', '=', 'Transferencia'),
            _c('is_night', '=', 'Sí'),
            _c('amount', '≥', '\$ 5.000.000'),
          ],
          'Laura Méndez',
          'hace 30 d · Laura Méndez',
          hits: 18,
          precision: 0.61,
          backtest: true,
        ),
        _v(
          2,
          RuleAction.review,
          RuleStatus.pendingApproval,
          [
            _c('type', '=', 'Transferencia'),
            _c('is_night', '=', 'Sí'),
            _c('amount', '≥', '\$ 2.000.000'),
          ],
          'Laura Méndez',
          'hoy · Laura Méndez',
          hits: 61,
          precision: 0.52,
          backtest: true,
          shadowDays: 5,
        ),
      ],
    ),
    Rule(
      code: 'ATO_PASSWORD_RESET',
      description: 'Cambio de clave en 24 h y transferencia',
      versions: [
        _v(
          1,
          RuleAction.block,
          RuleStatus.draft,
          [
            _c('password_changed_24h', '=', 'Sí'),
            _c('type', '=', 'Transferencia'),
          ],
          'Diego Salazar',
          'hoy · Diego Salazar',
        ),
      ],
    ),
    Rule(
      code: 'VELOCITY_5M',
      description: 'Más de 3 transacciones en 5 minutos',
      versions: [
        _v(
          5,
          RuleAction.block,
          RuleStatus.retired,
          [_c('tx_count_5m', '>', '3')],
          'Laura Méndez',
          'hace 2 meses · Laura Méndez',
        ),
      ],
    ),
  ];
}

List<ModelVersion> initialModels() {
  return const [
    ModelVersion(
      name: 'v5',
      trainedAt: '25 oct · 02:00',
      origin: 'Automático',
      prAuc: 0.81,
      recall: 0.74,
      status: ModelStatus.active,
    ),
    ModelVersion(
      name: 'v4',
      trainedAt: '24 oct · 16:40',
      origin: 'Manual · Laura C.',
      prAuc: 0.83,
      recall: 0.70,
      status: ModelStatus.candidate,
    ),
    ModelVersion(
      name: 'v3',
      trainedAt: '24 oct · 02:00',
      origin: 'Automático',
      prAuc: 0.79,
      recall: 0.72,
      status: ModelStatus.retired,
    ),
    ModelVersion(
      name: 'v2',
      trainedAt: '23 oct · 02:00',
      origin: 'Automático',
      prAuc: 0.78,
      recall: 0.72,
      status: ModelStatus.retired,
    ),
    ModelVersion(
      name: 'v1',
      trainedAt: '22 oct · 02:00',
      origin: 'Automático',
      prAuc: 0.77,
      recall: 0.71,
      status: ModelStatus.retired,
    ),
  ];
}

/// Features offered by the rule editor (docs/features.md, catalog v1).
const List<String> featureNames = [
  'amount',
  'amount_vs_avg_30d',
  'spend_24h',
  'tx_count_5m',
  'tx_count_1h',
  'same_amount_counterparty_10m',
  'minutes_since_prev',
  'km_from_home',
  'km_from_prev',
  'implied_speed_kmh',
  'hour_of_day',
  'is_night',
  'category',
  'is_new_device',
  'device_age_days',
  'customers_on_device',
  'failed_logins_1h',
  'password_changed_24h',
  'account_age_days',
  'score',
];

/// Operators of `condition_json`.
const List<String> ruleOperators = ['>', '≥', '<', '≤', '=', '≠', 'in'];

/// Most influential variables of the active model (label, share 0–1).
const List<(String, double)> featureImportance = [
  ('Monto vs. promedio 30 días', 1.0),
  ('Dispositivo nuevo', 0.78),
  ('Transacciones última hora', 0.62),
  ('Velocidad entre ubicaciones', 0.49),
  ('Horario nocturno', 0.36),
  ('Inicios de sesión fallidos', 0.27),
];

const List<SimScenario> simScenarios = [
  SimScenario(
    code: 'NORMAL',
    title: 'Normal',
    subtitle: 'Hábitos normales',
    description:
        'Compras y transferencias habituales del cliente, a su hora '
        'y desde su ciudad.',
  ),
  SimScenario(
    code: 'CARD_FRAUD',
    title: 'Fraude con tarjeta',
    subtitle: 'Compras de noche',
    description:
        'Compras repetidas por montos altos, de madrugada y en '
        'comercios en línea.',
  ),
  SimScenario(
    code: 'ACCOUNT_TAKEOVER',
    title: 'Toma de cuenta',
    subtitle: 'Clave y equipo nuevos',
    description:
        'Inicios fallidos, cambio de clave y un dispositivo nuevo; '
        'después, compras grandes desde otra ciudad.',
  ),
  SimScenario(
    code: 'ORIGINATION',
    title: 'Originación',
    subtitle: 'Cliente recién creado',
    description:
        'Un cliente recién creado que mueve montos altos desde el '
        'primer día.',
  ),
];

/// Decisions per hour for the dashboard chart (px heights from the design).
const List<HourlyDecisions> hourlyDecisions = [
  HourlyDecisions(22, 3, 4),
  HourlyDecisions(16, 3, 2),
  HourlyDecisions(12, 3, 6),
  HourlyDecisions(10, 3, 4),
  HourlyDecisions(9, 3, 2),
  HourlyDecisions(12, 3, 2),
  HourlyDecisions(25, 4, 4),
  HourlyDecisions(48, 7, 6),
  HourlyDecisions(69, 10, 2),
  HourlyDecisions(81, 11, 4),
  HourlyDecisions(87, 12, 2),
  HourlyDecisions(91, 8, 2),
  HourlyDecisions(94, 8, 6),
  HourlyDecisions(89, 8, 2),
  HourlyDecisions(86, 12, 2),
  HourlyDecisions(83, 12, 4),
  HourlyDecisions(87, 12, 2),
  HourlyDecisions(91, 8, 6),
  HourlyDecisions(79, 11, 4),
  HourlyDecisions(66, 9, 2),
  HourlyDecisions(51, 7, 2),
  HourlyDecisions(43, 6, 4),
  HourlyDecisions(36, 5, 6),
  HourlyDecisions(28, 4, 2),
];

/// Deterministic generator behind the simulator. Event [index] of a run for
/// [scenarioCode] always yields the same transaction, so runs are testable.
SimEvent simulateEvent({
  required String scenarioCode,
  required String customer,
  required int index,
}) {
  final seed = (index * 7919 + scenarioCode.length * 104729) % 100;
  final risky = switch (scenarioCode) {
    'CARD_FRAUD' => seed < 65,
    'ACCOUNT_TAKEOVER' => seed < 55,
    'ORIGINATION' => seed < 45,
    _ => seed < 8,
  };
  final transfer = risky && seed % 2 == 0;
  final amounts = risky
      ? [6400000, 4900000, 2100000, 3200000, 1850000]
      : [85000, 230000, 1150000, 47500, 610000];
  final amount = amounts[index % amounts.length];
  final Verdict verdict;
  if (!risky) {
    verdict = Verdict.approve;
  } else if (amount >= 6000000 || seed < 20) {
    verdict = Verdict.block;
  } else {
    verdict = Verdict.review;
  }
  final totalSeconds = 9 * 3600 + 51 * 60 + 30 + index ~/ 2;
  final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return SimEvent(
    time: '$h:$m:$s',
    customer: customer,
    type: transfer ? 'Transferencia' : 'Compra',
    amount: amount,
    verdict: verdict,
    latencyMs: 85 + (seed * 3) % 90,
  );
}
