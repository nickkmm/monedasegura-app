# Rule lifecycle and simulator operations on AppStore

> Issue #15: Add rule lifecycle and simulator operations to the AppStore

## Summary
- Specifies the rule lifecycle, rule evaluation and simulator operations on the in-memory `AppStore`, following intake's scope and readings.
- Includes intake's one rescope: `deleteDraft` also refuses a draft that came back from approval, because it has already run in shadow.
- Checked against the seed: the issue's nine criteria hold, and the spec adds exact expected values (backtest numbers, 7 flagged ATO events).
- Names three traps in the current code: a case's `shortId` is its first 6 id characters, the seed's metrics are `const`, and the condition matcher and home coordinates are private to the seed.
- Adds no UI and calls no API; a test file and one small model are the only new files.

## Context
- `lib/data/app_store.dart`: `AppStore extends ChangeNotifier`, built from `MockSeed`. It has sessions, cases, customers, metrics and models, but no rule or simulator state. Patterns to reuse:
  - `_requirePermission` treats signed out as lacking the permission and returns the user.
  - `_requireCaseIndex` is the `not_found` pattern.
  - `retrainNow` is the shape of an operation.
  - `addCaseRecord` and `updateMetrics` are the non-notifying helpers left for this task. `test/data/app_store_test.dart` uses them through a subclass, so they stay.
- `lib/data/mock/mock_seed.dart`:
  - `seed.rules` holds 8 `RuleView`s and `seed.simulationRunCount` is 17; the store reads neither yet.
  - `MockSeed._holds` already evaluates a condition, including "a rule on `score` never matches when the score is null".
  - `_homeCoordinates` maps a city to its coordinates. Seeded transactions use `latitude: home.$1 - km / 111, longitude: home.$2`.
  - Seeded transfers have `category: null` and a `counterparty` matching `^\*{4}\d{4}$`.
  - `_hourly` has 24 buckets, and `_buildMetrics` uses a `const` verdicts map and that `const` list, so neither can be mutated in place.
- `lib/data/models/rule.dart`: `Rule`, `RuleVersion` (`copyWith` has `clearBacktest`, `clearShadowStats` and `clearSubmittedAt`, but cannot clear `rejectionReason`), `RuleView` (`versions` newest first, `latest`, `active`, `version(n)`), `Condition`, `ConditionOp` (`code` is the API string), `ShadowStats`, `BacktestCounts`, `Backtest`.
- `lib/data/models/decision.dart`: `RuleHit` and `Decision` (immutable, with `caseId`).
- `lib/data/models/fraud_case.dart`: `FraudCase` and `CaseView`. `CaseView.shortId` is the first 6 id characters, upper-cased.
- `lib/data/models/transaction.dart`, `customer.dart`, `dashboard_metrics.dart` (`HourBucket`, `copyWith`), `feature_definition.dart` (`featureCatalog`, which includes `score`), `enums.dart` (`Scenario` also has `DATASET_FRAUD`, which has no profile in this issue), and the barrel `models.dart`.
- `lib/data/domain_error.dart`: `DomainError(code, message)` with `forbidden`, `conflict`, `not_found` or `invalid`.
- Contract and domain, in the sibling repo at `<main checkout>/../monedasegura-infra/docs/`: `model.md` §5 and §6, `features.md` (defaults), `api/decision-api.yaml` (`/rules`, `/simulator/runs`).
- Seeded users for the tests: Valentina Ríos (ADMIN), Laura Méndez and Diego Salazar (RISK_LEAD), Camilo Torres (ANALYST). `MockSeed.demoPassword` signs in any of them.

## Requirements

### General
1. The formulas, limits, ranges and signatures in `issue.md` ("Rules", "Rule evaluation", "Simulator") are binding. They are not all repeated here; this list adds what the issue leaves open.
2. Every mutation checks, in this order: permission (`forbidden`), unknown id (`not_found`), state (`conflict`), input (`invalid`). So in `createRule` a taken `code` gives `conflict` before any other input is checked, and in `approve` the approver-is-not-creator check comes after the state check.
3. A failed operation changes nothing and does not notify. A successful one calls `notifyListeners()` exactly once.
4. All failures are `DomainError`. An unknown rule id, or a version number the rule doesn't have, gives `not_found`.

### Rules
5. Add to `AppStore`: `rules`, `ruleById`, `ruleByCode`, `createRule`, `createVersion`, `updateDraft`, `deleteDraft`, `startShadow`, `runBacktest`, `submitForApproval`, `approve`, `reject`, `canApprove`, `approversFor` and `scoreThresholds`, with the issue's signatures. `rules` is unmodifiable, in seed order with new rules appended.
6. Condition validation follows the issue, and additionally: `in` takes a `List<String>`; `=` and `!=` on a string take a `String`. An empty conditions list is `invalid`.
7. New versions go at the front of `versions`, numbered from the highest existing version + 1, with `createdBy` the current user and `createdAt = now`. Backtest, shadow stats, `hits7d`, approval fields and `rejectionReason` are not copied.
8. `deleteDraft` throws `conflict` for any version that isn't DRAFT **and for a DRAFT with a `rejectionReason`**. Such a draft can still be edited, shadowed again and resubmitted. Carry a `// Prototype-only: not in decision-api.yaml.` comment on `deleteDraft`.
9. `rejectionReason` stays on the version after it is resubmitted or approved, and is overwritten only by another rejection. That is what keeps requirement 8 true.
10. `runBacktest`:
    - `h` is the sum of the code units of `feature + op.code + value.toString()` over all conditions.
    - `active` is `view.active?.backtest?.candidate`.
    - When `active` is null (no ACTIVE version, or one without a backtest), `systemRecallAfter` is 0.74.
    - `runAt = now`.
11. `submitForApproval` carries a comment saying it is prototype-only that `shadowStats != null` is enough: `model.md` §6 asks for real shadow hits, and the decision-service stays stricter.
12. `reject` clears `submittedAt` and `shadowStats` and keeps the backtest, as the issue lists. `approve` retires the previous ACTIVE version of that rule.
13. `scoreThresholds` reads the first `score >=` condition of the ACTIVE SCORE_REVIEW and SCORE_BLOCK versions, falling back to 0.6 and 0.9 respectively when there is none, because the return type is non-nullable.

### Evaluation
14. `evaluate` has no permission check and does not notify. It goes through rules in list order and, within a rule, through its ACTIVE and SHADOW versions, appending one `RuleHit` per version to `hitsOut` (`shadow` true for SHADOW).
15. Don't duplicate the condition matcher: make `MockSeed._holds` public (for example `MockSeed.conditionHolds`) and use it from both the seed and the store.
16. `verdictChanges` +1 means: a matched SHADOW version whose action is more severe than the verdict from the ACTIVE versions alone. `hits7d` is not touched.

### Simulator
17. Add `nextRunNumber`, `startRun`, `createOriginationCustomer` and `simulateOne` with the issue's behaviour and profiles, and `SimulationEvent` in `lib/data/models/simulation_event.dart`, exported from `lib/data/models/models.dart`.
18. `simulateOne` guards with `SIMULATOR_RUN`, then an unknown `customerId` gives `not_found`, then `Scenario.DATASET_FRAUD` gives `invalid`. It notifies once.
19. `createOriginationCustomer`: N is the current run count, which is the number the last `startRun` returned. `maskedName` is `Cliente nuevo N.` with the trailing period, and `maskedDocument` is `****` + N padded to four digits (`****0018`), keeping the last 4 digits if N is longer.
20. All randomness in `simulateOne` comes from `Random(runNumber * 1000 + index)`, drawn in an order that doesn't depend on store state, so the same run number and index give the same verdict.
21. Ids come from one running counter in the store, not from the seeded `Random`, starting above every seeded number and never reused, so re-running a run number creates new records and a deleted rule's id never returns. Use the seed's UUID shape and groups (`c1000000` rules, `a2000000` customers, `b1000000` devices, `b2000000` transactions, `b3000000` decisions).
22. A case id must put the counter in its **first 6 characters** (for example `<6 hex digits>00-0000-4000-8000-000000000000`), so that `CaseView.shortId` is unique across all cases.
23. Each event's features contain every `featureCatalog` name except `score`, using the profile's values, then:
    - `amount` from the transaction;
    - `category` from the transaction, or `unknown` when it is null;
    - `hour_of_day` from `occurredAt`, and `is_night` from `occurredAt` (hour 22-23 or 0-3) unless the profile sets it;
    - `account_age_days` from the customer (whole days) unless the profile sets it;
    - the rest from the `features.md` defaults, so `is_new_device` is `true` unless the profile sets it, and CARD_FRAUD events get `true`.
24. Each event creates a new `Device` (`firstSeenAt = now`, `os` from the seeded `Random`). The transaction has `source: SIMULATOR`, the scenario, and `occurredAt = now`. Latitude and longitude follow the seed's formula, using the customer's home city and `km_from_home`; expose the seed's coordinates to do so rather than copying them. Transfers have `category: null` and a counterparty of `****` + 4 digits; non-transfers have a null counterparty.
25. The `Decision` is ORIGINAL, `degraded: false`, `modelVersion = activeModel?.version`, latency 80-160 ms inclusive, `decidedAt = now`, and `caseId` set for REVIEW and BLOCK. Score ranges and all other ranges are inclusive; scores are rounded to 2 decimals before evaluation.
26. REVIEW and BLOCK events add a `CaseView` with an OPEN unassigned `FraudCase` through `addCaseRecord`. APPROVE events store the device, transaction and decision but no case.
27. Metrics, through `updateMetrics` with new collections: `decisions` +1, `verdicts[verdict]` +1 and `hourly[now.hour]`'s matching counter +1. `metrics.openCases` and all other fields stay as they are.

### Tests
28. Add `test/data/app_store_rules_test.dart` with a seeded store and the fixed clock `DateTime(2026, 10, 25, 9, 45)`, covering every acceptance criterion below. Existing tests keep passing.

## Acceptance criteria
All are verified by `flutter test test/data/app_store_rules_test.dart`, with the seeded store and the clock above. "Throws X" means a `DomainError` with code X.

1. As Laura Méndez, `createRule(code: 'NIGHT_ATM', name: 'Retiro nocturno', conditions: [Condition('is_night', ConditionOp.eq, true)], action: RuleAction.REVIEW)` gives 9 rules, with `NIGHT_ATM` last and v1 DRAFT, created by Laura at the clock's time. Code `night` throws `invalid`; code `SCORE_BLOCK` throws `conflict`; a condition with feature `type` throws `invalid`.
2. Condition validation: `Condition('is_night', ConditionOp.gt, true)`, `Condition('amount', ConditionOp.inList, ['a'])`, `Condition('amount', ConditionOp.gte, 'x')`, `Condition('category', ConditionOp.inList, 'grocery_pos')`, an empty conditions list and a 121-character name each throw `invalid`. `Condition('category', ConditionOp.inList, ['grocery_pos'])` and `Condition('score', ConditionOp.gte, 0.5)` are accepted.
3. `updateDraft` on that v1 changes its conditions and clears a previous backtest; `updateDraft` on SCORE_BLOCK v2 (ACTIVE) throws `conflict`.
4. `deleteDraft` on the new rule's v1 removes the rule (8 rules again and `ruleByCode('NIGHT_ATM')` is null); `deleteDraft` on an ACTIVE version throws `conflict`. Deleting a new DRAFT version of a rule with other versions removes only that version.
5. `createVersion` on SCORE_REVIEW creates v5 DRAFT, at the front of `versions`, copying `score >= 0.6` and action REVIEW, created by the current user, with null backtest and shadow stats. Calling it again throws `conflict`.
6. Lifecycle on that v5, created by Laura Méndez: `submitForApproval` before shadow throws `conflict`; after `startShadow`, `runBacktest` and `submitForApproval` it is PENDING_APPROVAL with `submittedAt` set; `approve` as Laura Méndez throws `forbidden` and `canApprove` is false for her; `canApprove` is true for Diego Salazar; `approve` as Diego makes v5 ACTIVE with `approvedBy` and `approvedAt` set, and v4 RETIRED. `submitForApproval` in SHADOW without a backtest throws `conflict`.
7. `runBacktest` on that v5 returns `casesEvaluated` 1920; candidate TP 26, FP 45, FN 37, TN 1812; `active` TP 41; `systemRecallBefore` 0.74; `systemRecallAfter` 0.73. Running it twice gives equal counts. On a rule with no ACTIVE version, such as `NIGHT_ATM`, `active` is null and `systemRecallAfter` is 0.74. On an ACTIVE version it throws `conflict`.
8. `reject` on NIGHT_TRANSFER v2 as Valentina Ríos with reason `Falta evidencia` gives DRAFT with that `rejectionReason`, null `submittedAt` and null `shadowStats`. An empty reason, or one of 1001 characters, throws `invalid`.
9. After that rejection, `deleteDraft` on NIGHT_TRANSFER v2 throws `conflict` and the version is still there; `updateDraft` on it succeeds, and after `startShadow`, `runBacktest` and `submitForApproval` it is PENDING_APPROVAL again.
10. As Camilo Torres and when signed out, each `RULE_WRITE` operation, `approve`, `reject`, `startRun`, `createOriginationCustomer` and `simulateOne` throws `forbidden`, even with an unknown id. As Laura Méndez, an unknown rule id on `updateDraft` throws `not_found`.
11. A listener registered on the store is called exactly once by a successful `createRule` and a successful `simulateOne`, and not at all by a failed `createRule`. A failed `createRule` leaves `rules` unchanged.
12. `approversFor` on NIGHT_TRANSFER v2 (created by Laura Méndez) returns Valentina Ríos and Diego Salazar. `scoreThresholds` in the seed is `(review: 0.6, block: 0.9)`.
13. `evaluate({'km_from_home': 400.0}, 0.1, hits)` returns APPROVE, appends 6 hits (SCORE_BLOCK v2, SCORE_REVIEW v4, HIGH_AMOUNT_NEW_DEVICE v3, VELOCITY_1H v1, NIGHT_TRANSFER v1, FAR_FROM_HOME v1), and takes FAR_FROM_HOME v1's stats from 9800/1102/14 to 9801/1103/15. The same features with score 0.7 return REVIEW and leave `verdictChanges` unchanged. With score 0.95 they return BLOCK. With score null, the SCORE_BLOCK and SCORE_REVIEW hits are not matched.
14. As Valentina Ríos, `nextRunNumber` is 18 and `startRun()` returns 18, then `nextRunNumber` is 19. `createOriginationCustomer()` then adds a customer named `Cliente nuevo 18.` with document `****0018`, home city `Bogotá`, `createdAt` the clock's time, and 0 for `transactions30d` and `previousFrauds`.
15. As Valentina Ríos, 20 `simulateOne(scenario: Scenario.ATO, customerId: <Sofía V.>, runNumber: 18, index: 0..19)` calls produce 20 decisions; exactly the 7 events with `index % 3 == 0` are REVIEW or BLOCK; each of those has an OPEN unassigned case in `openCases` (which grows by 7) whose id equals `decision.caseId`; `metrics.decisions` grows by 20; and `metrics.verdicts` and `hourly[9]` grow by the matching verdict counts. Running the same run number and indices again yields the same verdicts and new unique transaction, decision and case ids. All `shortId`s in `openCases` are distinct.
16. As Camilo Torres, `simulateOne` throws `forbidden`. As Valentina Ríos, an unknown customer id throws `not_found` and `Scenario.DATASET_FRAUD` throws `invalid`.
17. After 20 simulated events, FAR_FROM_HOME v1 (SHADOW) has `evaluated` increased by 20.
18. Profiles, over indices 0..29 of each scenario. Each event's feature keys are exactly `featureCatalog`'s names minus `score`, and its transaction has `source` SIMULATOR and the scenario.
    - NORMAL events are DEBIT in the listed categories and ranges, `is_night` and `is_new_device` false, verdict APPROVE, and no case.
    - CARD_FRAUD events are DEBIT `shopping_net`, in the listed ranges, `is_night` and `is_new_device` true.
    - ATO events with `index % 3 == 0` are TRANSFER in the listed ranges with null `category` and feature `category` `unknown`; the others are DEBIT `grocery_pos` in the listed ranges.
    - ORIGINATION events are TRANSFER in the listed ranges with `account_age_days` 0 and `is_new_device` true.

## Out of scope
- Widgets, screens, on-screen text beyond the seed-style strings `Cliente nuevo N.` and `Bogotá`, and theme changes.
- User administration (`/users`), activating a CANDIDATE model, re-evaluating degraded decisions, persistence, and any real API or HTTP call.
- A delete operation other than `deleteDraft`, a retire operation, or stopping a shadow run.
- Stricter rules than the issue's: requiring real shadow traffic before submitting, blocking a creator from rejecting their own version, or checking `category` against `allowedValues`.
- Keeping customer history or computing velocity features from past events, updating `transactions30d`, `hits7d` or `metrics.openCases`.
- Changing `factory/checks.sh`, `factory/config.json`, or the sibling `monedasegura-infra` repo.
- Doc updates: `AGENTS.md`'s data-layer description of the store stays accurate, so none is needed.

## Assumptions
- `deleteDraft` refuses rejected drafts (intake's rescope). They've already run in shadow, and the issue limits deleting to never-evaluated drafts.
- `rejectionReason` stays through resubmission and approval. `copyWith` can't clear it, and it is the only marker of a draft that has run in shadow.
- An ACTIVE version with no backtest counts as "no active" in `runBacktest`. The formula has no counts to subtract, and every seeded ACTIVE version has one, so this only matters after a future seed change.
- `op.code` (`>=`), not `op.symbol` (`≥`), feeds the backtest hash. The issue says "feature+op+value strings", and the code is the API's value; it fixes the numbers in criterion 7.
- Scores are rounded to 2 decimals, because the seed and the screens show 2 decimals and a displayed `0,90` should not fail `score >= 0.9`.
- `Scenario.DATASET_FRAUD` gives `invalid`. The issue defines no profile for it, and it comes from the seed dataset, not the simulator.
- A simulated `Device` has `firstSeenAt = now` even when `is_new_device` is false. `device_age_days` takes its default of 0 and the issue doesn't set a history for it.
- A run is reproducible under the same clock hour. `is_night` and `hour_of_day` come from `occurredAt` where the profile doesn't set them, as intake reads it, so re-running ATO or ORIGINATION at a different hour could change a verdict on `NIGHT_TRANSFER`.
- `submitForApproval` accepts a version with 0 evaluated events (flagged by intake as prototype-only). The issue's criterion relies on it, and `model.md` §6 is stricter for the real service.
- `evaluate` is public and unguarded, as intake reads it. Only `simulateOne` calls it in the app, and it needs no permission of its own.
