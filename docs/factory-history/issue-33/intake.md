DECISION: ACCEPT
RISK: low
SURFACES: none
RESCOPED: no

## Summary
- Accepted as written: a change to the mock seed and its tests only, with the values already decided by @nickkmm.
- `#09F35B` will get its REVIEW verdict from `HIGH_AMOUNT_NEW_DEVICE`, so the exception to `model.md` §5 goes away.
- `NIGHT_TRANSFER` v2 will be created before its shadow starts, as `model.md` §6 requires.
- Two side effects beyond the issue's list: the case's device `firstSeenAt` becomes recent, and the `'22 oct'` test expectation becomes `'19 oct'`.

## Scope
Build:

1. **Case `#09F35B`** in `MockSeed.build(now)`:
   - `amount` 3180000, `isNewDevice` true, `amountVsAvg` 4.9. The `amount`, `is_new_device` and `amount_vs_avg_30d` features follow these values.
   - `HIGH_AMOUNT_NEW_DEVICE` v3 is matched. `SCORE_BLOCK`, `SCORE_REVIEW`, `VELOCITY_1H`, `NIGHT_TRANSFER` v1 and `FAR_FROM_HOME` are not.
   - Verdict stays REVIEW, score null, degraded true, model version null.
   - The "Known exception" comment on the row is removed.
2. **`NIGHT_TRANSFER` v2**: `createdAt` moves from `daysAgo(3)` to `daysAgo(6)`. `shadowStats.since` stays `daysAgo(5)` and `submittedAt` stays today 08:10.
3. **Tests**:
   - Remove `_exceptionCase` and the exemption. One test asserts that every seeded case's verdict is the most severe matched non-shadow hit, with no exemption.
   - A test asserts the `#09F35B` values in acceptance criterion 1.
   - A test asserts `createdAt` < `shadowStats.since` < `submittedAt` for `NIGHT_TRANSFER` v2.
   - Update the `NIGHT_TRANSFER` expectations that read `createdAt`: `'hace 3 d'` becomes `'hace 6 d'`, and `'22 oct'` becomes `'19 oct'`.
   - `flutter test` passes, with the queue order unchanged and `#09F35B` still last.

Two readings the spec should follow:

- **Device first seen.** The seed derives a device's `firstSeenAt` from `isNewDevice`, so this case's device moves from months ago to 5 minutes before the transaction. This is a consequence of the requested change, and it keeps the data truthful, so it does not break "no other seed value changes". Leave the derivation as it is, with no special handling for this row.
- **`'22 oct'` expectation.** The issue only names `'hace 3 d'`, but the `NIGHT_TRANSFER` v2 test also checks `'22 oct'` against `createdAt`. It has to become `'19 oct'`, which matches the date in the issue.

Left out: widgets and screens, as the issue says, and any other seed value.

## Why
The issue is specific, and I checked its values against the `develop` checkout and `model.md` §5 and §6. `HIGH_AMOUNT_NEW_DEVICE` v3 requires `amount >= 3000000` and `is_new_device = true`, so the new row matches it, and no other non-shadow rule matches: score rules can't match when degraded, and `tx_count_1h` 2, `is_night` false and `km_from_home` 6 keep the rest off. Hits are computed from the conditions in `lib/data/mock/mock_seed.dart`, the app has no screens using this data yet, and no contract, data model or feature catalog change is needed.

The `#09F35B` queue position in `test/data/app_store_test.dart` depends on verdict and score, which don't change.
