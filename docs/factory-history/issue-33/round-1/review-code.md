VERDICT: PASS

## Summary
- Changes only `lib/data/mock/mock_seed.dart` and `test/data/mock_seed_test.dart`, as the spec requires; `git diff --name-only` lists exactly those two files.
- `#09F35B` now has amount 3180000, `isNewDevice` true and `amountVsAvg` 4.9. Its REVIEW comes from `HIGH_AMOUNT_NEW_DEVICE` v3 (`amount >= 3000000` and `is_new_device = true`), so the "known exception" comment and the test exemption are gone.
- `NIGHT_TRANSFER` v2 `createdAt` moves to `daysAgo(6)`, before its shadow start (`daysAgo(5)`) and submission, as `model.md` §6 requires. A new test asserts that order.
- The verdict test now covers every seeded case with no skip. The `#09F35B` test asserts the decided values and rule hits.
- Checks passed on this commit, and the diff matches the spec's requirements.

## Findings
None.

## Notes
- `amountVsAvg` is 4.9 as the issue and spec state. The issue also says it is the same customer average, and 3180000 / 2180000 × 3.4 gives about 4.96. Nothing in the tests relates the two, so this is a data-accuracy point for the product owner, not a blocker.
- The device `firstSeenAt` for `#09F35B` now falls 5 minutes before the transaction, through the existing `_deviceFirstSeenAt` derivation. This is intended and keeps the data consistent with `isNewDevice`.
- `docs/factory-history/issue-11/` still describes the old exception. That is the factory's record, so it is left as is.
- The `#09F35B` test's `(code, version)` loop repeats the list in `_evaluatedVersions`. That is acceptable in a test that is meant to be independent of the seed.
