# Make case #09F35B and NIGHT_TRANSFER v2 follow the data model

> Issue #33: Make case #09F35B and NIGHT_TRANSFER v2 consistent with the data model in the mock seed

## Summary
- Only `lib/data/mock/mock_seed.dart` and `test/data/mock_seed_test.dart` change; every value was decided in the issue.
- `#09F35B` gets its REVIEW verdict from `HIGH_AMOUNT_NEW_DEVICE`, so the exception to `model.md` §5 and its test exemption are removed.
- `NIGHT_TRANSFER` v2 is now created before its shadow starts, as the `model.md` §6 lifecycle requires.
- The case's device `firstSeenAt` becomes recent through the existing derivation, with no special handling, as intake decided.
- `amountVsAvg` 4.9 is used as the issue states, although the same customer average works out to about 4.96 (see Assumptions).

## Context
The shared rules are in `<main checkout>/../monedasegura-infra/docs/model.md`: §5 says the verdict is the most severe matched `ACTIVE` rule, and that rules on `score` don't match when degraded. §6 gives the lifecycle order `DRAFT → SHADOW → PENDING_APPROVAL → ACTIVE`.

**Seed: `lib/data/mock/mock_seed.dart`**
- `_caseRows()` holds one `_CaseRow` per case, and `MockSeed.build` derives the records from it. The `#09F35B` row (`id: '09f35b67-…'`, customer `Daniela C.`) has `amount: 2180000`, `amountVsAvg: 3.4` and `isNewDevice: false`, with a three-line "Known exception to model.md §5" comment above it.
- The decision's features, including `amount`, `amount_vs_avg_30d` and `is_new_device`, come from the row. `transaction.amount` also comes from the row, and `degraded` and `modelVersion` follow from `score == null`.
- Rule hits are computed, not written by hand: `_hit` evaluates each version in `_evaluatedVersions` against the features. The new row values therefore make `HIGH_AMOUNT_NEW_DEVICE` v3 match (`amount >= 3000000` and `is_new_device = true`), and no edit to the hits is needed.
- `_deviceFirstSeenAt` returns `occurredAt - 5 min` when `row.isNewDevice` is true and the row has no `deviceFirstSeenToday`. Otherwise it returns a date months ago.
- In `_buildRules`, `NIGHT_TRANSFER` v2 is built with `createdAt: daysAgo(3)`, `shadowStats.since: daysAgo(5)` and `submittedAt: _todayAt(now, 8, 10)`.

**Tests: `test/data/mock_seed_test.dart`** (clock `DateTime(2026, 10, 25, 9, 45)`)
- `_exceptionCase` is declared on line 6.
- Group `verdicts` has `'every verdict but #09F35B is the most severe matched hit'`, which skips the case, and `'#09F35B is degraded, with no matched non-shadow hit'`, which asserts the old amount and `_mostSevere == APPROVE`. The existing `_mostSevere` helper already ignores shadow hits and should be reused.
- `'latest authors and ages match the issue table'` expects `'NIGHT_TRANSFER': ('Laura Méndez', 'hace 3 d')`.
- `'NIGHT_TRANSFER v2 matches its own paragraph'` expects `formatDayMonth(v2.createdAt)` to be `'22 oct'`.
- Other `'hace 3 d'` expectations (`SCORE_REVIEW` and model `v1`) read different data and must stay as they are.

**`test/data/app_store_test.dart`** asserts `open.last.shortId == '#09F35B'` with a null score. It needs no change.

No file under `lib/` other than the seed reads the changed values in a way that needs editing, and there are no screens using this data yet.

## Requirements
1. In the `#09F35B` row of `_caseRows()`, set `amount: 3180000`, `amountVsAvg: 4.9` and `isNewDevice: true`. Verdict stays `Verdict.REVIEW` and the row still has no score, so it stays degraded with a null model version.
2. Remove the "Known exception to model.md §5" comment above that row.
3. Don't add `deviceFirstSeenToday` or `hitVersions` to that row, and don't change `_deviceFirstSeenAt`. The device's `firstSeenAt` moves to 5 minutes before the transaction through the existing derivation.
4. In `_buildRules`, change `NIGHT_TRANSFER` v2 `createdAt` from `daysAgo(3)` to `daysAgo(6)`. `shadowStats.since` stays `daysAgo(5)` and `submittedAt` stays `_todayAt(now, 8, 10)`.
5. In `test/data/mock_seed_test.dart`, remove `_exceptionCase` and every use of it.
6. Replace the exempting verdict test with one that asserts, for every seeded case and with no skip, that `_mostSevere(view.decision)` equals `view.verdict`. Its name must no longer mention an exception.
7. Replace the `'#09F35B is degraded…'` test with one that asserts on `#09F35B`:
   - amount 3180000, verdict REVIEW, null score, degraded true, null model version;
   - features `amount` 3180000, `amount_vs_avg_30d` 4.9, `is_new_device` true;
   - `HIGH_AMOUNT_NEW_DEVICE` v3 matched and not shadow;
   - `SCORE_BLOCK`, `SCORE_REVIEW`, `VELOCITY_1H`, `NIGHT_TRANSFER` v1 and `FAR_FROM_HOME` not matched.
8. Add a test asserting that, for `NIGHT_TRANSFER` v2, `createdAt` is before `shadowStats.since` and `shadowStats.since` is before `submittedAt`.
9. Update the `NIGHT_TRANSFER` expectations that read `createdAt`: `'hace 3 d'` becomes `'hace 6 d'` in the authors and ages table, and `'22 oct'` becomes `'19 oct'` in the paragraph test.
10. No doc update is needed: `AGENTS.md` and `docs/deliveries/flutter-prototype.md` don't mention these values. Don't edit `docs/factory-history/`.

## Acceptance criteria
1. `#09F35B` has the decided values. Verify: the Requirement 7 test exists in `test/data/mock_seed_test.dart` and passes under `flutter test test/data/mock_seed_test.dart`.
2. Every seeded verdict is the most severe matched non-shadow hit, with no exemption. Verify: the Requirement 6 test passes, and `grep -n "_exceptionCase\|Known exception" lib/data/mock/mock_seed.dart test/data/mock_seed_test.dart` prints nothing.
3. Hits stay truthful for the changed row. Verify: the existing `'every hit is the truthful evaluation of its version'` test passes unmodified.
4. `NIGHT_TRANSFER` v2 has a valid order. Verify: the Requirement 8 test passes, and `mock_seed.dart` has `createdAt: daysAgo(6)` and `since: daysAgo(5)` in that version.
5. `NIGHT_TRANSFER` v2 reads correctly at the test clock. Verify: `mock_seed_test.dart` expects `'hace 6 d'` for it in the authors and ages table and `'19 oct'` in the paragraph test, while `formatDayAgo(v2.shadowStats!.since, now)` still expects `'hace 5 d'` and `formatHm(v2.submittedAt!)` still expects `'08:10'`.
6. The device derivation is unchanged. Verify: `git diff origin/develop -- lib/data/mock/mock_seed.dart` shows no change to `_deviceFirstSeenAt`, and the `#09F35B` row has no `deviceFirstSeenToday`.
7. The queue order is unchanged. Verify: `flutter test test/data/app_store_test.dart` passes, and `git diff origin/develop --stat -- test/data/app_store_test.dart` is empty, so `#09F35B` is still asserted last.
8. No other seed value changes. Verify: `git diff origin/develop -- lib/data/mock/mock_seed.dart` touches only the removed comment, the three row values and the one `createdAt` line.
9. Only the seed and its test change. Verify: `git diff origin/develop --name-only -- lib test` lists exactly `lib/data/mock/mock_seed.dart` and `test/data/mock_seed_test.dart`.

## Out of scope
- Widgets and screens, including #16, #21 and #22, which are already updated for these values.
- Any other seed value: other cases, rules, `hits7d`, `backtest`, `shadowStats` figures, models or dashboard metrics.
- Refactoring the seed, its helpers or the hit evaluation.
- Adding a customer average field or deriving `amountVsAvg` from one.
- Changing `model.md` or any other file in `monedasegura-infra`.
- Changing the `SCORE_REVIEW` or model `v1` `'hace 3 d'` expectations, which read other data.
- Changing the `verdicts`, `time` or other seed tests beyond what the Requirements list.

## Assumptions
- **`amountVsAvg` is exactly 4.9.** The issue calls this "same customer average", but 2180000 / 3.4 is about 641176 and 3180000 over that is about 4.96. The issue states 4.9 explicitly and @nickkmm decided it, so it is used as written; no test relates this feature to an average.
- **The device `firstSeenAt` change is allowed under "no other seed value changes".** Intake decided this: it follows from `isNewDevice` and keeps the data truthful.
- **`'22 oct'` becomes `'19 oct'`.** The issue names only `'hace 3 d'`, but intake decided this one too, and the issue gives 19 oct as the date.
- **The `#09F35B` test keeps its place in group `verdicts` and is replaced rather than added alongside.** The old test asserts the removed exception, so it can't stay.
- **The lifecycle test can use the suite's shared seed and clock.** The issue's criterion doesn't ask for it across clocks, and `_todayAt` clamping can't put `submittedAt` before a date 5 days ago.
