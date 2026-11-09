STATUS: READY

# Build: Make case #09F35B and NIGHT_TRANSFER v2 follow the data model

## Summary
- `#09F35B` now gets its REVIEW verdict from `HIGH_AMOUNT_NEW_DEVICE` v3, so the exception to `model.md` §5 is gone.
- `NIGHT_TRANSFER` v2 is created 6 days ago, before its shadow starts 5 days ago.
- The verdict test now covers every seeded case with no skip.
- Only the seed and its test changed. Draft PR: #36.

## Changes
- `lib/data/mock/mock_seed.dart`:
  - Removes the "Known exception" comment above the `#09F35B` row.
  - Sets that row to `amount: 3180000`, `amountVsAvg: 4.9` and `isNewDevice: true`.
  - Changes `NIGHT_TRANSFER` v2 to `createdAt: daysAgo(6)`.
- `test/data/mock_seed_test.dart`:
  - Removes `_exceptionCase`.
  - Replaces the exempting verdict test with `'every verdict is the most severe matched hit'`.
  - Replaces the old `#09F35B` test with `'#09F35B is degraded, with REVIEW from HIGH_AMOUNT_NEW_DEVICE'`.
  - Adds `'NIGHT_TRANSFER v2 is created, then shadowed, then submitted'`.
  - Updates the `NIGHT_TRANSFER` expectations to `'hace 6 d'` and `'19 oct'`.

## Acceptance criteria
1. [x] `#09F35B` has the decided values: the `'#09F35B is degraded, with REVIEW from HIGH_AMOUNT_NEW_DEVICE'` test covers all of Requirement 7. `flutter test test/data/mock_seed_test.dart` printed `+40: All tests passed!`.
2. [x] Every seeded verdict is the most severe matched non-shadow hit, with no exemption: `'every verdict is the most severe matched hit'` passes. The `grep` for `_exceptionCase\|Known exception` on both files printed nothing (exit 1).
3. [x] Hits stay truthful for the changed row: `'every hit is the truthful evaluation of its version'` passes, and it appears only as an unchanged context line in the test diff.
4. [x] `NIGHT_TRANSFER` v2 has a valid order: `'NIGHT_TRANSFER v2 is created, then shadowed, then submitted'` passes. The seed has `createdAt: daysAgo(6)` and `since: daysAgo(5)` in that version.
5. [x] `NIGHT_TRANSFER` v2 reads correctly at the test clock: `mock_seed_test.dart` expects `'hace 6 d'` (line 401), `'19 oct'` (line 513), `'08:10'` (line 514) and `'hace 5 d'` (line 515), and all pass.
6. [x] The device derivation is unchanged: `git diff origin/develop -- lib/data/mock/mock_seed.dart` doesn't touch `_deviceFirstSeenAt`, and the `#09F35B` row has no `deviceFirstSeenToday`.
7. [x] The queue order is unchanged: `flutter test test/data/app_store_test.dart` printed `+42: All tests passed!`, and `git diff origin/develop --stat -- test/data/app_store_test.dart` is empty.
8. [x] No other seed value changes: the seed diff touches only the removed comment, the three row values and the one `createdAt` line.
9. [x] Only the seed and its test change: `git diff origin/develop --name-only -- lib test` lists exactly `lib/data/mock/mock_seed.dart` and `test/data/mock_seed_test.dart`.

## Validation
- `bash <main checkout>/factory/checks.sh` from the worktree: passed (exit 0). That covers `flutter pub get`, `dart format`, `flutter analyze`, `flutter test` (158 tests) and `flutter build web --release`.
- `flutter test test/data/mock_seed_test.dart`: passed (40 tests).
- `flutter test test/data/app_store_test.dart`: passed (42 tests).
- The `grep` and `git diff` commands listed under the acceptance criteria gave the results shown there.
- No page was checked: this job changes no UI, and no screen reads this data yet.

## Log
### Round 1
- Implemented the spec from scratch, in one commit (`fc667cf`), and opened draft PR #36.
- WSL git has no `user.name` or `user.email`, so the first commit attempt failed. I passed the identity for that one commit with `git -c`, using `Gomaxd11 <159067553+Gomaxd11@users.noreply.github.com>`: the authenticated `gh` account and issue assignee, in the noreply form already in the repo history. No git config was written, so later commits from this environment will hit the same error until an identity is set.
- The new `#09F35B` test doesn't assert the device's `firstSeenAt`, because Requirement 7 doesn't list it. The value moves through the unchanged `_deviceFirstSeenAt` derivation.
- `amountVsAvg` is 4.9 as the spec decides, although the same customer average works out to about 4.96.
