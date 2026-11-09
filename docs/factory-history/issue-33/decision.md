ESCALATE

## Summary
- Recommendation: merge. A person always merges in this project, so this escalation is the normal hand-off.
- `#09F35B` now gets its REVIEW from `HIGH_AMOUNT_NEW_DEVICE` v3, and its exception and test exemption are gone.
- `NIGHT_TRANSFER` v2 is now created (6 d ago) before its shadow starts (5 d ago).
- Only the mock seed and its test changed. Gate and code review passed on the current commit, `fc667cf`.
- One small point to accept: `amountVsAvg` is 4.9 as the issue decided, though the same average gives about 4.96.

## Why
All nine acceptance criteria are met, the final round is `GATE: PASS` and `VERDICT: PASS`, and the change stays inside intake's Scope. It touches no auth, contract, migration, environment variable, deploy config or dependency, and it brings the seed into line with `model.md` §5 and §6 rather than away from them. The review's Notes describe intended behavior or a minor data point, not a real problem.

## Acceptance criteria
1. `#09F35B` has the decided values: met. The diff shows them on the row and the new test asserts them. I ran `flutter test` on `test/data/mock_seed_test.dart` and `test/data/app_store_test.dart`, and all 82 tests passed.
2. Every verdict is the most severe matched non-shadow hit, with no exemption: met. The test has no skip, `_mostSevere` filters on `h.matched && !h.shadow`, and my `grep` for `_exceptionCase\|Known exception` found nothing.
3. Hits stay truthful for the changed row: met. `'every hit is the truthful evaluation of its version'` is not in the diff and passes in my run.
4. `NIGHT_TRANSFER` v2 has a valid order: met. The seed has `createdAt: daysAgo(6)` and `since: daysAgo(5)`, and a new test asserts `createdAt` < `since` < `submittedAt`.
5. `NIGHT_TRANSFER` v2 reads correctly at the test clock: met. The diff changes the expectations to `'hace 6 d'` and `'19 oct'`, and leaves `'hace 5 d'` and `'08:10'` as they were.
6. The device derivation is unchanged: met. `_deviceFirstSeenAt` is not in the diff, and the row has no `deviceFirstSeenToday`.
7. The queue order is unchanged: met. `test/data/app_store_test.dart` is not in the diff, still asserts `#09F35B` last with a null score, and passes in my run.
8. No other seed value changes: met. I read the seed diff: it holds only the removed comment, the three row values and the one `createdAt` line.
9. Only the seed and its test change: met. `git diff --name-only origin/develop...HEAD` lists exactly those two files.

## For the human
Recommendation: merge

None of this project's "check before merging" conditions apply, so no check is required before you merge. Three things are worth a quick look:

- **`amountVsAvg` is 4.9, not about 4.96.** The issue says "same customer average", and 2180000 / 3.4 is about 641176, which gives about 4.96 for the new amount. The issue also states 4.9 explicitly, so the build uses it, and no test relates the two. If you want the exact figure, that is a one-line follow-up.
- **The device `firstSeenAt` for `#09F35B` also moves.** It goes from months ago to 5 minutes before the transaction, through the existing derivation. The diff doesn't show this, and issue criterion 5 says no other seed value changes. Intake accepted it as a direct result of `isNewDevice: true`, and I agree.
- **The commit identity was chosen by the builder.** WSL git has no `user.name` or `user.email`, so the builder passed `Gomaxd11` for this one commit, with `git -c`. Later commits from this environment will fail until an identity is set.

Files to look at:
- `lib/data/mock/mock_seed.dart`: the `#09F35B` row and `NIGHT_TRANSFER` v2.
- `test/data/mock_seed_test.dart`: the `verdicts` group and the new lifecycle test.
