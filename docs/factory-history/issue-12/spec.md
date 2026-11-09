# In-memory AppStore, DomainError and AppScope

> Issue #12: Add the in-memory AppStore: session, cases, dashboard and models

## Summary
- Specifies `DomainError`, `AppStore` (session, cases, customers, dashboard, models) and `AppScope`, as intake scoped them; rules and the simulator wait for the next task.
- Fixes the details the issue left open: the order of checks, when listeners fire, and how `v{n+1}` is numbered.
- Requires the next-task helpers to be `@protected` public methods, because unused private ones would fail `flutter analyze`.
- Adds a small `AppScope` widget test and extends the "Data layer" bullet in `AGENTS.md`.
- Nothing here needs a product decision; the one thing to watch is that the `AGENTS.md` bullet sits in a block the infra installer manages.

## Context
This is the state layer on top of the data layer from #11. No `AppStore`, `AppScope` or `DomainError` exists yet, and `lib/app/` doesn't exist either.

- `lib/data/models/` (barrel `models.dart`) holds the immutable domain classes.
  - `CaseView` wraps `FraudCase`, `Transaction`, `Decision`, `Customer` and `Device`, and has `id`, `shortId`, `status`, `verdict`, `score`, `assignedTo`, `openedAt`, `resolvedAt`, plus `copyWith`.
  - `FraudCase.copyWith` and `ModelVersion.copyWith` update records by replacement. `AppUser` has `can(PermissionCode)` and `ref` (a `UserRef`).
  - `ModelMetrics` has no `copyWith`; build a new one. `QualityGate.checks` is a list of `({String name, bool passed})` named `MIN_NEW_LABELS`, `PR_AUC_NOT_WORSE`, `RECALL_NOT_WORSE`, in that order (see `_buildModels` in `mock_seed.dart`).
- `lib/data/models/enums.dart`: `Verdict` is declared `APPROVE, REVIEW, BLOCK`, so ascending `index` order puts BLOCK last. `rolePermissions` is the §4 RBAC table.
- `lib/data/mock/mock_seed.dart`: `MockSeed.build(now)` returns `users`, `customers`, `devices`, `transactions`, `decisions`, `cases`, `rules`, `models`, `metrics`, and has `MockSeed.demoPassword`. Model ids follow `d1000000-0000-4000-8000-<n padded to 12 digits>`, with v1 to v5 as `n` = 1 to 5.
- Seed facts at the issue's clock:
  - 9 open cases (7 OPEN and unassigned, plus #3A91C2 for Camilo and #C66A2F for Valentina, both IN_REVIEW) and 3 resolved today.
  - The 3 most recently opened are #7F0B6A, #3A91C2, #B204E7.
  - v5 is ACTIVE with prAuc 0.81, recall 0.74, precision 0.62, 182400 rows, 1940 frauds. v4 is CANDIDATE.
  - `metrics.openCases` is 214.
- Rules come from `../monedasegura-infra/docs/model.md` §4, §7, §8 and `docs/api/decision-api.yaml` (`/cases/{caseId}/resolve` notes `maxLength: 2000`). From this worktree, those docs are at `<main checkout>/../monedasegura-infra/docs/`.
- `flutter analyze` fails on warnings and infos, so an unused private member (`unused_element`, `unused_field`) fails the checks.
- Tests live in `test/data/` and import `package:monedasegura_app/...`; see `test/data/mock_seed_test.dart`.
- `AGENTS.md` has a "Data layer" bullet under "This repo (monedasegura-app)", added by #11.

## Requirements

### `lib/data/domain_error.dart`
1. `class DomainError implements Exception` with `final String code` (one of `forbidden`, `conflict`, `not_found`, `invalid`) and `final String message` (English), and a `toString` showing both.

### `lib/data/app_store.dart`: construction
2. `class AppStore extends ChangeNotifier` with constructor `AppStore({required MockSeed seed, required DateTime Function() clock})` and `factory AppStore.seeded({DateTime Function()? clock})`, which uses `MockSeed.build(clock())` with `clock` defaulting to `DateTime.now`.
3. The store keeps its own mutable copies of the seed's `users`, `customers`, `devices`, `transactions`, `decisions`, `cases` and `models`, so a mutation never changes the seed's lists. It updates a record by replacing it with a `copyWith` result. Seed `rules` and `simulationRunCount` are not copied here, because they would be unused fields until the next task.
4. Every list getter returns a list callers can't modify (`List.unmodifiable`), so state only changes through operations that notify.

### Session
5. `DateTime get now` returns the clock's value. `AppUser? get currentUser`. `bool can(PermissionCode p)` is false when signed out.
6. `AppUser? signIn(String email, String password)` matches the trimmed email case-insensitively against active users and requires `password == MockSeed.demoPassword` (compared exactly, not trimmed). On success it sets and returns the user. Otherwise it returns null and leaves the session as it was, including a session already open.
7. `void signOut()` clears `currentUser`.
8. `List<AppUser> get users` (seed order) and `AppUser? userById(String id)`.
9. `lib/data/app_store.dart` has no logging at all (`print`, `debugPrint`, `log`), and the password is never stored or put in a `DomainError` message.

### Cases
10. The queue order is: verdict with BLOCK first, then score descending with null last, then `openedAt` ascending. It is defined once and used by `openCases`, `unassignedCases` and `myCases`.
11. `openCases`: status OPEN or IN_REVIEW, in queue order.
12. `unassignedCases`: OPEN and `assignedTo == null`, in queue order.
13. `myCases`: IN_REVIEW and assigned to `currentUser` (compare `UserRef.id`), in queue order; empty when signed out.
14. `resolvedToday`: RESOLVED with `resolvedAt` on the same year, month and day as `now`, newest `resolvedAt` first.
15. `recentCases`: the 3 cases from the `openCases` set (OPEN or IN_REVIEW) with the latest `openedAt`, newest first.
16. `CaseView? caseById(String id)` finds a case in any status, and returns null when unknown.
17. `void takeCase(String caseId)` checks, in order:
    - `CASE_RESOLVE`, including signed out (`forbidden`)
    - known id (`not_found`)
    - status OPEN (`conflict`)

    It then sets IN_REVIEW and `assignedTo = currentUser.ref`.
18. `void resolveCase(String caseId, CaseLabel label, {String? notes})` checks, in order:
    - `CASE_RESOLVE` (`forbidden`)
    - known id (`not_found`)
    - status IN_REVIEW and assigned to the current user (`conflict`)
    - notes at most 2000 characters (`invalid`)

    It then sets RESOLVED, `label`, `notes` and `resolvedAt = now`. Only `fraudCase` changes: the `CaseView`'s `decision` and `transaction` stay the same objects (model.md §7).

### Customers and dashboard
19. `List<Customer> get customers` (seed order) and `Customer? customerById(String id)`.
20. `DashboardMetrics get metrics` returns the current metrics. Taking or resolving a case doesn't change them, and the seeded `metrics.openCases` (214) stays as it is.
21. `int get openCaseCount` is the size of the `openCases` set. `int get unassignedCaseCount` is the size of the `unassignedCases` set. Both are computed from the case list.

### Models
22. `List<ModelVersion> get models` is newest first, ordered by numeric version descending. `ModelVersion? get activeModel` is the version with status ACTIVE.
23. `ModelVersion retrainNow()` requires `MODEL_TRAIN` (else `forbidden`) and an active model (else `conflict`). It creates a version with:
    - `version`: `v{n+1}`, where `n` is the highest existing version number
    - `id`: the seed's pattern, with `n+1`
    - `trigger`: MANUAL
    - `trainedBy`: `currentUser.ref`
    - `trainedAt`: `now`
    - `metrics`: the active version's, with prAuc, recall and precision each +0.01 and rounded to 2 decimals, and the same `featureImportance`
    - `trainingRows`: active +1200
    - `fraudsSeen`: active +30
24. The new version's `QualityGate` has the three named checks in the seed's order:
    - `MIN_NEW_LABELS` always passes
    - `PR_AUC_NOT_WORSE` passes when new prAuc >= active prAuc
    - `RECALL_NOT_WORSE` passes when new recall >= active recall - 0.02

    `passed` is true when all three pass.
25. If the gate passes, the new version is ACTIVE and the previous ACTIVE becomes RETIRED. Otherwise the new version stays CANDIDATE and the active version doesn't change. `retrainNow` returns the new version. Other versions, such as v4, don't change.

### Notifications
26. Each successful public mutation (`signIn`, `signOut`, `takeCase`, `resolveCase`, `retrainNow`) calls `notifyListeners()` exactly once, as its last step.
27. A failed operation (a `DomainError` or a null `signIn`) changes nothing and doesn't notify.

### Helpers for the next task
28. `AppStore` declares two `@protected` public methods (from `package:flutter/foundation.dart`). Neither notifies; the public operation that calls them will.
    - `void addCaseRecord(CaseView view)` adds the view's device, transaction, decision and case to the store's lists.
    - `void updateMetrics(DashboardMetrics Function(DashboardMetrics) update)` replaces `metrics` with the result.

### `lib/app/app_scope.dart`
29. `class AppScope extends InheritedNotifier<AppStore>` with `static AppStore of(BuildContext context)`, which depends on changes, and `static AppStore read(BuildContext context)`, which creates no dependency (`getInheritedWidgetOfExactType`). Both assert when no `AppScope` is above the context.

### Tests and docs
30. `test/data/app_store_test.dart` uses `AppStore.seeded(clock: () => DateTime(2026, 10, 25, 9, 45))` and covers the acceptance criteria for the store. It reaches the helpers through a small `AppStore` subclass declared in the test file.
31. `test/app/app_scope_test.dart` covers `AppScope` with widget tests.
32. The "Data layer" bullet in `AGENTS.md` also says that `lib/data/app_store.dart` holds the in-memory state and domain operations, that domain failures throw `DomainError`, and that widgets reach the store through `AppScope.of` (rebuilds) or `AppScope.read` (callbacks).

## Acceptance criteria
Unless stated otherwise, verify with `flutter test test/data/app_store_test.dart`, using the fixed clock from Requirement 30. Cases are named by `shortId`.

1. `signIn('valentina.rios@monedasegura.co', MockSeed.demoPassword)` returns Valentina and `can(PermissionCode.SIMULATOR_RUN)` is true. A wrong password returns null and `currentUser` stays null. `signOut()` clears it, and `can` is then false.
2. `signIn('  VALENTINA.RIOS@monedasegura.co ', MockSeed.demoPassword)` returns Valentina. A failed sign-in while signed in leaves the current user in place. A user replaced with `active: false` in a seed passed to the constructor can't sign in.
3. `openCases` has 9 entries, starts with #A17D3C (0.97), #7F0B6A (0.96), #E1C048 (0.92), and ends with #09F35B (null score), the last of the REVIEW cases.
4. On a fresh store, `openCaseCount` is 9, `unassignedCaseCount` is 7, `metrics.openCases` is 214, and `unassignedCases` contains only OPEN cases with no assignee, in queue order.
5. `recentCases` is exactly #7F0B6A, #3A91C2, #B204E7. `resolvedToday` has 3 entries, newest `resolvedAt` first (#F09A5E, #8C3B07, #D4E2F1).
6. Signed in as Valentina, `takeCase` on #B204E7 makes it IN_REVIEW assigned to her, and it appears in `myCases` after #C66A2F. A second `takeCase` throws `DomainError` with code `conflict`.
7. After `resolveCase(#B204E7, CaseLabel.CONFIRMED_FRAUD, notes: 'x')`, the case isn't in `openCases` (8 left) and is in `resolvedToday` (4 entries). `caseById` shows its label, notes and `resolvedAt == now`, and its `decision` and `transaction` are identical (`same`) to those before the call.
8. Signed in as Mateo Rojas, `takeCase` throws `forbidden`. Signed out, `takeCase` and `resolveCase` throw `forbidden`, even with an unknown id. Signed in as Valentina, resolving #3A91C2 (assigned to Camilo Torres) throws `conflict`.
9. Signed in as Valentina, `takeCase` and `resolveCase` with an unknown id throw `not_found`. `resolveCase` on her case #C66A2F with 2001-character notes throws `invalid` and leaves it IN_REVIEW. With exactly 2000 characters it succeeds.
10. Signed in as Laura Cárdenas, `retrainNow()` returns `v6`, ACTIVE, with trigger MANUAL, `trainedBy` Laura, `trainedAt == now`, prAuc 0.82, recall 0.75, precision 0.63 (`equals`, no tolerance), `trainingRows` 183600, `fraudsSeen` 1970, the same `featureImportance`, and a passing gate with the three checks. `models.first` is v6, `activeModel` is v6, v5 is RETIRED and v4 is still CANDIDATE. A second `retrainNow()` returns `v7`.
11. Signed in as Camilo Torres, `retrainNow()` throws `forbidden` and `models` still has 5 entries.
12. A listener added with `addListener` is called once for each successful `signIn`, `signOut`, `takeCase`, `resolveCase` and `retrainNow`, and not at all for a failed sign-in or an operation that throws `DomainError`.
13. After mutations, the `seed.cases` entry for #B204E7 and the length of `seed.models` are unchanged. `store.users.add(...)` throws `UnsupportedError`.
14. Through the test subclass, `addCaseRecord` makes a new case available from `caseById` and `openCases`, and `updateMetrics` changes `metrics`. Neither calls listeners.
15. `flutter test test/app/app_scope_test.dart` shows three things: a widget using `AppScope.of` rebuilds when the store notifies; a widget using only `AppScope.read` gets the store and doesn't rebuild; and `of` and `read` throw `AssertionError` without an `AppScope`.
16. `lib/data/app_store.dart` contains no `print(`, `debugPrint(` or `log(` (check with a search).
17. `AGENTS.md` mentions `lib/data/app_store.dart`, `DomainError` and `AppScope` in the "Data layer" bullet.

## Out of scope
- Rule lifecycle and simulator operations, and any read of rules from the store (next task).
- Widgets and screens, and wiring `AppScope` into `lib/main.dart` or `lib/login_screen.dart`.
- Persistence between restarts, and any HTTP client or `config.json` use.
- Manual activation of a CANDIDATE (`POST /models/{modelId}/activate`).
- A test that reaches the CANDIDATE outcome: build it, but the gate always passes through the public API.
- Dashboard alerts when a gate fails, and any change to the seeded `metrics.openCases`.
- Changes to `lib/data/models/`, `lib/data/mock/mock_seed.dart`, `lib/data/labels.dart`, `lib/data/format.dart`, `../monedasegura-infra`, or the protected files `factory/checks.sh` and `factory/config.json`.
- Capping metrics at 1.0, new packages, or options the issue doesn't list.

## Assumptions
- The helpers are named `addCaseRecord` and `updateMetrics` and are `@protected`: the issue allows this, and unused library-private methods would fail `flutter analyze`.
- The helpers don't notify: the next task's operations will call both, and Requirement 26 allows one notification per mutation.
- `addCaseRecord` takes a `CaseView` only: that is what the issue describes, and the next task can add a path for APPROVE decisions, which have no case.
- `signOut` always notifies once, even when already signed out: it is the simplest behaviour and no caller depends on the difference.
- `models` orders by version number rather than `trainedAt`: `MockSeed` clamps v5's time to `now` early in the day, which could tie with a new version.
- `retrainNow` with no active model throws `conflict`: the seed always has one, and the API uses 409 for a state problem.
- List getters are unmodifiable: otherwise a caller could change state without notifying, which breaks "every mutation notifies".
- Seed `rules` aren't copied yet: an unused field fails `flutter analyze`, and the next task adds them with their first reader.
- The `AppScope` tests get their own file under `test/app/`: the issue's list names only the store test, but AGENTS.md asks for widget tests on new shared widgets.
- The `AGENTS.md` note extends the existing bullet, as #11 did, even though that bullet sits inside the `factory:start` block managed by infra's `factory/bin/install`: a reinstall could overwrite it, and fixing that would mean changing another repo.
