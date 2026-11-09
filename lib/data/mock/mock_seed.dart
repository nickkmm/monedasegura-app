import '../models/models.dart';

/// A fixed UUID; [group] tells the entity kinds apart.
String _uuid(String group, int n) =>
    '$group-0000-4000-8000-${n.toString().padLeft(12, '0')}';

final _valentina = AppUser(
  id: _uuid('a1000000', 1),
  fullName: 'Valentina Ríos',
  email: 'valentina.rios@monedasegura.co',
  active: true,
  roles: const [RoleCode.ADMIN],
);
final _lauraMendez = AppUser(
  id: _uuid('a1000000', 2),
  fullName: 'Laura Méndez',
  email: 'laura.mendez@monedasegura.co',
  active: true,
  roles: const [RoleCode.RISK_LEAD],
);
final _diego = AppUser(
  id: _uuid('a1000000', 3),
  fullName: 'Diego Salazar',
  email: 'diego.salazar@monedasegura.co',
  active: true,
  roles: const [RoleCode.RISK_LEAD],
);
final _camilo = AppUser(
  id: _uuid('a1000000', 4),
  fullName: 'Camilo Torres',
  email: 'camilo.torres@monedasegura.co',
  active: true,
  roles: const [RoleCode.ANALYST],
);
final _lauraCardenas = AppUser(
  id: _uuid('a1000000', 5),
  fullName: 'Laura Cárdenas',
  email: 'laura.cardenas@monedasegura.co',
  active: true,
  roles: const [RoleCode.DATA_SCIENTIST],
);
final _mateo = AppUser(
  id: _uuid('a1000000', 6),
  fullName: 'Mateo Rojas',
  email: 'mateo.rojas@monedasegura.co',
  active: true,
  roles: const [RoleCode.AUDITOR],
);

/// Latitude and longitude of each customer's home city.
const _homeCoordinates = {
  'Medellín': (6.2442, -75.5812),
  'Cali': (3.4516, -76.5320),
  'Bogotá': (4.7110, -74.0721),
  'Barranquilla': (10.9685, -74.7813),
  'Bucaramanga': (7.1193, -73.1227),
  'Cartagena': (10.3910, -75.4794),
  'Pereira': (4.8133, -75.6961),
};

/// The active and shadow versions a decision evaluates, in hit order.
const _evaluatedVersions = [
  ('SCORE_BLOCK', 2),
  ('SCORE_REVIEW', 4),
  ('HIGH_AMOUNT_NEW_DEVICE', 3),
  ('VELOCITY_1H', 1),
  ('NIGHT_TRANSFER', 1),
  ('FAR_FROM_HOME', 1),
];

const _featureImportance = {
  'amount_vs_avg_30d': 0.284,
  'is_new_device': 0.2216,
  'tx_count_1h': 0.176,
  'implied_speed_kmh': 0.139,
  'is_night': 0.1024,
  'failed_logins_1h': 0.077,
};

const _hourly = [
  HourBucket(approve: 22, review: 3, block: 4),
  HourBucket(approve: 16, review: 3, block: 2),
  HourBucket(approve: 12, review: 3, block: 6),
  HourBucket(approve: 10, review: 3, block: 4),
  HourBucket(approve: 9, review: 3, block: 2),
  HourBucket(approve: 12, review: 3, block: 2),
  HourBucket(approve: 25, review: 4, block: 4),
  HourBucket(approve: 48, review: 7, block: 6),
  HourBucket(approve: 69, review: 10, block: 2),
  HourBucket(approve: 81, review: 11, block: 4),
  HourBucket(approve: 87, review: 12, block: 2),
  HourBucket(approve: 91, review: 8, block: 2),
  HourBucket(approve: 94, review: 8, block: 6),
  HourBucket(approve: 89, review: 8, block: 2),
  HourBucket(approve: 86, review: 12, block: 2),
  HourBucket(approve: 83, review: 12, block: 4),
  HourBucket(approve: 87, review: 12, block: 2),
  HourBucket(approve: 91, review: 8, block: 6),
  HourBucket(approve: 79, review: 11, block: 4),
  HourBucket(approve: 66, review: 9, block: 2),
  HourBucket(approve: 51, review: 7, block: 2),
  HourBucket(approve: 43, review: 6, block: 4),
  HourBucket(approve: 36, review: 5, block: 6),
  HourBucket(approve: 28, review: 4, block: 2),
];

/// One row of the case tables; the seed derives the case's records from it.
class _CaseRow {
  const _CaseRow({
    required this.id,
    required this.customer,
    required this.amount,
    required this.type,
    this.category,
    this.counterparty,
    this.score,
    required this.verdict,
    required this.age,
    this.status = CaseStatus.OPEN,
    this.assignedTo,
    this.label,
    this.resolvedAge,
    required this.amountVsAvg,
    required this.isNewDevice,
    required this.kmFromHome,
    required this.txCount1h,
    required this.latencyMs,
    this.deviceFirstSeenToday,
    this.hitVersions = _evaluatedVersions,
  });

  final String id;
  final String customer;
  final int amount;
  final TransactionType type;
  final String? category;
  final String? counterparty;
  final double? score;
  final Verdict verdict;
  final Duration age;
  final CaseStatus status;
  final UserRef? assignedTo;
  final CaseLabel? label;
  final Duration? resolvedAge;
  final double amountVsAvg;
  final bool isNewDevice;
  final int kmFromHome;
  final int txCount1h;
  final int latencyMs;
  final (int hour, int minute)? deviceFirstSeenToday;
  final List<(String, int)> hitVersions;
}

/// The prototype's in-memory data. Every time is relative to the `now` given
/// to [build], except customer `createdAt`.
class MockSeed {
  MockSeed._({
    required this.users,
    required this.customers,
    required this.devices,
    required this.transactions,
    required this.decisions,
    required this.cases,
    required this.rules,
    required this.models,
    required this.metrics,
  });

  /// A prototype value, not a real credential.
  static const demoPassword = 'MonedaSegura2026';

  /// Latitude and longitude of each customer's home city.
  static const homeCoordinates = _homeCoordinates;

  /// The seed's id shape, for records created after it.
  static String uuid(String group, int n) => _uuid(group, n);

  final List<AppUser> users;
  final List<Customer> customers;
  final List<Device> devices;
  final List<Transaction> transactions;
  final List<Decision> decisions;
  final List<CaseView> cases;
  final List<RuleView> rules;
  final List<ModelVersion> models;
  final DashboardMetrics metrics;
  final int simulationRunCount = 17;

  static MockSeed build(DateTime now) {
    final customers = _buildCustomers();
    final rules = _buildRules(now);

    final devices = <Device>[];
    final transactions = <Transaction>[];
    final decisions = <Decision>[];
    final cases = <CaseView>[];

    final rows = _caseRows();
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final customer = customers.firstWhere(
        (candidate) => candidate.maskedName == row.customer,
      );
      final occurredAt = now.subtract(row.age);

      final device = Device(
        id: _uuid('b1000000', i + 1),
        fingerprint: 'fp-${row.id.substring(0, 6)}',
        os: i.isEven ? DeviceOs.ANDROID : DeviceOs.IOS,
        firstSeenAt: _deviceFirstSeenAt(row, i, occurredAt, now),
      );

      final home = _homeCoordinates[customer.homeCity]!;
      final transaction = Transaction(
        id: _uuid('b2000000', i + 1),
        customerId: customer.id,
        deviceId: device.id,
        type: row.type,
        category: row.category,
        amount: row.amount,
        // One degree of latitude is about 111 km.
        latitude: home.$1 - row.kmFromHome / 111,
        longitude: home.$2,
        counterparty: row.counterparty,
        source: TransactionSource.SIMULATOR,
        scenario: _scenarioOf(row),
        occurredAt: occurredAt,
      );

      // `is_night` is fixed rather than derived, because times move with `now`.
      final features = <String, Object>{
        'amount': row.amount,
        'amount_vs_avg_30d': row.amountVsAvg,
        'is_new_device': row.isNewDevice,
        'km_from_home': row.kmFromHome,
        'tx_count_1h': row.txCount1h,
        'is_night': false,
      };

      final decision = Decision(
        id: _uuid('b3000000', i + 1),
        transactionId: transaction.id,
        kind: DecisionKind.ORIGINAL,
        verdict: row.verdict,
        score: row.score,
        modelVersion: row.score == null ? null : 'v5',
        degraded: row.score == null,
        features: features,
        ruleHits: [
          for (final (code, version) in row.hitVersions)
            _hit(rules, code, version, features, row.score),
        ],
        latencyMs: row.latencyMs,
        decidedAt: occurredAt,
        caseId: row.id,
      );

      final fraudCase = FraudCase(
        id: row.id,
        decisionId: decision.id,
        status: row.status,
        label: row.label,
        assignedTo: row.assignedTo,
        openedAt: occurredAt,
        resolvedAt: row.resolvedAge == null
            ? null
            : now.subtract(row.resolvedAge!),
      );

      devices.add(device);
      transactions.add(transaction);
      decisions.add(decision);
      cases.add(
        CaseView(
          fraudCase: fraudCase,
          transaction: transaction,
          decision: decision,
          customer: customer,
          device: device,
        ),
      );
    }

    return MockSeed._(
      users: [
        _valentina,
        _lauraMendez,
        _diego,
        _camilo,
        _lauraCardenas,
        _mateo,
      ],
      customers: customers,
      devices: devices,
      transactions: transactions,
      decisions: decisions,
      cases: cases,
      rules: rules,
      models: _buildModels(now),
      metrics: _buildMetrics(now),
    );
  }

  /// That clock time on `now`'s date, clamped to `now` when it is still to come.
  static DateTime _todayAt(DateTime now, int hour, int minute) {
    final time = DateTime(now.year, now.month, now.day, hour, minute);
    return time.isAfter(now) ? now : time;
  }

  static DateTime _daysAgoAt(DateTime now, int days, int hour, int minute) =>
      DateTime(now.year, now.month, now.day - days, hour, minute);

  static DateTime _deviceFirstSeenAt(
    _CaseRow row,
    int index,
    DateTime occurredAt,
    DateTime now,
  ) {
    final today = row.deviceFirstSeenToday;
    if (today != null) {
      final time = _todayAt(now, today.$1, today.$2);
      return time.isAfter(occurredAt) ? occurredAt : time;
    }
    return row.isNewDevice
        ? occurredAt.subtract(const Duration(minutes: 5))
        : now.subtract(Duration(days: 90 + 30 * index));
  }

  static Scenario _scenarioOf(_CaseRow row) {
    if (row.type == TransactionType.TRANSFER) return Scenario.ATO;
    if (row.category == 'shopping_net') return Scenario.CARD_FRAUD;
    return Scenario.NORMAL;
  }

  static RuleHit _hit(
    List<RuleView> rules,
    String code,
    int versionNumber,
    Map<String, Object> features,
    double? score,
  ) {
    final view = rules.firstWhere((rule) => rule.rule.code == code);
    final version = view.version(versionNumber)!;
    return RuleHit(
      ruleId: view.rule.id,
      ruleCode: code,
      version: versionNumber,
      action: version.action,
      matched: version.conditions.every(
        (condition) => conditionHolds(condition, features, score),
      ),
      shadow: version.status == RuleStatus.SHADOW,
    );
  }

  /// A rule on `score` never matches when the score is null.
  static bool conditionHolds(
    Condition condition,
    Map<String, Object> features,
    double? score,
  ) {
    final actual = condition.feature == 'score'
        ? score
        : features[condition.feature];
    if (actual == null) return false;
    final expected = condition.value;
    return switch (condition.op) {
      ConditionOp.gt => (actual as num) > (expected as num),
      ConditionOp.gte => (actual as num) >= (expected as num),
      ConditionOp.lt => (actual as num) < (expected as num),
      ConditionOp.lte => (actual as num) <= (expected as num),
      ConditionOp.eq => actual == expected,
      ConditionOp.neq => actual != expected,
      ConditionOp.inList => (expected as List).contains(actual),
    };
  }

  static List<Customer> _buildCustomers() {
    Customer customer(
      int n,
      String name,
      String document,
      String city,
      DateTime createdAt,
      int transactions30d, [
      int previousFrauds = 0,
    ]) {
      return Customer(
        id: _uuid('a2000000', n),
        maskedName: name,
        maskedDocument: document,
        homeCity: city,
        createdAt: createdAt,
        transactions30d: transactions30d,
        previousFrauds: previousFrauds,
      );
    }

    return [
      customer(
        1,
        'Mariana G.',
        '****1907',
        'Medellín',
        DateTime(2022, 6, 8),
        34,
      ),
      customer(2, 'Julián R.', '****5532', 'Cali', DateTime(2021, 11, 23), 52),
      customer(3, 'Andrés P.', '****4821', 'Bogotá', DateTime(2023, 3, 14), 41),
      customer(
        4,
        'Camila O.',
        '****7764',
        'Barranquilla',
        DateTime(2024, 1, 17),
        18,
      ),
      customer(
        5,
        'Santiago M.',
        '****2289',
        'Bogotá',
        DateTime(2021, 4, 2),
        27,
      ),
      customer(
        6,
        'Daniela C.',
        '****6043',
        'Bucaramanga',
        DateTime(2022, 9, 30),
        45,
      ),
      customer(7, 'Felipe A.', '****3175', 'Cali', DateTime(2023, 7, 11), 23),
      customer(8, 'Laura C.', '****9418', 'Medellín', DateTime(2024, 5, 6), 12),
      customer(
        9,
        'Tomás H.',
        '****0652',
        'Cartagena',
        DateTime(2022, 2, 19),
        38,
        1,
      ),
      customer(
        10,
        'Sofía V.',
        '****3310',
        'Pereira',
        DateTime(2023, 10, 25),
        60,
      ),
    ];
  }

  static List<_CaseRow> _caseRows() {
    return [
      _CaseRow(
        id: '7f0b6a21-4c8d-4e1f-a2b3-1d2e3f4a5b60',
        customer: 'Mariana G.',
        amount: 8900000,
        type: TransactionType.TRANSFER,
        counterparty: '****4417',
        score: 0.96,
        verdict: Verdict.BLOCK,
        age: const Duration(minutes: 1),
        amountVsAvg: 7.2,
        isNewDevice: true,
        kmFromHome: 38,
        txCount1h: 2,
        latencyMs: 118,
      ),
      _CaseRow(
        id: '3a91c2d4-7e10-4b6a-8f25-2e3f4a5b6c71',
        customer: 'Julián R.',
        amount: 1240000,
        type: TransactionType.DEBIT,
        category: 'shopping_net',
        score: 0.71,
        verdict: Verdict.REVIEW,
        age: const Duration(minutes: 3),
        status: CaseStatus.IN_REVIEW,
        assignedTo: _camilo.ref,
        amountVsAvg: 2.6,
        isNewDevice: false,
        kmFromHome: 12,
        txCount1h: 2,
        latencyMs: 96,
      ),
      // The Figma detail screen, with exactly the four hits it shows.
      const _CaseRow(
        id: 'b204e7c1-3f5a-4d2e-9b8a-6c7d8e9f0a12',
        customer: 'Andrés P.',
        amount: 3250000,
        type: TransactionType.DEBIT,
        category: 'shopping_net',
        counterparty: 'ElectroHogar Bogotá',
        score: 0.67,
        verdict: Verdict.REVIEW,
        age: Duration(minutes: 4),
        amountVsAvg: 4.1,
        isNewDevice: true,
        kmFromHome: 412,
        txCount1h: 3,
        latencyMs: 142,
        deviceFirstSeenToday: (9, 30),
        hitVersions: [
          ('SCORE_REVIEW', 4),
          ('HIGH_AMOUNT_NEW_DEVICE', 3),
          ('VELOCITY_1H', 1),
          ('FAR_FROM_HOME', 1),
        ],
      ),
      const _CaseRow(
        id: '5d7a13e8-92b4-4c07-b1d6-3f4a5b6c7d82',
        customer: 'Camila O.',
        amount: 650000,
        type: TransactionType.DEBIT,
        category: 'gas_transport',
        score: 0.63,
        verdict: Verdict.REVIEW,
        age: Duration(minutes: 9),
        amountVsAvg: 1.8,
        isNewDevice: false,
        kmFromHome: 24,
        txCount1h: 1,
        latencyMs: 74,
      ),
      const _CaseRow(
        id: 'e1c0489a-1d36-4f82-9e47-4a5b6c7d8e93',
        customer: 'Santiago M.',
        amount: 12400000,
        type: TransactionType.TRANSFER,
        counterparty: '****8120',
        score: 0.92,
        verdict: Verdict.BLOCK,
        age: Duration(minutes: 12),
        amountVsAvg: 9.5,
        isNewDevice: true,
        kmFromHome: 420,
        txCount1h: 4,
        latencyMs: 163,
      ),
      const _CaseRow(
        id: '09f35b67-a5c2-4d19-8c3e-5b6c7d8e9fa4',
        customer: 'Daniela C.',
        amount: 3180000,
        type: TransactionType.DEBIT,
        category: 'grocery_pos',
        verdict: Verdict.REVIEW,
        age: Duration(minutes: 17),
        amountVsAvg: 4.9,
        isNewDevice: true,
        kmFromHome: 6,
        txCount1h: 2,
        latencyMs: 188,
      ),
      _CaseRow(
        id: 'c66a2f30-6b7e-4a58-b092-6c7d8e9fa0b5',
        customer: 'Felipe A.',
        amount: 4700000,
        type: TransactionType.DEBIT,
        category: 'food_dining',
        score: 0.78,
        verdict: Verdict.REVIEW,
        age: const Duration(minutes: 21),
        status: CaseStatus.IN_REVIEW,
        assignedTo: _valentina.ref,
        amountVsAvg: 4.4,
        isNewDevice: true,
        kmFromHome: 310,
        txCount1h: 3,
        latencyMs: 131,
      ),
      const _CaseRow(
        id: '4b8e90f5-c218-4e63-a7d4-7d8e9fa0b1c6',
        customer: 'Laura C.',
        amount: 980000,
        type: TransactionType.DEBIT,
        category: 'shopping_net',
        score: 0.69,
        verdict: Verdict.REVIEW,
        age: Duration(minutes: 26),
        amountVsAvg: 2.1,
        isNewDevice: false,
        kmFromHome: 45,
        txCount1h: 3,
        latencyMs: 88,
      ),
      const _CaseRow(
        id: 'a17d3c42-e9f1-4b70-96c5-8e9fa0b1c2d7',
        customer: 'Tomás H.',
        amount: 15000000,
        type: TransactionType.TRANSFER,
        counterparty: '****2765',
        score: 0.97,
        verdict: Verdict.BLOCK,
        age: Duration(minutes: 34),
        amountVsAvg: 11.3,
        isNewDevice: true,
        kmFromHome: 820,
        txCount1h: 6,
        latencyMs: 174,
      ),
      _CaseRow(
        id: 'd4e2f1b6-30a7-4c94-85e1-9fa0b1c2d3e8',
        customer: 'Julián R.',
        amount: 2300000,
        type: TransactionType.TRANSFER,
        counterparty: '****6093',
        score: 0.93,
        verdict: Verdict.BLOCK,
        age: const Duration(hours: 2, minutes: 40),
        status: CaseStatus.RESOLVED,
        assignedTo: _camilo.ref,
        label: CaseLabel.CONFIRMED_FRAUD,
        resolvedAge: const Duration(hours: 2),
        amountVsAvg: 3.1,
        isNewDevice: true,
        kmFromHome: 180,
        txCount1h: 2,
        latencyMs: 109,
      ),
      _CaseRow(
        id: '8c3b07a9-d462-4f1b-b3f8-a0b1c2d3e4f9',
        customer: 'Camila O.',
        amount: 410000,
        type: TransactionType.DEBIT,
        category: 'grocery_pos',
        score: 0.62,
        verdict: Verdict.REVIEW,
        age: const Duration(hours: 2),
        status: CaseStatus.RESOLVED,
        assignedTo: _camilo.ref,
        label: CaseLabel.DISMISSED,
        resolvedAge: const Duration(hours: 1, minutes: 20),
        amountVsAvg: 1.4,
        isNewDevice: false,
        kmFromHome: 9,
        txCount1h: 1,
        latencyMs: 62,
      ),
      _CaseRow(
        id: 'f09a5e13-5f8c-4a26-a906-b1c2d3e4f50a',
        customer: 'Felipe A.',
        amount: 5600000,
        type: TransactionType.DEBIT,
        category: 'shopping_net',
        score: 0.88,
        verdict: Verdict.REVIEW,
        age: const Duration(hours: 1, minutes: 10),
        status: CaseStatus.RESOLVED,
        assignedTo: _camilo.ref,
        label: CaseLabel.CONFIRMED_FRAUD,
        resolvedAge: const Duration(minutes: 35),
        amountVsAvg: 5.2,
        isNewDevice: true,
        kmFromHome: 455,
        txCount1h: 4,
        latencyMs: 147,
      ),
    ];
  }

  static List<RuleView> _buildRules(DateTime now) {
    final laura = _lauraMendez.ref;
    final diego = _diego.ref;
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    // True negatives fill up to the 1920 evaluated cases.
    BacktestCounts counts(int tp, int fp, int fn) => BacktestCounts(
      truePositives: tp,
      falsePositives: fp,
      falseNegatives: fn,
      trueNegatives: 1920 - tp - fp - fn,
    );

    RuleVersion version(
      String ruleId,
      int number,
      List<Condition> conditions,
      RuleAction action,
      RuleStatus status,
      UserRef createdBy,
      DateTime createdAt, {
      BacktestCounts? candidate,
      int? hits7d,
      ShadowStats? shadowStats,
    }) {
      // ACTIVE and RETIRED versions were approved by the other risk lead.
      final approved =
          status == RuleStatus.ACTIVE || status == RuleStatus.RETIRED;
      return RuleVersion(
        ruleId: ruleId,
        version: number,
        conditions: conditions,
        action: action,
        status: status,
        createdBy: createdBy,
        createdAt: createdAt,
        approvedBy: approved
            ? (createdBy.id == laura.id ? diego : laura)
            : null,
        approvedAt: approved ? createdAt.add(const Duration(days: 1)) : null,
        shadowStats: shadowStats,
        backtest: candidate == null
            ? null
            : Backtest(
                runAt: createdAt.add(const Duration(hours: 12)),
                casesEvaluated: 1920,
                candidate: candidate,
              ),
        hits7d: hits7d,
      );
    }

    RuleView view(
      int n,
      String code,
      String name,
      String description,
      List<RuleVersion> Function(String ruleId) versions,
    ) {
      final id = _uuid('c1000000', n);
      final built = versions(id);
      return RuleView(
        rule: Rule(
          id: id,
          code: code,
          name: name,
          description: description,
          createdAt: built.last.createdAt,
        ),
        versions: built,
      );
    }

    const scoreBlock = [Condition('score', ConditionOp.gte, 0.9)];
    const scoreReview = [Condition('score', ConditionOp.gte, 0.6)];
    const highAmount = [
      Condition('amount', ConditionOp.gte, 3000000),
      Condition('is_new_device', ConditionOp.eq, true),
    ];
    const velocity5m = [Condition('tx_count_5m', ConditionOp.gt, 3)];

    return [
      view(
        1,
        'SCORE_BLOCK',
        'Bloqueo por score alto',
        'Score del modelo ≥ 0,90',
        (id) => [
          version(
            id,
            2,
            scoreBlock,
            RuleAction.BLOCK,
            RuleStatus.ACTIVE,
            laura,
            daysAgo(9),
            candidate: counts(88, 12, 14),
            hits7d: 312,
          ),
          version(
            id,
            1,
            scoreBlock,
            RuleAction.BLOCK,
            RuleStatus.RETIRED,
            diego,
            daysAgo(60),
          ),
        ],
      ),
      view(
        2,
        'SCORE_REVIEW',
        'Revisión por score medio',
        'Score del modelo ≥ 0,60',
        (id) => [
          version(
            id,
            4,
            scoreReview,
            RuleAction.REVIEW,
            RuleStatus.ACTIVE,
            laura,
            daysAgo(3),
            candidate: counts(41, 59, 22),
            hits7d: 2410,
          ),
          for (final (number, age) in const [(3, 30), (2, 60), (1, 90)])
            version(
              id,
              number,
              scoreReview,
              RuleAction.REVIEW,
              RuleStatus.RETIRED,
              number.isOdd ? diego : laura,
              daysAgo(age),
            ),
        ],
      ),
      view(
        3,
        'HIGH_AMOUNT_NEW_DEVICE',
        'Monto alto en dispositivo nuevo',
        'Monto ≥ \$ 3.000.000 y dispositivo nuevo',
        (id) => [
          version(
            id,
            3,
            highAmount,
            RuleAction.REVIEW,
            RuleStatus.ACTIVE,
            diego,
            daysAgo(12),
            candidate: counts(57, 43, 18),
            hits7d: 486,
          ),
          for (final (number, age) in const [(2, 40), (1, 80)])
            version(
              id,
              number,
              highAmount,
              RuleAction.REVIEW,
              RuleStatus.RETIRED,
              number.isOdd ? laura : diego,
              daysAgo(age),
            ),
        ],
      ),
      view(
        4,
        'VELOCITY_1H',
        'Velocidad en una hora',
        'Más de 5 transacciones en 1 hora',
        (id) => [
          version(
            id,
            1,
            const [Condition('tx_count_1h', ConditionOp.gt, 5)],
            RuleAction.BLOCK,
            RuleStatus.ACTIVE,
            diego,
            daysAgo(20),
            candidate: counts(74, 26, 11),
            hits7d: 97,
          ),
        ],
      ),
      view(
        5,
        'FAR_FROM_HOME',
        'Lejos de su ciudad',
        'Distancia a su ciudad > 300 km',
        (id) => [
          version(
            id,
            1,
            const [Condition('km_from_home', ConditionOp.gt, 300)],
            RuleAction.REVIEW,
            RuleStatus.SHADOW,
            laura,
            daysAgo(1),
            candidate: counts(33, 67, 30),
            hits7d: 1102,
            shadowStats: ShadowStats(
              since: daysAgo(1),
              evaluated: 9800,
              matched: 1102,
              verdictChanges: 14,
            ),
          ),
        ],
      ),
      view(
        6,
        'NIGHT_TRANSFER',
        'Transferencia nocturna de monto alto',
        'Transferencia de noche ≥ \$ 2.000.000',
        (id) => [
          RuleVersion(
            ruleId: id,
            version: 2,
            conditions: const [
              Condition('is_night', ConditionOp.eq, true),
              Condition('amount', ConditionOp.gte, 2000000),
            ],
            action: RuleAction.REVIEW,
            status: RuleStatus.PENDING_APPROVAL,
            createdBy: laura,
            createdAt: daysAgo(6),
            shadowStats: ShadowStats(
              since: daysAgo(5),
              evaluated: 4200,
              matched: 61,
              verdictChanges: 0,
            ),
            backtest: Backtest(
              runAt: _todayAt(now, 8, 0),
              casesEvaluated: 1920,
              candidate: counts(41, 38, 22),
              active: counts(32, 9, 31),
              systemRecallBefore: 0.74,
              systemRecallAfter: 0.77,
            ),
            hits7d: 61,
            submittedAt: _todayAt(now, 8, 10),
          ),
          version(
            id,
            1,
            const [
              Condition('is_night', ConditionOp.eq, true),
              Condition('amount', ConditionOp.gte, 5000000),
            ],
            RuleAction.REVIEW,
            RuleStatus.ACTIVE,
            laura,
            daysAgo(45),
            candidate: counts(32, 9, 31),
          ),
        ],
      ),
      view(
        7,
        'ATO_PASSWORD_RESET',
        'Cambio de clave y equipo nuevo',
        'Cambio de clave en 24 h y transferencia',
        (id) => [
          version(
            id,
            1,
            const [
              Condition('password_changed_24h', ConditionOp.eq, true),
              Condition('is_new_device', ConditionOp.eq, true),
            ],
            RuleAction.BLOCK,
            RuleStatus.DRAFT,
            diego,
            _todayAt(now, 7, 50),
          ),
        ],
      ),
      view(
        8,
        'VELOCITY_5M',
        'Velocidad en cinco minutos',
        'Más de 3 transacciones en 5 minutos',
        (id) => [
          for (final (number, age) in const [
            (5, 70),
            (4, 100),
            (3, 130),
            (2, 160),
            (1, 190),
          ])
            version(
              id,
              number,
              velocity5m,
              RuleAction.BLOCK,
              RuleStatus.RETIRED,
              number.isOdd ? laura : diego,
              daysAgo(age),
            ),
        ],
      ),
    ];
  }

  static List<ModelVersion> _buildModels(DateTime now) {
    QualityGate gate({required bool recallNotWorse}) => QualityGate(
      passed: recallNotWorse,
      checks: [
        (name: 'MIN_NEW_LABELS', passed: true),
        (name: 'PR_AUC_NOT_WORSE', passed: true),
        (name: 'RECALL_NOT_WORSE', passed: recallNotWorse),
      ],
    );

    ModelMetrics metrics(double prAuc, double recall, double precision) =>
        ModelMetrics(
          prAuc: prAuc,
          precision: precision,
          recall: recall,
          featureImportance: _featureImportance,
        );

    return [
      ModelVersion(
        id: _uuid('d1000000', 5),
        version: 'v5',
        trigger: ModelTrigger.SCHEDULED,
        status: ModelStatus.ACTIVE,
        metrics: metrics(0.81, 0.74, 0.62),
        qualityGate: gate(recallNotWorse: true),
        trainedAt: _todayAt(now, 2, 0),
        trainingRows: 182400,
        fraudsSeen: 1940,
      ),
      ModelVersion(
        id: _uuid('d1000000', 4),
        version: 'v4',
        trigger: ModelTrigger.MANUAL,
        trainedBy: _lauraCardenas.ref,
        status: ModelStatus.CANDIDATE,
        metrics: metrics(0.83, 0.70, 0.64),
        qualityGate: gate(recallNotWorse: false),
        trainedAt: _daysAgoAt(now, 1, 16, 40),
        trainingRows: 181000,
        fraudsSeen: 1880,
      ),
      ModelVersion(
        id: _uuid('d1000000', 3),
        version: 'v3',
        trigger: ModelTrigger.SCHEDULED,
        status: ModelStatus.RETIRED,
        metrics: metrics(0.79, 0.72, 0.61),
        trainedAt: _daysAgoAt(now, 1, 2, 0),
        trainingRows: 178000,
        fraudsSeen: 1820,
      ),
      ModelVersion(
        id: _uuid('d1000000', 2),
        version: 'v2',
        trigger: ModelTrigger.SCHEDULED,
        status: ModelStatus.RETIRED,
        metrics: metrics(0.78, 0.72, 0.60),
        trainedAt: _daysAgoAt(now, 2, 2, 0),
        trainingRows: 174000,
        fraudsSeen: 1760,
      ),
      ModelVersion(
        id: _uuid('d1000000', 1),
        version: 'v1',
        trigger: ModelTrigger.SCHEDULED,
        status: ModelStatus.RETIRED,
        metrics: metrics(0.77, 0.71, 0.59),
        trainedAt: _daysAgoAt(now, 3, 2, 0),
        trainingRows: 170000,
        fraudsSeen: 1700,
      ),
    ];
  }

  static DashboardMetrics _buildMetrics(DateTime now) {
    return DashboardMetrics(
      from: now.subtract(const Duration(hours: 24)),
      to: now.subtract(const Duration(seconds: 12)),
      decisions: 12480,
      verdicts: const {
        Verdict.APPROVE: 12229,
        Verdict.REVIEW: 214,
        Verdict.BLOCK: 37,
      },
      latencyP50: 64,
      latencyP95: 182,
      latencyP99: 310,
      degradedRate: 3 / 12480,
      openCases: 214,
      alerts: const [],
      previousDecisions: 11534,
      hourly: _hourly,
    );
  }
}
