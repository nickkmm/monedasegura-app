STATUS: READY

# Build: Rule lifecycle and simulator operations on AppStore

## Summary
- `AppStore` now runs the full rule lifecycle, from draft through shadow, backtest and approval to retirement of the previous version.
- `evaluate` computes the verdict of `model.md` §5 and counts SHADOW versions.
- `simulateOne` decides synthetic events with the four profiles, opens cases and updates the metrics.
- All 18 acceptance criteria pass, along with `factory/checks.sh`.
- One criterion's wording differs from the spec: hits follow rule list order, so FAR_FROM_HOME comes before NIGHT_TRANSFER (see criterion 13).

## Changes
- `lib/data/app_store.dart`: adds the rule operations, `evaluate`, the simulator operations, condition validation, the scenario profiles and the running id counter. The comment on `addCaseRecord` and `updateMetrics` no longer says they are for "the next task".
- `lib/data/mock/mock_seed.dart`: renames `_holds` to the public `conditionHolds`, and adds `homeCoordinates` and `uuid`, so the store reuses them instead of copying them.
- `lib/data/models/simulation_event.dart` (new): the `SimulationEvent` model.
- `lib/data/models/models.dart`: exports `simulation_event.dart`.
- `test/data/app_store_rules_test.dart` (new): 54 tests with the seeded store and the fixed clock.

## Acceptance criteria
All evidence comes from `flutter test test/data/app_store_rules_test.dart`, which printed `+54: All tests passed!`.

1. [x] `createRule` gives 9 rules with `NIGHT_ATM` last and v1 DRAFT, created by Laura at the clock's time; bad code, taken code and unknown feature throw as specified: group `createRule`.
2. [x] Each listed invalid condition, the empty list and the 121-character name throw `invalid`; `in` on `category` and a number on `score` are accepted: group `condition validation`.
3. [x] `updateDraft` changes the conditions and clears the backtest; on an ACTIVE version it throws `conflict`: group `updateDraft`.
4. [x] `deleteDraft` removes the rule, or only the new version when others exist; on an ACTIVE version it throws `conflict`: group `deleteDraft`.
5. [x] `createVersion` on SCORE_REVIEW creates v5 DRAFT at the front with copied conditions and action, and null backtest and shadow stats; a second call throws `conflict`: group `createVersion`.
6. [x] The full lifecycle on v5, including `approve` and `canApprove` for Laura and Diego, and v4 RETIRED; submitting in SHADOW without a backtest throws `conflict`: group `lifecycle`.
7. [x] Backtest gives 1920 cases; candidate 26/45/37/1812; active TP 41; recall 0.74 before and 0.73 after; equal counts on a second run; `NIGHT_ATM` has null `active` and 0.74; an ACTIVE version throws `conflict`: group `runBacktest`.
8. [x] `reject` gives DRAFT with the reason, null `submittedAt` and null `shadowStats`; an empty reason and one of 1001 characters throw `invalid`: group `reject`.
9. [x] A rejected draft cannot be deleted, but it can be edited, shadowed, backtested and resubmitted to PENDING_APPROVAL: group `reject`.
10. [x] Camilo and a signed-out user get `forbidden` on every listed operation with an unknown id; Laura gets `not_found` on `updateDraft`: group `permissions`.
11. [x] A listener is called once by a successful `createRule` and `simulateOne`, and not at all by a failed `createRule`, which leaves `rules` unchanged: group `notifications`.
12. [x] `approversFor` returns Valentina and Diego; `scoreThresholds` is `(review: 0.6, block: 0.9)`: group `approvers and thresholds`.
13. [x] `evaluate` returns APPROVE, REVIEW and BLOCK for scores 0.1, 0.7 and 0.95; it appends the 6 listed hits; FAR_FROM_HOME goes to 9801/1103/15 and `verdictChanges` is unchanged at 0.7; a null score matches neither score rule: group `evaluate`. The test expects FAR_FROM_HOME v1 before NIGHT_TRANSFER v1, because requirement 14 fixes list order and the seed has FAR_FROM_HOME first. The criterion lists the same 6 hits the other way round.
14. [x] `nextRunNumber` goes 18 to 19, `startRun` returns 18, and the customer is `Cliente nuevo 18.` with `****0018`, `Bogotá`, the clock's time and zero counters: group `runs and origination customers`.
15. [x] 20 ATO events open exactly the 7 cases at `index % 3 == 0`; `openCases`, `metrics.decisions`, `metrics.verdicts` and `hourly[9]` grow to match; a re-run gives the same verdicts and new unique ids; all `shortId`s are distinct: group `simulateOne`. The store has no public decision list, so "20 decisions" is checked through the 20 returned events.
16. [x] Camilo gets `forbidden`; Valentina gets `not_found` on an unknown customer and `invalid` on `DATASET_FRAUD`: group `simulateOne`.
17. [x] 20 events take FAR_FROM_HOME v1 `evaluated` from 9800 to 9820: group `simulateOne`.
18. [x] Indices 0..29 of each scenario have the exact feature keys, source, scenario, types, categories and ranges: group `profiles`.

## Validation
- `bash <main checkout>/factory/checks.sh`: passed, exit 0.
  - `dart format`: 56 files, 0 changed.
  - `flutter analyze`: no issues.
  - `flutter test`: `+236: All tests passed!`
  - `flutter build web --release`: built `build/web`.
- `flutter test test/data/app_store_rules_test.dart`: `+54: All tests passed!`
- This task adds no UI, so no page check applies.

## Log
### Round 1
Implemented the spec from scratch, with the tests. Choices the spec leaves open:
- Simulated ids start at 1000. A case's first 6 characters are that number in hex (`0003e8`...), far below the seeded case prefixes, the lowest of which is `09f35b`, so short ids stay distinct.
- Simulated scores and `amount_vs_avg_30d` are drawn in hundredths, so both ends of each range are reachable and scores already have 2 decimals.
- `Scenario.DATASET_FRAUD` is refused in the profile switch, which runs after the customer lookup and before any change to the store.
- `createRule` and `updateDraft` store an unmodifiable copy of the conditions, so a caller can't change them after validation.
- An empty list for `in` is accepted, because neither the spec nor the API refuses it. Such a condition never matches.
