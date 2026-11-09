ESCALATE

## Summary
- Issue #12 adds the in-memory `AppStore`, `DomainError` and `AppScope`, with tests and a note in `AGENTS.md`.
- All 17 acceptance criteria are met. The gate passed on commit eae115b and both reviews passed.
- I found no defect. I re-ran the 45 new tests and they pass.
- This needs a person's check first: it adds mock sign-in and permission enforcement, and it differs from `model.md` and `decision-api.yaml` in three small ways.
- It also goes slightly beyond intake's Scope, with an `AGENTS.md` edit and a separate `AppScope` test file.

## Why
The code does what the spec asks, but `signIn` and the permission checks touch permissions, which this project reserves for a person to check. The mock also departs from the shared docs in places the issue allows or doesn't address, and a person should accept those knowingly. No migration, environment variable, `docker-compose.yml`, CI config, dependency or JWT handling changed.

## Acceptance criteria
1. Sign-in, wrong password, sign-out and `can`: met; test "signs in with the demo password and signs out", and I read `signIn` and `can` in `lib/data/app_store.dart`.
2. Trimmed, case-insensitive email, failed sign-in keeps the session, inactive user refused: met; named tests in build.md, and the code matches.
3. `openCases` order, with #09F35B last: met; test "openCases follows the queue order", and `_compareQueueOrder` matches the order in `decision-api.yaml`.
4. `openCaseCount` 9, `unassignedCaseCount` 7, `metrics.openCases` 214: met; named tests in build.md.
5. `recentCases` and `resolvedToday` contents and order: met; named tests in build.md.
6. `takeCase` on #B204E7 and a second take gives `conflict`: met; named tests in build.md, and I read `takeCase`.
7. `resolveCase` on #B204E7 leaves 8 open and 4 resolved today, with `decision` and `transaction` unchanged: met; I read the test and the code myself (spot-check).
8. `forbidden` for Mateo and for signed-out callers, `conflict` on another analyst's case: met; the check order in the code is permission, then id, then state.
9. `not_found`, and the 2000 and 2001-character notes limit: met; named tests in build.md, and the code matches.
10. `retrainNow` as Laura gives v6, v5 RETIRED, v4 unchanged, then v7: met; the tests exist at `test/data/app_store_test.dart:392` and `:431`, and I read the code.
11. Camilo gets `forbidden` on `retrainNow` and `models` stays at 5: met; the test exists at `test/data/app_store_test.dart:443`.
12. One listener call per successful mutation, none on failure: met; group "notifications", and each mutation in the code notifies once.
13. The seed stays unchanged and list getters are unmodifiable: met; group "isolation", and the constructor copies the lists.
14. `addCaseRecord` and `updateMetrics` work without notifying: met; group "helpers", and the code matches.
15. `AppScope` `of`, `read` and the missing-scope assert: met; I re-ran `test/app/app_scope_test.dart` and all 3 pass.
16. No logging in `lib/data/app_store.dart`: met; I re-ran the search and it found nothing.
17. `AGENTS.md` "Data layer" bullet: met; it is in the diff and names all three.

## For the human
Recommendation: don't merge yet

I found no defect, so this is a request to check, not a request for changes. If the three checks below look right to you, merge it.

1. **Check the permission logic.** The change adds mock sign-in and enforces `CASE_RESOLVE` and `MODEL_TRAIN`, which this project reserves for a person to check. Confirm the check order and the rule that only the assigned analyst can resolve a case. Also confirm you accept one shared demo password for every user in the prototype. The password predates this PR, but `signIn` now uses it, and it ends up in the web build. This store must not become a real sign-in path.
   - `lib/data/app_store.dart:69-81` (`signIn`)
   - `lib/data/app_store.dart:139-183` (`takeCase`, `resolveCase`)
   - `lib/data/app_store.dart:297-303` (`_requirePermission`)

2. **Accept or reject the differences from the shared docs.** The issue says the store enforces the rules "the way the decision-api would", and these three places don't quite do that. The first two are what the issue specifies; the third follows the spec and intake where the issue is silent.
   - **Quality gate:** `MIN_NEW_LABELS` always passes (`lib/data/app_store.dart:234`), while `model.md` §8 requires at least 50 new labeled cases. Each retrain also adds 0.01 to the metrics, so the gate can't fail through the public API. The CANDIDATE outcome is built but has no test, and failure can't be shown in a demo with this store.
   - **Read access:** `openCases`, `caseById`, `customers`, `users`, `models` and `metrics` return data while signed out and don't check permissions (`lib/data/app_store.dart:88`, `:99-137`, `:187-217`). `decision-api.yaml` requires permissions such as `CASE_READ` on `GET /cases`. `users` exposes staff emails. Screens will have to gate on `can(...)` themselves.
   - **Signed-out writes:** they throw `forbidden`, while the API has a separate 401. `DomainError` has no code for it, as the issue defines it (`lib/data/domain_error.dart`).

3. **Accept the two additions beyond intake's Scope.** Neither is in the issue's file list or intake's Scope; the spec added both, and both are low risk.
   - `test/app/app_scope_test.dart`: `AGENTS.md` asks for widget tests on new shared widgets.
   - The longer "Data layer" bullet in `AGENTS.md`: it sits inside the `factory:start` block that infra's `factory/bin/install` manages, so a reinstall could overwrite it.

**For the next task, not this PR:** `addCaseRecord` and `updateMetrics` (`lib/data/app_store.dart:271-282`) have no permission checks, and `@protected` is only an analyzer hint. The public operations that call them must check first, for example `SIMULATOR_RUN`.

I didn't check the CI status on PR #30, so confirm it is green before merging. `flutter test` on the new files passed locally, and `factory/checks.sh` passed on this commit.
