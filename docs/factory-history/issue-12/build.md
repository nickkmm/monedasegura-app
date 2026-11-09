STATUS: READY

# Build: In-memory AppStore, DomainError and AppScope

## Summary
- Adds `AppStore`, a `ChangeNotifier` over copies of the mock seed, with session, cases, customers, dashboard and models operations.
- Adds `DomainError` (`forbidden`, `conflict`, `not_found`, `invalid`) and `AppScope` (`of` and `read`).
- Adds the `@protected` helpers `addCaseRecord` and `updateMetrics` for the next task.
- Adds 45 tests across two new test files and extends the "Data layer" bullet in `AGENTS.md`.
- `factory/checks.sh` passes.

## Changes
- `lib/data/domain_error.dart`: the exception, with a code, an English message and a `toString` showing both.
- `lib/data/app_store.dart`: the store. The queue order is defined once in `_compareQueueOrder`; list getters return unmodifiable lists; a mutation replaces a record with a `copyWith` result and notifies once as its last step.
- `lib/app/app_scope.dart`: `AppScope extends InheritedNotifier<AppStore>`, constructed with `store:` and `child:`.
- `test/data/app_store_test.dart`: 42 tests with the fixed clock, including a `_TestStore` subclass that reaches the helpers.
- `test/app/app_scope_test.dart`: 3 widget tests.
- `AGENTS.md`: the "Data layer" bullet now names `lib/data/app_store.dart`, `DomainError`, `AppScope.of` and `AppScope.read`.

## Acceptance criteria
Criteria 1 to 14 pass in `flutter test test/data/app_store_test.dart` (42 tests, all passed).

1. [x] Sign-in, wrong password, sign-out and `can`: groups "session", tests "signs in with the demo password and signs out" and "a wrong password returns null and stays signed out".
2. [x] Trimmed and case-insensitive email, failed sign-in keeps the session, inactive user refused: tests "the email is trimmed and case-insensitive", "a failed sign-in leaves the current user in place", "an inactive user cannot sign in".
3. [x] `openCases` has 9 entries, starts #A17D3C, #7F0B6A, #E1C048 and ends with #09F35B (null score): test "openCases follows the queue order".
4. [x] `openCaseCount` 9, `unassignedCaseCount` 7, `metrics.openCases` 214, and `unassignedCases` only unassigned OPEN cases in queue order: tests "a fresh store counts from the case list" and "unassignedCases holds only unassigned OPEN cases in queue order".
5. [x] `recentCases` is #7F0B6A, #3A91C2, #B204E7 and `resolvedToday` is #F09A5E, #8C3B07, #D4E2F1: tests "recentCases holds the 3 latest opened, newest first" and "resolvedToday is newest first".
6. [x] `takeCase` on #B204E7 gives IN_REVIEW assigned to Valentina, `myCases` is #C66A2F then #B204E7, and a second take throws `conflict`: tests "assigns the case to the current user" and "a second take throws conflict".
7. [x] After `resolveCase`, 8 open and 4 resolved today; label, notes and `resolvedAt` set; `decision` and `transaction` are `same` as before: test "labels the case and leaves the decision and transaction alone".
8. [x] Mateo and signed-out callers get `forbidden`, even with an unknown id; Valentina resolving #3A91C2 gets `conflict`: tests "an auditor is forbidden", both "signed out is forbidden, even with an unknown id", "another analyst's case throws conflict".
9. [x] Unknown id gives `not_found`; 2001 characters give `invalid` and leave #C66A2F IN_REVIEW; exactly 2000 succeed: tests "an unknown id throws not_found" (both groups), "2001-character notes throw invalid and change nothing", "2000-character notes succeed".
10. [x] `retrainNow()` as Laura Cárdenas returns the specified v6, with exact metrics, a passing gate with the three checks, v5 RETIRED and v4 CANDIDATE; a second call returns v7: tests "retrainNow creates an active v6 and retires v5" and "a second retrainNow creates v7".
11. [x] Camilo gets `forbidden` and `models` still has 5 entries: test "an analyst is forbidden and models do not change".
12. [x] One listener call per successful mutation, none for failures: group "notifications".
13. [x] The seed's #B204E7 entry and `seed.models` length are unchanged, and `store.users.add(...)` throws `UnsupportedError`: group "isolation".
14. [x] `addCaseRecord` and `updateMetrics` work through the subclass without notifying: group "helpers".
15. [x] `flutter test test/app/app_scope_test.dart`: 3 tests passed (`of` rebuilds, `read` doesn't rebuild, both throw `AssertionError` without an `AppScope`).
16. [x] `grep -nE "print\(|debugPrint\(|log\(" lib/data/app_store.dart` finds nothing (exit 1).
17. [x] `grep` finds `lib/data/app_store.dart` on the "Data layer" bullet at `AGENTS.md` line 93, which also names `DomainError` and `AppScope`.

## Validation
- `bash <main checkout>/factory/checks.sh`: passed (exit 0). `dart format` 0 changed, `flutter analyze` no issues, `flutter test` 151 passed, `flutter build web --release` built.
- `flutter test test/data/app_store_test.dart`: 42 passed.
- `flutter test test/app/app_scope_test.dart`: 3 passed.
- No page to check: this task adds no screen, and `AppScope` isn't wired into the app yet.

## Log
### Round 1
Built the spec. The first checks run failed `flutter analyze` on `prefer_initializing_formals` for the `clock` parameter. I changed the constructor to `required this._clock`, a private named parameter that callers still pass as `clock:`, and the checks then passed. As the spec allows, the CANDIDATE outcome of `retrainNow` is built but has no test, because the gate always passes through the public API. I added a few tests beyond the criteria: the score tie-break, `resolvedToday` on another day, and `retrainNow` with no active model.
