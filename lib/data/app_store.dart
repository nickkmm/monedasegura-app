import 'dart:math';

import 'package:flutter/foundation.dart';

import 'domain_error.dart';
import 'mock/mock_seed.dart';
import 'models/models.dart';

const _maxNotesLength = 2000;
const _maxRuleNameLength = 120;
const _maxRejectionReasonLength = 1000;
const _backtestCases = 1920;
const _systemRecallBefore = 0.74;
const _defaultReviewThreshold = 0.6;
const _defaultBlockThreshold = 0.9;

/// Above every number in the seed, so a new id never repeats a seeded one.
const _firstRecordNumber = 1000;

final _ruleCodePattern = RegExp(r'^[A-Z][A-Z0-9_]{2,39}$');

/// The queue order of `model.md` §7: BLOCK first, then score descending with
/// null last, then oldest first.
int _compareQueueOrder(CaseView a, CaseView b) {
  final byVerdict = b.verdict.index.compareTo(a.verdict.index);
  if (byVerdict != 0) return byVerdict;

  final scoreA = a.score;
  final scoreB = b.score;
  if (scoreA != scoreB) {
    if (scoreA == null) return 1;
    if (scoreB == null) return -1;
    return scoreB.compareTo(scoreA);
  }
  return a.openedAt.compareTo(b.openedAt);
}

int _versionNumber(ModelVersion model) => int.parse(model.version.substring(1));

double _plusOnePoint(double metric) => ((metric + 0.01) * 100).round() / 100;

double _twoDecimals(double value) => (value * 100).round() / 100;

/// `in` takes a list of strings, and `=` and `!=` on a string take one string.
bool _isValidCondition(Condition condition) {
  final op = condition.op;
  final value = condition.value;
  final isEquality = op == ConditionOp.eq || op == ConditionOp.neq;
  for (final feature in featureCatalog) {
    if (feature.name != condition.feature) continue;
    return switch (feature.type) {
      'boolean' => isEquality && value is bool,
      'string' =>
        op == ConditionOp.inList
            ? value is List<String>
            : isEquality && value is String,
      _ => op != ConditionOp.inList && value is num,
    };
  }
  return false;
}

void _requireValidConditions(List<Condition> conditions) {
  if (conditions.isEmpty) {
    throw const DomainError('invalid', 'A rule needs at least one condition');
  }
  for (final condition in conditions) {
    if (!_isValidCondition(condition)) {
      throw DomainError('invalid', 'Invalid condition on ${condition.feature}');
    }
  }
}

/// What a scenario decides about one simulated event, before the rules run.
typedef _SimulationProfile = ({
  TransactionType type,
  String? category,
  int amount,
  double score,
  Map<String, Object> features,
});

_SimulationProfile _drawProfile(Scenario scenario, int index, Random random) {
  int between(int min, int max) => min + random.nextInt(max - min + 1);
  // In hundredths, so both ends are reachable and the result has 2 decimals.
  double hundredths(int min, int max) => between(min, max) / 100;

  switch (scenario) {
    case Scenario.NORMAL:
      const categories = ['grocery_pos', 'gas_transport', 'food_dining'];
      return (
        type: TransactionType.DEBIT,
        category: categories[random.nextInt(categories.length)],
        amount: between(20000, 600000),
        score: hundredths(2, 35),
        features: {
          'is_night': false,
          'is_new_device': false,
          'km_from_home': between(0, 15),
        },
      );
    case Scenario.CARD_FRAUD:
      return (
        type: TransactionType.DEBIT,
        category: 'shopping_net',
        amount: between(800000, 6000000),
        score: hundredths(55, 98),
        features: {
          'is_night': true,
          'tx_count_5m': between(2, 6),
          'amount_vs_avg_30d': hundredths(300, 900),
        },
      );
    case Scenario.ATO:
      if (index % 3 != 0) {
        return (
          type: TransactionType.DEBIT,
          category: 'grocery_pos',
          amount: between(40000, 1200000),
          score: hundredths(5, 40),
          features: const {},
        );
      }
      return (
        type: TransactionType.TRANSFER,
        category: null,
        amount: between(2000000, 7000000),
        score: hundredths(62, 97),
        features: {
          'is_new_device': true,
          'password_changed_24h': true,
          'failed_logins_1h': between(3, 6),
          'km_from_home': between(250, 600),
        },
      );
    case Scenario.ORIGINATION:
      return (
        type: TransactionType.TRANSFER,
        category: null,
        amount: between(500000, 4000000),
        score: hundredths(40, 90),
        features: const {'account_age_days': 0, 'is_new_device': true},
      );
    case Scenario.DATASET_FRAUD:
      throw const DomainError(
        'invalid',
        'DATASET_FRAUD comes from the seed dataset, not the simulator',
      );
  }
}

/// Every feature of the catalog but `score`: the defaults of `features.md`,
/// then what the profile sets.
Map<String, Object> _simulatedFeatures(
  int amount,
  String? category,
  DateTime occurredAt,
  Customer customer,
  Map<String, Object> profile,
) {
  final hour = occurredAt.hour;
  return {
    'amount': amount,
    'amount_vs_avg_30d': 1.0,
    'spend_24h': 0,
    'tx_count_5m': 0,
    'tx_count_1h': 0,
    'same_amount_counterparty_10m': 0,
    'minutes_since_prev': 10080,
    'km_from_home': 0,
    'km_from_prev': 0,
    'implied_speed_kmh': 0,
    'hour_of_day': hour,
    'is_night': hour >= 22 || hour <= 3,
    'category': category ?? 'unknown',
    'is_new_device': true,
    'device_age_days': 0,
    'customers_on_device': 1,
    'failed_logins_1h': 0,
    'password_changed_24h': false,
    'account_age_days': occurredAt.difference(customer.createdAt).inDays,
    ...profile,
  };
}

/// The in-memory state of the prototype and the domain operations on it,
/// enforcing `model.md` the way the decision-api would.
class AppStore extends ChangeNotifier {
  AppStore({required MockSeed seed, required this._clock})
    : _users = List.of(seed.users),
      _customers = List.of(seed.customers),
      _devices = List.of(seed.devices),
      _transactions = List.of(seed.transactions),
      _decisions = List.of(seed.decisions),
      _cases = List.of(seed.cases),
      _models = List.of(seed.models),
      _rules = List.of(seed.rules),
      _metrics = seed.metrics,
      _runCount = seed.simulationRunCount;

  factory AppStore.seeded({DateTime Function()? clock}) {
    final resolvedClock = clock ?? DateTime.now;
    return AppStore(
      seed: MockSeed.build(resolvedClock()),
      clock: resolvedClock,
    );
  }

  final DateTime Function() _clock;
  final List<AppUser> _users;
  final List<Customer> _customers;
  final List<Device> _devices;
  final List<Transaction> _transactions;
  final List<Decision> _decisions;
  final List<CaseView> _cases;
  final List<ModelVersion> _models;
  final List<RuleView> _rules;
  DashboardMetrics _metrics;
  int _runCount;
  int _nextRecordNumber = _firstRecordNumber;
  AppUser? _currentUser;

  // Session

  DateTime get now => _clock();

  AppUser? get currentUser => _currentUser;

  bool can(PermissionCode p) => _currentUser?.can(p) ?? false;

  AppUser? signIn(String email, String password) {
    if (password != MockSeed.demoPassword) return null;

    final normalized = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.active && user.email.toLowerCase() == normalized) {
        _currentUser = user;
        notifyListeners();
        return user;
      }
    }
    return null;
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  List<AppUser> get users => List.unmodifiable(_users);

  AppUser? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  // Cases

  List<CaseView> get openCases => _queued(_isOpen);

  List<CaseView> get unassignedCases => _queued(_isUnassigned);

  List<CaseView> get myCases {
    final userId = _currentUser?.id;
    if (userId == null) return const [];
    return _queued(
      (view) =>
          view.status == CaseStatus.IN_REVIEW && view.assignedTo?.id == userId,
    );
  }

  List<CaseView> get resolvedToday {
    final today = now;
    final resolved = _cases.where((view) {
      final resolvedAt = view.resolvedAt;
      return view.status == CaseStatus.RESOLVED &&
          resolvedAt != null &&
          resolvedAt.year == today.year &&
          resolvedAt.month == today.month &&
          resolvedAt.day == today.day;
    }).toList();
    resolved.sort((a, b) => b.resolvedAt!.compareTo(a.resolvedAt!));
    return List.unmodifiable(resolved);
  }

  List<CaseView> get recentCases {
    final open = _cases.where(_isOpen).toList();
    open.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return List.unmodifiable(open.take(3));
  }

  CaseView? caseById(String id) {
    for (final view in _cases) {
      if (view.id == id) return view;
    }
    return null;
  }

  void takeCase(String caseId) {
    final user = _requirePermission(PermissionCode.CASE_RESOLVE);
    final index = _requireCaseIndex(caseId);
    final view = _cases[index];
    if (view.status != CaseStatus.OPEN) {
      throw DomainError('conflict', 'Case $caseId is not OPEN');
    }

    _cases[index] = view.copyWith(
      fraudCase: view.fraudCase.copyWith(
        status: CaseStatus.IN_REVIEW,
        assignedTo: user.ref,
      ),
    );
    notifyListeners();
  }

  void resolveCase(String caseId, CaseLabel label, {String? notes}) {
    final user = _requirePermission(PermissionCode.CASE_RESOLVE);
    final index = _requireCaseIndex(caseId);
    final view = _cases[index];
    if (view.status != CaseStatus.IN_REVIEW || view.assignedTo?.id != user.id) {
      throw DomainError(
        'conflict',
        'Case $caseId is not IN_REVIEW and assigned to the current user',
      );
    }
    if (notes != null && notes.length > _maxNotesLength) {
      throw const DomainError(
        'invalid',
        'Notes exceed $_maxNotesLength characters',
      );
    }

    // Labeling only: the decision and the transaction stay as they are.
    _cases[index] = view.copyWith(
      fraudCase: view.fraudCase.copyWith(
        status: CaseStatus.RESOLVED,
        label: label,
        notes: notes,
        resolvedAt: now,
      ),
    );
    notifyListeners();
  }

  // Customers

  List<Customer> get customers => List.unmodifiable(_customers);

  Customer? customerById(String id) {
    for (final customer in _customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  // Dashboard

  DashboardMetrics get metrics => _metrics;

  int get openCaseCount => _cases.where(_isOpen).length;

  int get unassignedCaseCount => _cases.where(_isUnassigned).length;

  // Models

  List<ModelVersion> get models {
    final newestFirst = List.of(_models);
    newestFirst.sort((a, b) => _versionNumber(b).compareTo(_versionNumber(a)));
    return List.unmodifiable(newestFirst);
  }

  ModelVersion? get activeModel {
    for (final model in _models) {
      if (model.status == ModelStatus.ACTIVE) return model;
    }
    return null;
  }

  ModelVersion retrainNow() {
    final user = _requirePermission(PermissionCode.MODEL_TRAIN);
    final active = activeModel;
    if (active == null) {
      throw const DomainError('conflict', 'There is no active model');
    }

    final activeMetrics = active.metrics;
    final metrics = ModelMetrics(
      prAuc: _plusOnePoint(activeMetrics.prAuc),
      precision: _plusOnePoint(activeMetrics.precision),
      recall: _plusOnePoint(activeMetrics.recall),
      featureImportance: activeMetrics.featureImportance,
    );
    final checks = [
      (name: 'MIN_NEW_LABELS', passed: true),
      (name: 'PR_AUC_NOT_WORSE', passed: metrics.prAuc >= activeMetrics.prAuc),
      (
        name: 'RECALL_NOT_WORSE',
        passed: metrics.recall >= activeMetrics.recall - 0.02,
      ),
    ];
    final passed = checks.every((check) => check.passed);

    final number =
        _models.map(_versionNumber).reduce((a, b) => a > b ? a : b) + 1;
    final created = ModelVersion(
      id: 'd1000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
      version: 'v$number',
      trigger: ModelTrigger.MANUAL,
      trainedBy: user.ref,
      status: passed ? ModelStatus.ACTIVE : ModelStatus.CANDIDATE,
      metrics: metrics,
      qualityGate: QualityGate(passed: passed, checks: checks),
      trainedAt: now,
      trainingRows: active.trainingRows + 1200,
      fraudsSeen: active.fraudsSeen + 30,
    );

    if (passed) {
      _models[_models.indexOf(active)] = active.copyWith(
        status: ModelStatus.RETIRED,
      );
    }
    _models.add(created);
    notifyListeners();
    return created;
  }

  // Rules

  List<RuleView> get rules => List.unmodifiable(_rules);

  RuleView? ruleById(String id) {
    for (final view in _rules) {
      if (view.rule.id == id) return view;
    }
    return null;
  }

  RuleView? ruleByCode(String code) {
    for (final view in _rules) {
      if (view.rule.code == code) return view;
    }
    return null;
  }

  RuleView createRule({
    required String code,
    required String name,
    String description = '',
    required List<Condition> conditions,
    required RuleAction action,
  }) {
    final user = _requirePermission(PermissionCode.RULE_WRITE);
    if (ruleByCode(code) != null) {
      throw DomainError('conflict', 'Rule code $code is taken');
    }
    if (!_ruleCodePattern.hasMatch(code)) {
      throw DomainError('invalid', 'Invalid rule code $code');
    }
    if (name.isEmpty || name.length > _maxRuleNameLength) {
      throw const DomainError(
        'invalid',
        'A rule name has 1 to $_maxRuleNameLength characters',
      );
    }
    _requireValidConditions(conditions);

    final createdAt = now;
    final id = MockSeed.uuid('c1000000', _takeRecordNumber());
    final view = RuleView(
      rule: Rule(
        id: id,
        code: code,
        name: name,
        description: description,
        createdAt: createdAt,
      ),
      versions: [
        RuleVersion(
          ruleId: id,
          version: 1,
          conditions: List.unmodifiable(conditions),
          action: action,
          status: RuleStatus.DRAFT,
          createdBy: user.ref,
          createdAt: createdAt,
        ),
      ],
    );
    _rules.add(view);
    notifyListeners();
    return view;
  }

  RuleVersion createVersion(String ruleId) {
    final user = _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final view = _rules[index];
    final hasOpenVersion = view.versions.any(
      (version) =>
          version.status == RuleStatus.DRAFT ||
          version.status == RuleStatus.SHADOW ||
          version.status == RuleStatus.PENDING_APPROVAL,
    );
    if (hasOpenVersion) {
      throw DomainError(
        'conflict',
        'Rule ${view.rule.code} already has a version in progress',
      );
    }

    final highest = view.versions.map((version) => version.version).reduce(max);
    final created = RuleVersion(
      ruleId: ruleId,
      version: highest + 1,
      conditions: view.latest.conditions,
      action: view.latest.action,
      status: RuleStatus.DRAFT,
      createdBy: user.ref,
      createdAt: now,
    );
    _rules[index] = view.copyWith(versions: [created, ...view.versions]);
    notifyListeners();
    return created;
  }

  void updateDraft(
    String ruleId,
    int version, {
    required List<Condition> conditions,
    required RuleAction action,
  }) {
    _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.DRAFT);
    _requireValidConditions(conditions);

    _putVersion(
      index,
      current.copyWith(
        conditions: List.unmodifiable(conditions),
        action: action,
        clearBacktest: true,
      ),
    );
    notifyListeners();
  }

  // Prototype-only: not in decision-api.yaml.
  void deleteDraft(String ruleId, int version) {
    _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.DRAFT);
    // A rejected draft has already run in shadow, so it has left history behind.
    if (current.rejectionReason != null) {
      throw DomainError(
        'conflict',
        'Version $version was rejected, so it has been evaluated',
      );
    }

    final view = _rules[index];
    final remaining = [
      for (final candidate in view.versions)
        if (candidate.version != version) candidate,
    ];
    if (remaining.isEmpty) {
      _rules.removeAt(index);
    } else {
      _rules[index] = view.copyWith(versions: remaining);
    }
    notifyListeners();
  }

  void startShadow(String ruleId, int version) {
    _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.DRAFT);

    _putVersion(
      index,
      current.copyWith(
        status: RuleStatus.SHADOW,
        shadowStats: ShadowStats(
          since: now,
          evaluated: 0,
          matched: 0,
          verdictChanges: 0,
        ),
      ),
    );
    notifyListeners();
  }

  /// A deterministic mock: the counts follow from the version's conditions.
  Backtest runBacktest(String ruleId, int version) {
    _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    if (current.status != RuleStatus.DRAFT &&
        current.status != RuleStatus.SHADOW) {
      throw DomainError('conflict', 'Version $version is not DRAFT or SHADOW');
    }

    var h = 0;
    for (final condition in current.conditions) {
      final text = '${condition.feature}${condition.op.code}${condition.value}';
      h += text.codeUnits.fold(0, (sum, unit) => sum + unit);
    }
    final truePositives = 25 + h % 30;
    final falsePositives = 15 + (h ~/ 3) % 40;
    final falseNegatives = max(0, 63 - truePositives);
    final active = _rules[index].active?.backtest?.candidate;

    final backtest = Backtest(
      runAt: now,
      casesEvaluated: _backtestCases,
      candidate: BacktestCounts(
        truePositives: truePositives,
        falsePositives: falsePositives,
        falseNegatives: falseNegatives,
        trueNegatives:
            _backtestCases - truePositives - falsePositives - falseNegatives,
      ),
      active: active,
      systemRecallBefore: _systemRecallBefore,
      systemRecallAfter: active == null
          ? _systemRecallBefore
          : _twoDecimals(
              _systemRecallBefore +
                  (truePositives - active.truePositives) / 1300,
            ),
    );
    _putVersion(index, current.copyWith(backtest: backtest));
    notifyListeners();
    return backtest;
  }

  void submitForApproval(String ruleId, int version) {
    _requirePermission(PermissionCode.RULE_WRITE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.SHADOW);
    // Prototype-only: `shadowStats != null` is enough here. `model.md` §6 asks
    // for real shadow hits, and the decision-service stays stricter.
    if (current.shadowStats == null || current.backtest == null) {
      throw DomainError(
        'conflict',
        'Version $version needs a shadow run and a backtest',
      );
    }

    _putVersion(
      index,
      current.copyWith(status: RuleStatus.PENDING_APPROVAL, submittedAt: now),
    );
    notifyListeners();
  }

  void approve(String ruleId, int version) {
    final user = _requirePermission(PermissionCode.RULE_APPROVE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.PENDING_APPROVAL);
    if (user.id == current.createdBy.id) {
      throw const DomainError(
        'forbidden',
        'The approver must differ from the creator',
      );
    }

    final previous = _rules[index].active;
    if (previous != null) {
      _putVersion(index, previous.copyWith(status: RuleStatus.RETIRED));
    }
    _putVersion(
      index,
      current.copyWith(
        status: RuleStatus.ACTIVE,
        approvedBy: user.ref,
        approvedAt: now,
      ),
    );
    notifyListeners();
  }

  void reject(String ruleId, int version, String reason) {
    _requirePermission(PermissionCode.RULE_APPROVE);
    final index = _requireRuleIndex(ruleId);
    final current = _requireVersion(index, version);
    _requireStatus(current, RuleStatus.PENDING_APPROVAL);
    if (reason.isEmpty || reason.length > _maxRejectionReasonLength) {
      throw const DomainError(
        'invalid',
        'A rejection reason has 1 to $_maxRejectionReasonLength characters',
      );
    }

    _putVersion(
      index,
      current.copyWith(
        status: RuleStatus.DRAFT,
        rejectionReason: reason,
        clearSubmittedAt: true,
        clearShadowStats: true,
      ),
    );
    notifyListeners();
  }

  bool canApprove(RuleVersion v) {
    final user = _currentUser;
    return user != null &&
        user.can(PermissionCode.RULE_APPROVE) &&
        v.status == RuleStatus.PENDING_APPROVAL &&
        user.id != v.createdBy.id;
  }

  List<AppUser> approversFor(RuleVersion v) => List.unmodifiable(
    _users.where(
      (user) =>
          user.active &&
          user.can(PermissionCode.RULE_APPROVE) &&
          user.id != v.createdBy.id,
    ),
  );

  ({double review, double block}) get scoreThresholds => (
    review: _scoreThreshold('SCORE_REVIEW', _defaultReviewThreshold),
    block: _scoreThreshold('SCORE_BLOCK', _defaultBlockThreshold),
  );

  /// The verdict of `model.md` §5. Appends one hit per ACTIVE and SHADOW
  /// version and counts the SHADOW ones; the caller notifies.
  Verdict evaluate(
    Map<String, Object> features,
    double? score,
    List<RuleHit> hitsOut,
  ) {
    bool matches(RuleVersion version) => version.conditions.every(
      (condition) => MockSeed.conditionHolds(condition, features, score),
    );

    var verdict = Verdict.APPROVE;
    for (final view in _rules) {
      final active = view.active;
      if (active == null || !matches(active)) continue;
      final hit = Verdict.fromCode(active.action.code);
      if (hit.index > verdict.index) verdict = hit;
    }

    for (var index = 0; index < _rules.length; index++) {
      final view = _rules[index];
      for (final version in view.versions) {
        final isShadow = version.status == RuleStatus.SHADOW;
        if (!isShadow && version.status != RuleStatus.ACTIVE) continue;

        final matched = matches(version);
        hitsOut.add(
          RuleHit(
            ruleId: view.rule.id,
            ruleCode: view.rule.code,
            version: version.version,
            action: version.action,
            matched: matched,
            shadow: isShadow,
          ),
        );
        if (isShadow) {
          final changesVerdict =
              matched &&
              Verdict.fromCode(version.action.code).index > verdict.index;
          final stats = version.shadowStats!;
          _putVersion(
            index,
            version.copyWith(
              shadowStats: ShadowStats(
                since: stats.since,
                evaluated: stats.evaluated + 1,
                matched: stats.matched + (matched ? 1 : 0),
                verdictChanges: stats.verdictChanges + (changesVerdict ? 1 : 0),
              ),
            ),
          );
        }
      }
    }
    return verdict;
  }

  // Simulator

  int get nextRunNumber => _runCount + 1;

  int startRun() {
    _requirePermission(PermissionCode.SIMULATOR_RUN);
    _runCount++;
    notifyListeners();
    return _runCount;
  }

  Customer createOriginationCustomer() {
    _requirePermission(PermissionCode.SIMULATOR_RUN);

    final digits = _runCount.toString().padLeft(4, '0');
    final customer = Customer(
      id: MockSeed.uuid('a2000000', _takeRecordNumber()),
      maskedName: 'Cliente nuevo $_runCount.',
      maskedDocument: '****${digits.substring(digits.length - 4)}',
      homeCity: 'Bogotá',
      createdAt: now,
      transactions30d: 0,
      previousFrauds: 0,
    );
    _customers.add(customer);
    notifyListeners();
    return customer;
  }

  SimulationEvent simulateOne({
    required Scenario scenario,
    required String customerId,
    required int runNumber,
    required int index,
  }) {
    _requirePermission(PermissionCode.SIMULATOR_RUN);
    final customer = customerById(customerId);
    if (customer == null) {
      throw DomainError('not_found', 'Unknown customer $customerId');
    }

    // Every draw comes from here and in this order, so that a run number and
    // an index always give the same event.
    final random = Random(runNumber * 1000 + index);
    final profile = _drawProfile(scenario, index, random);
    final os = DeviceOs.values[random.nextInt(DeviceOs.values.length)];
    final counterpartyDigits = random.nextInt(10000).toString().padLeft(4, '0');
    final latencyMs = 80 + random.nextInt(81);

    final at = now;
    final features = _simulatedFeatures(
      profile.amount,
      profile.category,
      at,
      customer,
      profile.features,
    );

    final deviceNumber = _takeRecordNumber();
    final device = Device(
      id: MockSeed.uuid('b1000000', deviceNumber),
      fingerprint: 'fp-${deviceNumber.toRadixString(16).padLeft(6, '0')}',
      os: os,
      firstSeenAt: at,
    );

    final home = MockSeed.homeCoordinates[customer.homeCity]!;
    final transaction = Transaction(
      id: MockSeed.uuid('b2000000', _takeRecordNumber()),
      customerId: customer.id,
      deviceId: device.id,
      type: profile.type,
      category: profile.category,
      amount: profile.amount,
      // One degree of latitude is about 111 km.
      latitude: home.$1 - (features['km_from_home'] as num) / 111,
      longitude: home.$2,
      counterparty: profile.type == TransactionType.TRANSFER
          ? '****$counterpartyDigits'
          : null,
      source: TransactionSource.SIMULATOR,
      scenario: scenario,
      occurredAt: at,
    );

    final hits = <RuleHit>[];
    final verdict = evaluate(features, profile.score, hits);
    final opensCase = verdict != Verdict.APPROVE;

    final decisionId = MockSeed.uuid('b3000000', _takeRecordNumber());
    final caseId = opensCase ? _takeCaseId() : null;
    final decision = Decision(
      id: decisionId,
      transactionId: transaction.id,
      kind: DecisionKind.ORIGINAL,
      verdict: verdict,
      score: profile.score,
      modelVersion: activeModel?.version,
      degraded: false,
      features: features,
      ruleHits: hits,
      latencyMs: latencyMs,
      decidedAt: at,
      caseId: caseId,
    );

    if (caseId != null) {
      addCaseRecord(
        CaseView(
          fraudCase: FraudCase(
            id: caseId,
            decisionId: decisionId,
            status: CaseStatus.OPEN,
            openedAt: at,
          ),
          transaction: transaction,
          decision: decision,
          customer: customer,
          device: device,
        ),
      );
    } else {
      _devices.add(device);
      _transactions.add(transaction);
      _decisions.add(decision);
    }
    updateMetrics((metrics) => _withDecision(metrics, verdict, at.hour));
    notifyListeners();

    return SimulationEvent(
      transaction: transaction,
      decision: decision,
      customer: customer,
    );
  }

  // Neither helper notifies: the public operation that calls them does.

  @protected
  void addCaseRecord(CaseView view) {
    _devices.add(view.device);
    _transactions.add(view.transaction);
    _decisions.add(view.decision);
    _cases.add(view);
  }

  @protected
  void updateMetrics(DashboardMetrics Function(DashboardMetrics) update) {
    _metrics = update(_metrics);
  }

  bool _isOpen(CaseView view) =>
      view.status == CaseStatus.OPEN || view.status == CaseStatus.IN_REVIEW;

  bool _isUnassigned(CaseView view) =>
      view.status == CaseStatus.OPEN && view.assignedTo == null;

  List<CaseView> _queued(bool Function(CaseView) test) {
    final queue = _cases.where(test).toList();
    queue.sort(_compareQueueOrder);
    return List.unmodifiable(queue);
  }

  /// Returns the current user; signed out counts as lacking the permission.
  AppUser _requirePermission(PermissionCode permission) {
    final user = _currentUser;
    if (user == null || !user.can(permission)) {
      throw DomainError('forbidden', 'Requires ${permission.code}');
    }
    return user;
  }

  int _requireCaseIndex(String caseId) {
    final index = _cases.indexWhere((view) => view.id == caseId);
    if (index == -1) {
      throw DomainError('not_found', 'Unknown case $caseId');
    }
    return index;
  }

  int _requireRuleIndex(String ruleId) {
    final index = _rules.indexWhere((view) => view.rule.id == ruleId);
    if (index == -1) {
      throw DomainError('not_found', 'Unknown rule $ruleId');
    }
    return index;
  }

  RuleVersion _requireVersion(int ruleIndex, int version) {
    final found = _rules[ruleIndex].version(version);
    if (found == null) {
      throw DomainError('not_found', 'Unknown rule version $version');
    }
    return found;
  }

  void _requireStatus(RuleVersion version, RuleStatus status) {
    if (version.status != status) {
      throw DomainError(
        'conflict',
        'Version ${version.version} is not ${status.code}',
      );
    }
  }

  void _putVersion(int ruleIndex, RuleVersion updated) {
    final view = _rules[ruleIndex];
    _rules[ruleIndex] = view.copyWith(
      versions: [
        for (final candidate in view.versions)
          candidate.version == updated.version ? updated : candidate,
      ],
    );
  }

  double _scoreThreshold(String code, double fallback) {
    final active = ruleByCode(code)?.active;
    if (active == null) return fallback;
    for (final condition in active.conditions) {
      if (condition.feature == 'score' && condition.op == ConditionOp.gte) {
        return (condition.value as num).toDouble();
      }
    }
    return fallback;
  }

  int _takeRecordNumber() => _nextRecordNumber++;

  /// The number goes in the first 6 characters, which are the case's short id.
  String _takeCaseId() {
    final prefix = _takeRecordNumber().toRadixString(16).padLeft(6, '0');
    return '${prefix}00-0000-4000-8000-000000000000';
  }

  DashboardMetrics _withDecision(
    DashboardMetrics metrics,
    Verdict verdict,
    int hour,
  ) {
    final bucket = metrics.hourly[hour];
    final hourly = List.of(metrics.hourly);
    hourly[hour] = HourBucket(
      approve: bucket.approve + (verdict == Verdict.APPROVE ? 1 : 0),
      review: bucket.review + (verdict == Verdict.REVIEW ? 1 : 0),
      block: bucket.block + (verdict == Verdict.BLOCK ? 1 : 0),
    );
    return metrics.copyWith(
      decisions: metrics.decisions + 1,
      verdicts: {
        ...metrics.verdicts,
        verdict: (metrics.verdicts[verdict] ?? 0) + 1,
      },
      hourly: hourly,
    );
  }
}
