import 'package:flutter/foundation.dart';

import 'domain_error.dart';
import 'mock/mock_seed.dart';
import 'models/models.dart';

const _maxNotesLength = 2000;

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
      _metrics = seed.metrics;

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
  DashboardMetrics _metrics;
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

  // Helpers for the next task. Neither notifies: the public operation that
  // calls them does.

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
}
