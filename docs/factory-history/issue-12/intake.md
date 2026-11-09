DECISION: ACCEPT
RISK: medium
SURFACES: security
RESCOPED: no

## Summary
- Accepted as written: an in-memory `AppStore`, `DomainError` and `AppScope`, with tests.
- Dependency #11 is merged, so the models, labels and mock seed this builds on are on `develop`.
- I checked all seven acceptance criteria by hand against the seed and the permission table; they are consistent.
- No change to the contract or the data model is needed, because `model.md` §4, §7 and §8 and `decision-api.yaml` already cover these rules.
- One branch can't be reached in the mock: a retrain always passes the quality gate. It is built as specified but needs no test.

## Scope
Build what the issue specifies:

- **`DomainError`**: carries a code (`forbidden`, `conflict`, `not_found`, `invalid`) and an English message.
- **`AppStore`**: a `ChangeNotifier` over mutable copies of the seed, with an injected clock and an `AppStore.seeded` factory.
  - **Session**: sign-in, sign-out, `can`, and user lookups. The password is never logged.
  - **Cases**: the five case lists in the specified orders, `caseById`, `takeCase` and `resolveCase`. Labeling changes only the case, never its decision or transaction.
  - **Customers**: the list in seed order and lookup by id.
  - **Dashboard**: `metrics`, plus `openCaseCount` and `unassignedCaseCount` computed from the case list. The seeded `metrics.openCases` (214) stays as it is, and the KPI uses the computed counts.
  - **Models**: the list newest first, `activeModel` and `retrainNow`.
  - **Helpers for the next task**: adding a transaction, decision and case, and updating the metric counters. These have no callers yet and must still pass `flutter analyze`.
- **`AppScope`**: an `InheritedNotifier<AppStore>` with `of` and `read`, which asserts when missing.
- **Tests**: `test/data/app_store_test.dart` covers the seven acceptance criteria with the fixed clock from the issue.

Where the issue leaves a detail open, the spec should follow the API:

- An unknown case id throws `not_found`.
- A signed-out user gets `forbidden`, because `can` is false.
- Permission is checked before state, then notes length.
- A failed operation or failed sign-in changes nothing and does not notify listeners. Successful `signIn` and `signOut` count as mutations and notify once.
- "Open" in `recentCases` means OPEN or IN_REVIEW, the same as `openCases`.
- `v{n+1}` is numbered from the highest existing version.

Because every retrain adds 0.01 to the active metrics, the gate always passes in the mock. Build the CANDIDATE outcome as the issue describes, but it needs no acceptance test, since it can't be reached through the public API.

Left out, as the issue says:

- Rule lifecycle and simulator operations (next task)
- Widgets and screens
- Persistence
- Any HTTP client

Wiring `AppScope` into `main.dart` isn't requested either. Manual activation of a CANDIDATE (`POST /models/{modelId}/activate`) isn't in this issue, so it isn't part of this job.

## Why
This is one of the planned foundations in `docs/deliveries/flutter-prototype.md`, and no `AppStore`, `AppScope` or `DomainError` exists in `lib/` yet. The seed in `lib/data/mock/mock_seed.dart` gives 9 open cases and 3 resolved today, with the expected BLOCK order, and `rolePermissions` in `lib/data/models/enums.dart` gives the access the criteria expect. The rules match `model.md` and `decision-api.yaml`, including the queue order, the assigned-analyst rule and the 2000-character notes limit. I rated it medium because every screen will rely on this shared code. It isn't high because the sign-in and permission checks are simulated, with no real credentials or data, and everything can be verified with unit tests.
