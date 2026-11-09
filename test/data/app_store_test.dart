import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/app_store.dart';
import 'package:monedasegura_app/data/domain_error.dart';
import 'package:monedasegura_app/data/mock/mock_seed.dart';
import 'package:monedasegura_app/data/models/models.dart';

const _valentina = 'valentina.rios@monedasegura.co';
const _camilo = 'camilo.torres@monedasegura.co';
const _lauraCardenas = 'laura.cardenas@monedasegura.co';
const _mateo = 'mateo.rojas@monedasegura.co';
const _password = MockSeed.demoPassword;

const _unknownId = '00000000-0000-4000-8000-000000000000';

final _now = DateTime(2026, 10, 25, 9, 45);
DateTime _clock() => _now;

AppStore _store() => AppStore.seeded(clock: _clock);

/// Reaches the helpers the next task's operations will call.
class _TestStore extends AppStore {
  _TestStore({required super.seed}) : super(clock: _clock);

  void add(CaseView view) => addCaseRecord(view);

  void changeMetrics(DashboardMetrics Function(DashboardMetrics) update) =>
      updateMetrics(update);
}

String _idOf(AppStore store, String shortId) => store.openCases
    .followedBy(store.resolvedToday)
    .firstWhere((view) => view.shortId == shortId)
    .id;

List<String> _shortIds(List<CaseView> views) => [
  for (final view in views) view.shortId,
];

Matcher _throwsDomainError(String code) =>
    throwsA(isA<DomainError>().having((error) => error.code, 'code', code));

void main() {
  group('DomainError', () {
    test('toString shows the code and the message', () {
      final text = const DomainError('conflict', 'Not open').toString();

      expect(text, contains('conflict'));
      expect(text, contains('Not open'));
    });
  });

  group('session', () {
    test('signs in with the demo password and signs out', () {
      final store = _store();

      final user = store.signIn(_valentina, _password);

      expect(user?.fullName, 'Valentina Ríos');
      expect(store.currentUser, same(user));
      expect(store.can(PermissionCode.SIMULATOR_RUN), isTrue);

      store.signOut();

      expect(store.currentUser, isNull);
      expect(store.can(PermissionCode.SIMULATOR_RUN), isFalse);
    });

    test('a wrong password returns null and stays signed out', () {
      final store = _store();

      expect(store.signIn(_valentina, 'wrong'), isNull);
      expect(store.currentUser, isNull);
    });

    test('the password is compared exactly, not trimmed', () {
      final store = _store();

      expect(store.signIn(_valentina, ' $_password '), isNull);
    });

    test('the email is trimmed and case-insensitive', () {
      final store = _store();

      final user = store.signIn('  VALENTINA.RIOS@monedasegura.co ', _password);

      expect(user?.fullName, 'Valentina Ríos');
    });

    test('a failed sign-in leaves the current user in place', () {
      final store = _store();
      final user = store.signIn(_valentina, _password);

      expect(store.signIn(_camilo, 'wrong'), isNull);
      expect(store.signIn('nobody@monedasegura.co', _password), isNull);
      expect(store.currentUser, same(user));
    });

    test('an inactive user cannot sign in', () {
      final seed = MockSeed.build(_now);
      final index = seed.users.indexWhere((user) => user.email == _camilo);
      final camilo = seed.users[index];
      seed.users[index] = AppUser(
        id: camilo.id,
        fullName: camilo.fullName,
        email: camilo.email,
        active: false,
        roles: camilo.roles,
      );
      final store = AppStore(seed: seed, clock: _clock);

      expect(store.signIn(_camilo, _password), isNull);
      expect(store.currentUser, isNull);
    });

    test('users come in seed order and resolve by id', () {
      final store = _store();
      final seed = MockSeed.build(_now);

      expect(
        [for (final user in store.users) user.id],
        [for (final user in seed.users) user.id],
      );
      expect(store.userById(store.users[3].id)?.fullName, 'Camilo Torres');
      expect(store.userById(_unknownId), isNull);
    });

    test('now returns the clock', () {
      expect(_store().now, _now);
    });
  });

  group('case lists', () {
    test('openCases follows the queue order', () {
      final open = _store().openCases;

      expect(open, hasLength(9));
      expect(_shortIds(open).take(3), ['#A17D3C', '#7F0B6A', '#E1C048']);
      expect(open.take(3).map((view) => view.score), [0.97, 0.96, 0.92]);
      expect(open.last.shortId, '#09F35B');
      expect(open.last.score, isNull);
    });

    test('equal verdict and score fall back to the oldest first', () {
      final seed = MockSeed.build(_now);
      final index = seed.cases.indexWhere((view) => view.shortId == '#3A91C2');
      final original = seed.cases[index];
      final twin = seed.cases.firstWhere((view) => view.shortId == '#C66A2F');
      seed.cases[index] = original.copyWith(decision: twin.decision);

      final order = _shortIds(AppStore(seed: seed, clock: _clock).openCases);

      // #C66A2F opened 21 minutes ago and #3A91C2 3 minutes ago.
      expect(order.indexOf('#C66A2F'), lessThan(order.indexOf('#3A91C2')));
    });

    test('a fresh store counts from the case list', () {
      final store = _store();

      expect(store.openCaseCount, 9);
      expect(store.unassignedCaseCount, 7);
      expect(store.metrics.openCases, 214);
    });

    test('unassignedCases holds only unassigned OPEN cases in queue order', () {
      final store = _store();
      final unassigned = store.unassignedCases;

      expect(unassigned, hasLength(7));
      expect(
        unassigned.every(
          (view) => view.status == CaseStatus.OPEN && view.assignedTo == null,
        ),
        isTrue,
      );
      expect(
        _shortIds(unassigned),
        _shortIds(store.openCases)
            .where((id) => id != '#C66A2F' && id != '#3A91C2')
            .toList(),
      );
    });

    test('recentCases holds the 3 latest opened, newest first', () {
      expect(_shortIds(_store().recentCases), [
        '#7F0B6A',
        '#3A91C2',
        '#B204E7',
      ]);
    });

    test('resolvedToday is newest first', () {
      expect(_shortIds(_store().resolvedToday), [
        '#F09A5E',
        '#8C3B07',
        '#D4E2F1',
      ]);
    });

    test('resolvedToday skips cases resolved on another day', () {
      final store = AppStore(
        seed: MockSeed.build(_now),
        clock: () => _now.add(const Duration(days: 1)),
      );

      expect(store.resolvedToday, isEmpty);
    });

    test('myCases is empty when signed out', () {
      expect(_store().myCases, isEmpty);
    });

    test('caseById finds any status and null when unknown', () {
      final store = _store();
      final resolved = store.resolvedToday.first;

      expect(store.caseById(resolved.id), same(resolved));
      expect(store.caseById(_unknownId), isNull);
    });
  });

  group('takeCase', () {
    test('assigns the case to the current user', () {
      final store = _store();
      final user = store.signIn(_valentina, _password)!;
      final id = _idOf(store, '#B204E7');

      store.takeCase(id);

      final taken = store.caseById(id)!;
      expect(taken.status, CaseStatus.IN_REVIEW);
      expect(taken.assignedTo?.id, user.id);
      expect(_shortIds(store.myCases), ['#C66A2F', '#B204E7']);
      expect(store.unassignedCaseCount, 6);
      expect(store.openCaseCount, 9);
    });

    test('a second take throws conflict', () {
      final store = _store();
      store.signIn(_valentina, _password);
      final id = _idOf(store, '#B204E7');
      store.takeCase(id);

      expect(() => store.takeCase(id), _throwsDomainError('conflict'));
    });

    test('an auditor is forbidden', () {
      final store = _store();
      store.signIn(_mateo, _password);

      expect(
        () => store.takeCase(_idOf(store, '#B204E7')),
        _throwsDomainError('forbidden'),
      );
    });

    test('signed out is forbidden, even with an unknown id', () {
      final store = _store();

      expect(
        () => store.takeCase(_idOf(store, '#B204E7')),
        _throwsDomainError('forbidden'),
      );
      expect(() => store.takeCase(_unknownId), _throwsDomainError('forbidden'));
    });

    test('an unknown id throws not_found', () {
      final store = _store();
      store.signIn(_valentina, _password);

      expect(() => store.takeCase(_unknownId), _throwsDomainError('not_found'));
    });
  });

  group('resolveCase', () {
    test('labels the case and leaves the decision and transaction alone', () {
      final store = _store();
      store.signIn(_valentina, _password);
      final id = _idOf(store, '#B204E7');
      store.takeCase(id);
      final before = store.caseById(id)!;

      store.resolveCase(id, CaseLabel.CONFIRMED_FRAUD, notes: 'x');

      final after = store.caseById(id)!;
      expect(_shortIds(store.openCases), isNot(contains('#B204E7')));
      expect(store.openCases, hasLength(8));
      expect(_shortIds(store.resolvedToday), contains('#B204E7'));
      expect(store.resolvedToday, hasLength(4));
      expect(after.status, CaseStatus.RESOLVED);
      expect(after.label, CaseLabel.CONFIRMED_FRAUD);
      expect(after.fraudCase.notes, 'x');
      expect(after.resolvedAt, store.now);
      expect(after.decision, same(before.decision));
      expect(after.transaction, same(before.transaction));
    });

    test('signed out is forbidden, even with an unknown id', () {
      final store = _store();

      expect(
        () => store.resolveCase(_unknownId, CaseLabel.DISMISSED),
        _throwsDomainError('forbidden'),
      );
    });

    test("another analyst's case throws conflict", () {
      final store = _store();
      store.signIn(_valentina, _password);

      expect(
        () => store.resolveCase(_idOf(store, '#3A91C2'), CaseLabel.DISMISSED),
        _throwsDomainError('conflict'),
      );
    });

    test('an unknown id throws not_found', () {
      final store = _store();
      store.signIn(_valentina, _password);

      expect(
        () => store.resolveCase(_unknownId, CaseLabel.DISMISSED),
        _throwsDomainError('not_found'),
      );
    });

    test('2001-character notes throw invalid and change nothing', () {
      final store = _store();
      store.signIn(_valentina, _password);
      final id = _idOf(store, '#C66A2F');

      expect(
        () => store.resolveCase(id, CaseLabel.DISMISSED, notes: 'x' * 2001),
        _throwsDomainError('invalid'),
      );
      expect(store.caseById(id)!.status, CaseStatus.IN_REVIEW);
    });

    test('2000-character notes succeed', () {
      final store = _store();
      store.signIn(_valentina, _password);
      final id = _idOf(store, '#C66A2F');

      store.resolveCase(id, CaseLabel.DISMISSED, notes: 'x' * 2000);

      expect(store.caseById(id)!.status, CaseStatus.RESOLVED);
    });
  });

  group('customers', () {
    test('come in seed order and resolve by id', () {
      final store = _store();
      final seed = MockSeed.build(_now);

      expect(
        [for (final customer in store.customers) customer.id],
        [for (final customer in seed.customers) customer.id],
      );
      expect(
        store.customerById(store.customers.first.id)?.maskedName,
        'Mariana G.',
      );
      expect(store.customerById(_unknownId), isNull);
    });
  });

  group('metrics', () {
    test('taking or resolving a case does not change them', () {
      final store = _store();
      final before = store.metrics;
      store.signIn(_valentina, _password);
      final id = _idOf(store, '#B204E7');

      store.takeCase(id);
      store.resolveCase(id, CaseLabel.DISMISSED);

      expect(store.metrics, same(before));
      expect(store.metrics.openCases, 214);
    });
  });

  group('models', () {
    test('are newest first with v5 active', () {
      final store = _store();

      expect(
        [for (final model in store.models) model.version],
        ['v5', 'v4', 'v3', 'v2', 'v1'],
      );
      expect(store.activeModel?.version, 'v5');
    });

    test('retrainNow creates an active v6 and retires v5', () {
      final store = _store();
      final laura = store.signIn(_lauraCardenas, _password)!;
      final previous = store.activeModel!;

      final created = store.retrainNow();

      expect(created.version, 'v6');
      expect(created.id, 'd1000000-0000-4000-8000-000000000006');
      expect(created.status, ModelStatus.ACTIVE);
      expect(created.trigger, ModelTrigger.MANUAL);
      expect(created.trainedBy?.id, laura.id);
      expect(created.trainedAt, _now);
      expect(created.metrics.prAuc, equals(0.82));
      expect(created.metrics.recall, equals(0.75));
      expect(created.metrics.precision, equals(0.63));
      expect(created.trainingRows, 183600);
      expect(created.fraudsSeen, 1970);
      expect(
        created.metrics.featureImportance,
        same(previous.metrics.featureImportance),
      );

      final gate = created.qualityGate!;
      expect(gate.passed, isTrue);
      expect(gate.checks, [
        (name: 'MIN_NEW_LABELS', passed: true),
        (name: 'PR_AUC_NOT_WORSE', passed: true),
        (name: 'RECALL_NOT_WORSE', passed: true),
      ]);

      expect(store.models.first, same(created));
      expect(store.activeModel, same(created));
      ModelVersion byVersion(String version) =>
          store.models.firstWhere((model) => model.version == version);
      expect(byVersion('v5').status, ModelStatus.RETIRED);
      expect(byVersion('v4').status, ModelStatus.CANDIDATE);
    });

    test('a second retrainNow creates v7', () {
      final store = _store();
      store.signIn(_lauraCardenas, _password);
      store.retrainNow();

      expect(store.retrainNow().version, 'v7');
    });

    test('an analyst is forbidden and models do not change', () {
      final store = _store();
      store.signIn(_camilo, _password);

      expect(store.retrainNow, _throwsDomainError('forbidden'));
      expect(store.models, hasLength(5));
    });

    test('with no active model retrainNow throws conflict', () {
      final seed = MockSeed.build(_now);
      seed.models.removeWhere((model) => model.status == ModelStatus.ACTIVE);
      final store = AppStore(seed: seed, clock: _clock);
      store.signIn(_lauraCardenas, _password);

      expect(store.activeModel, isNull);
      expect(store.retrainNow, _throwsDomainError('conflict'));
    });
  });

  group('notifications', () {
    test('each successful mutation notifies once', () {
      final store = _store();
      var calls = 0;
      store.addListener(() => calls++);

      void expectOneCall(void Function() mutation) {
        calls = 0;
        mutation();
        expect(calls, 1);
      }

      final id = _idOf(store, '#B204E7');
      expectOneCall(() => store.signIn(_valentina, _password));
      expectOneCall(() => store.takeCase(id));
      expectOneCall(() => store.resolveCase(id, CaseLabel.DISMISSED));
      expectOneCall(store.retrainNow);
      expectOneCall(store.signOut);
    });

    test('a failed operation does not notify', () {
      final store = _store();
      var calls = 0;
      store.addListener(() => calls++);

      expect(store.signIn(_valentina, 'wrong'), isNull);
      expect(store.signIn('nobody@monedasegura.co', _password), isNull);
      expect(() => store.takeCase(_unknownId), throwsA(isA<DomainError>()));
      expect(
        () => store.resolveCase(_unknownId, CaseLabel.DISMISSED),
        throwsA(isA<DomainError>()),
      );
      expect(store.retrainNow, throwsA(isA<DomainError>()));

      expect(calls, 0);
    });
  });

  group('isolation', () {
    test('mutations never reach the seed', () {
      final seed = MockSeed.build(_now);
      final store = AppStore(seed: seed, clock: _clock);
      final seedCase = seed.cases.firstWhere(
        (view) => view.shortId == '#B204E7',
      );
      store.signIn(_valentina, _password);

      store.takeCase(seedCase.id);
      store.resolveCase(seedCase.id, CaseLabel.DISMISSED);
      store.retrainNow();

      final after = seed.cases.firstWhere((view) => view.shortId == '#B204E7');
      expect(after, same(seedCase));
      expect(after.status, CaseStatus.OPEN);
      expect(seed.models, hasLength(5));
    });

    test('list getters cannot be modified', () {
      final store = _store();
      final user = store.users.first;
      final view = store.resolvedToday.first;
      final customer = store.customers.first;
      final model = store.models.first;

      expect(() => store.users.add(user), throwsUnsupportedError);
      expect(() => store.customers.add(customer), throwsUnsupportedError);
      expect(() => store.models.add(model), throwsUnsupportedError);
      expect(() => store.openCases.add(view), throwsUnsupportedError);
      expect(() => store.unassignedCases.add(view), throwsUnsupportedError);
      expect(() => store.myCases.add(view), throwsUnsupportedError);
      expect(() => store.resolvedToday.add(view), throwsUnsupportedError);
      expect(() => store.recentCases.add(view), throwsUnsupportedError);
    });
  });

  group('helpers', () {
    test('addCaseRecord adds a case without notifying', () {
      final seed = MockSeed.build(_now);
      final store = _TestStore(seed: seed);
      var calls = 0;
      store.addListener(() => calls++);
      const newId = 'abcdef00-0000-4000-8000-000000000000';
      final template = seed.cases.first;

      store.add(
        template.copyWith(fraudCase: template.fraudCase.copyWith(id: newId)),
      );

      expect(store.caseById(newId)?.id, newId);
      expect(_shortIds(store.openCases), contains('#ABCDEF'));
      expect(calls, 0);
    });

    test('updateMetrics changes metrics without notifying', () {
      final store = _TestStore(seed: MockSeed.build(_now));
      var calls = 0;
      store.addListener(() => calls++);

      store.changeMetrics((metrics) => metrics.copyWith(decisions: 1));

      expect(store.metrics.decisions, 1);
      expect(calls, 0);
    });
  });
}
