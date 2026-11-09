# Domain models, Spanish labels, formatters and mock seed

> Issue #11: Add the domain models, Spanish labels, formatters and mock seed data

## Summary
- Specifies a new pure Dart data layer under `lib/data/`: enums and RBAC map, immutable models, labels, formatters, `MockSeed`, and tests in `test/data/`.
- The issue's Specification stays the source of every value; this spec settles what it leaves open, using intake's binding readings.
- I checked the later issues (#12, #15, #16, #20 to #22) so the API here fits them: API-code enum constants, a positional `Condition`, `cases` as `List<CaseView>`, and a `copyWith` that can clear fields.
- Needs a human look: `NIGHT_TRANSFER` v2 created 3 d ago satisfies #22 ("22 oct") but contradicts the "hoy · Laura Méndez" that #16 and #21 expect.
- Also open from intake: `#09F35B` keeps a REVIEW verdict that no active rule can produce, marked as a known exception.

## Context
- The repo is a skeleton: `lib/main.dart`, `lib/login_screen.dart` and `test/widget_test.dart`. `lib/data/` does not exist, so this job only adds files, plus one line in `AGENTS.md`. There is no pattern to reuse yet; this layer sets it.
- `pubspec.yaml` has no `intl` or `meta` dependency and none may be added. `flutter_test` is the test runner.
- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, which enables `constant_identifier_names`. `flutter analyze`, run by `factory/checks.sh`, exits non-zero on info-level lints, so upper-case enum constants need a local ignore.
- Shared documents, relative to the main checkout: `../monedasegura-infra/docs/model.md` (§2 tables, §4 RBAC, §5 verdict, §6 lifecycle, §7 cases, §8 quality gate), `../monedasegura-infra/docs/api/decision-api.yaml` (`components/schemas`, line 823 on), `../monedasegura-infra/docs/features.md` ("Catalog (v1)").
- Later consumers fix parts of the shape:
  - #12 `AppStore` builds `MockSeed.build(clock())`, keeps mutable copies of the seed lists and returns `CaseView`s. It calls `CaseLabel.CONFIRMED_FRAUD` and `PermissionCode.SIMULATOR_RUN`.
  - #15 uses `Condition('is_night', ConditionOp.eq, true)` and `RuleAction.REVIEW`, and clears `backtest`, `shadowStats` and `submittedAt` on a version.
  - #16 passes `CaseView` to `CaseRow` and calls `formatDecimal(precision)` without `digits`.
  - #22 calls `formatPercent(x, digits: 1)`.

## Requirements

### General
1. Build everything in the issue's "Specification" section (Files, Enums, Models, Spanish labels, Formatters, `MockSeed`), using its names and values exactly, including accents and symbols. That section is binding wherever this spec doesn't settle a point differently.
2. Create exactly the issue's files: `lib/data/models/{enums,app_user,customer,transaction,decision,fraud_case,rule,feature_definition,model_version,dashboard_metrics,models}.dart`, `lib/data/labels.dart`, `lib/data/format.dart`, `lib/data/mock/mock_seed.dart`, and tests under `test/data/`. `models.dart` exports every other model file.
3. Nothing under `lib/data/` imports `package:flutter` or `dart:ui`. No new package in `pubspec.yaml`. No `print` or logging.
4. Code, identifiers, comments and tests are in English. Only the label, hint, description and seed copy strings the issue gives are in Spanish.
5. Add one bullet under "This repo (monedasegura-app)" in `AGENTS.md`: `lib/data/models/` holds the domain models, `lib/data/labels.dart` the Spanish labels, `lib/data/format.dart` the formatters and `lib/data/mock/mock_seed.dart` the mock data; screens reuse them rather than re-translating or re-formatting.

### Enums (`enums.dart`)
6. Enum constants are the API codes verbatim (`Verdict.BLOCK`, `RuleStatus.PENDING_APPROVAL`, `PermissionCode.SIMULATOR_RUN`), because later issues reference them that way. `enums.dart` starts with `// ignore_for_file: constant_identifier_names`; do not change `analysis_options.yaml`.
7. Each enum, and `ConditionOp` in `rule.dart`, has `final String code` and `static X fromCode(String)`. `fromCode` throws `ArgumentError` on an unknown code.
8. `ConditionOp` keeps the issue's lower-case constants (`gt`, `gte`, `lt`, `lte`, `eq`, `neq`, `inList`) and adds `symbol`.
9. `rolePermissions` matches `model.md` §4 exactly.

### Models
10. All fields are `final`, with `const` constructors where possible and named parameters, except `Condition`, which is positional: `const Condition(this.feature, this.op, this.value)`.
11. Provide `copyWith` on `FraudCase`, `CaseView`, `Rule`, `RuleVersion`, `RuleView`, `ModelVersion` and `DashboardMetrics`. `RuleVersion.copyWith` also takes `bool clearBacktest`, `clearShadowStats` and `clearSubmittedAt`, each defaulting to false, because #15 must set those fields back to null.
12. `AppUser` has no password field. `initials` uses the first letter of the first two whitespace-separated words, upper case; a one-word name gives one letter.
13. `Transaction.category` and `Transaction.counterparty` are `String?` (optional in the API; the seed's TRANSFER rows have no category). `CaseView.typeLabel` returns `"Transferencia"` for TRANSFER, otherwise `categoryLabel(category ?? '')`.
14. `RuleView.latest` is `versions.first`. `active` is the ACTIVE version or null. `version(int n)` returns `RuleVersion?`, null when absent.
15. Every field that isn't in `decision-api.yaml` carries the comment `// Prototype-only: not in decision-api.yaml.`: the ones the issue marks prototype-only, `HourBucket`, and `CaseView.device`.
16. `DashboardMetrics.alerts` is `List<DashboardAlert>`, with `DashboardAlert {type (String), message, at}` following the API schema, defined in `dashboard_metrics.dart`. The seed's list is empty.
17. `featureCatalog` has 20 entries: the 19 of features.md in order, with each `description` copied verbatim from its Definition column, then `score` (number, `Model output 0-1, usable in rules`). `category` gets `allowedValues` equal to the 14 category codes that `categoryLabel` lists.

### Labels (`labels.dart`)
18. Provide the getters the issue lists, for `Verdict`, `RuleStatus`, `RuleAction`, `CaseLabel` (`label`, `hint`), `ModelStatus`, `ModelTrigger`, `TransactionType`, `RoleCode`, `Scenario` (`label`, `hint`, `description`) and `DeviceOs`, plus `degradedLabel`, `categoryLabel` and `featureLabel`.
19. `Scenario.DATASET_FRAUD` returns `''` for `hint` and `description`.
20. Do not invent Spanish strings for enums the issue gives none for (`CaseStatus`, `DecisionKind`, `TransactionSource`, `SessionEventType`, `PermissionCode`).

### Formatters (`format.dart`)
21. `formatPercent(double ratio, {int digits = 2})` takes a ratio and multiplies by 100: `0.0296` gives `2,96 %` and `37/12480` gives `0,30 %`.
22. `formatDecimal(double v, {int digits = 2})` rounds with `toStringAsFixed`. `formatScore` uses 2 digits.
23. `formatAgo(t, now)` uses the elapsed time. Under 1 min, including a `t` after `now`: `hace 1 min`. Under 60 min: `hace N min`. Under 24 h: `hace N h`. Under 60 d: `hace N d`. Otherwise: `hace M meses`, with `M = days ~/ 30`.
24. `formatDayAgo(t, now)` compares calendar dates only, so a DST change or the hour of day can't shift the result. A `t` on or after today gives `hoy`; the previous day gives `ayer`; under 60 d gives `hace N d`; otherwise `hace M meses`, with `M` as above.
25. Date and time formatters use the `DateTime`'s own fields with no time zone conversion, and pad hours, minutes and seconds to 2 digits.

### `MockSeed`
26. `MockSeed.build(now)` returns an instance exposing `users`, `customers`, `devices`, `transactions`, `decisions`, `cases` (`List<CaseView>`), `rules` (`List<RuleView>`), `models` (`List<ModelVersion>`, newest first: v5, v4, v3, v2, v1), `metrics` (`DashboardMetrics`) and `simulationRunCount`. List orders follow the issue's tables. `demoPassword` is a static const with a comment saying it is a prototype value, not a real credential.
27. Each `CaseView` holds the same objects found in the other seed lists. `decision.caseId == fraudCase.id` and `fraudCase.decisionId == decision.id`. There are exactly 12 transactions, 12 decisions and 12 cases; the seed adds no APPROVE decisions.
28. All ids are fixed lower-case UUID strings; each case id starts with its short id in lower case. `build` is deterministic: no `Random`, no `DateTime.now()`.
29. **Time.** Everything is relative to `now`, except customer `createdAt`, which is fixed.
    - Clock-anchored "today" values (v5 trained 02:00, `submittedAt` 08:10, the `#B204E7` device first seen 09:30, and any "today" `createdAt` or `runAt`) are computed as that clock time on `now`'s date, clamped to `now` if later. For the device, clamp to its transaction's `occurredAt`.
    - No seed timestamp is ever after `now`, for any `now`.
    - At 09:45 the clamps don't apply, so the values read exactly as in the issue.
30. **`#B204E7`** has exactly the four rule hits the issue lists, in that order, with its listed features.
31. **Other cases** have the same six feature keys, `features['amount']` equal to the transaction amount, and one hit per ACTIVE and SHADOW version, in this order: SCORE_BLOCK v2, SCORE_REVIEW v4, HIGH_AMOUNT_NEW_DEVICE v3, VELOCITY_1H v1, NIGHT_TRANSFER v1, FAR_FROM_HOME v1 (`shadow = true`).
    - Each hit's `matched` is the true result of its version's conditions over the features and score. A rule on `score` never matches when the score is null.
    - The verdict is the most severe matched non-shadow action, so REVIEW cases need `tx_count_1h <= 5`.
    - Each hit's `ruleId`, `version` and `action` match that version in `rules`.
32. **`#09F35B`** keeps the issue's row: 2.180.000, degraded, null score, modelVersion null, REVIEW. No non-shadow hit matches. A code comment marks the row as a known exception to `model.md` §5.
33. **Transactions.** `source` is SIMULATOR. `scenario` is ATO for TRANSFER rows, CARD_FRAUD for `shopping_net` rows and NORMAL otherwise. TRANSFER counterparties are masked accounts (`****` plus 4 digits), never a person's name. Every `deviceId` exists in `devices`.
34. **Rule versions.**
    - `NIGHT_TRANSFER` v2 uses the values in its own paragraph: `createdAt = now - 3 d`, `shadowStats.since = now - 5 d`, `submittedAt` today 08:10.
    - Every ACTIVE or RETIRED version has `approvedBy` and `approvedAt`, with the approver different from the creator and holding `RULE_APPROVE`; use Laura Méndez and Diego Salazar. `NIGHT_TRANSFER` v1 is created by Laura Méndez and approved by Diego Salazar. DRAFT, SHADOW and PENDING_APPROVAL versions have no approver.
    - Older versions have strictly earlier `createdAt`, reuse the same conditions and action unless the issue says otherwise, and have `hits7d` null. `Rule.createdAt` is no later than its oldest version.
35. **Backtests.** Every ACTIVE version, FAR_FROM_HOME v1 and NIGHT_TRANSFER v2 has a backtest with `casesEvaluated` 1920 and counts summing to 1920, using the TP/FP from the issue (NIGHT_TRANSFER v1: 32/9). `active` is null except on NIGHT_TRANSFER v2. `systemRecallBefore` and `systemRecallAfter` are set only on NIGHT_TRANSFER v2. RETIRED versions, and ATO_PASSWORD_RESET v1 (DRAFT), have none.
36. **Models.**
    - Shorthand triples read prAuc/recall/precision.
    - v4's `qualityGate` has `passed = false`, with MIN_NEW_LABELS and PR_AUC_NOT_WORSE passing and RECALL_NOT_WORSE failing. v5's gate passes all three. v3, v2 and v1 have a null gate.
    - v2 and v1 are SCHEDULED with `trainedBy` null. They and v4 reuse v5's `featureImportance`, as does v3.
    - `trainingRows` and `fraudsSeen` the issue doesn't give increase with `trainedAt` and stay below v5's (182400 and 1940).
37. **Metrics.** Use the values as given, including `hourly`, which doesn't add up to `verdicts`. No test may require that sum.

### Tests
38. Add `test/data/format_test.dart`, `test/data/models_test.dart`, `test/data/mock_seed_test.dart` and `test/data/labels_test.dart`, covering the criteria below.

## Acceptance criteria
Run the tests with `flutter test test/data/<file>`.

1. **Formatters.** `format_test.dart` passes and asserts every example of the issue's acceptance criterion 1: `formatCop(3250000) == '\$ 3.250.000'`, `formatInt(12480) == '12.480'`, `formatScore(0.674) == '0,67'`, `formatScore(null) == '—'`, `formatPercent(37/12480, digits: 2) == '0,30 %'`, `formatDateTime(DateTime(2026,10,25,9,41)) == '25 oct 2026, 09:41'`, `formatMonthYear(DateTime(2023,3,14)) == 'mar 2023'`, plus `formatAgo` and `formatDayAgo` at 4 min, 3 h, 9 d, 70 d, same day and previous day.
2. **Formatter edges.** `format_test.dart` also asserts: `formatPercent(0.0296, digits: 2) == '2,96 %'`; `formatDecimal(0.674, digits: 2) == '0,67'`; `formatDecimal(0.5189) == '0,52'`; `formatDayMonth` gives `25 oct`; `formatHm` gives `02:00`; `formatHms` gives `09:52:14`; `formatAgo` gives `hace 1 min` at 30 s, `hace 1 h` at exactly 60 min, and `hace 2 meses` at 60 d; `formatDayAgo` gives `ayer` for 23:50 yesterday against 00:10 today.
3. **RBAC.** `models_test.dart` asserts: ADMIN has all 10 permissions; RISK_LEAD has RULE_APPROVE; ANALYST lacks RULE_WRITE and SIMULATOR_RUN; AUDITOR has exactly 4; a user with two roles gets the union.
4. **User.** `models_test.dart` asserts `initials` of "Valentina Ríos" is "VR" and `can` agrees with `permissions`. `lib/data/models/app_user.dart` contains no match for `password` (case-insensitive).
5. **Enums.** `models_test.dart` asserts, for all 15 enums plus `ConditionOp`, that `fromCode(x.code) == x` for every value and that an unknown code throws `ArgumentError`. It also asserts the `ConditionOp` symbols `>`, `≥`, `<`, `≤`, `=`, `≠`, `en`.
6. **Model getters.** `models_test.dart` asserts: `BacktestCounts` with TP 41 and FP 38 has `matches` 79 and `formatDecimal(precision) == '0,52'`; precision is 0 with no matches; `RuleView.latest`, `active` and `version(n)` behave as in requirement 14; `RuleVersion.copyWith(clearBacktest: true)` nulls the backtest; `CaseView.shortId` of the `b204e7…` case is `#B204E7`; `typeLabel` is `Transferencia` for `#7F0B6A` and `Compra en línea` for `#B204E7`.
7. **Feature catalog.** A test asserts `featureCatalog` has 20 entries, with `amount` first, `account_age_days` 19th and `score` last.
8. **Labels.** `labels_test.dart` has one test per enum in requirement 18, asserting every string from the issue, plus `categoryLabel` (a known code and `anything` giving `Sin categoría`) and `featureLabel` (a known name and an unknown one returned as is), `degradedLabel`, and `''` for the DATASET_FRAUD hint and description.
9. **Seed cases.** With `MockSeed.build(DateTime(2026,10,25,9,45))`, `mock_seed_test.dart` asserts: 9 cases OPEN or IN_REVIEW and 3 RESOLVED; `#B204E7` has verdict REVIEW, score 0.67 and customer `Andrés P.`; `#3A91C2` and `#C66A2F` are the only assigned open cases; every REVIEW or BLOCK decision has exactly one case, linked both ways; every case id starts with its lower-case short id.
10. **Seed personal data.** Every `maskedDocument` matches `^\*{4}\d{4}$`; there are 10 customers; `Andrés P.` has `formatMonthYear(createdAt) == 'mar 2023'`, 41 transactions and 0 frauds.
11. **Seed verdicts.** For every decision except `#09F35B`, the verdict equals the most severe matched non-shadow hit. For every decision except `#B204E7`, each hit's `matched` equals the evaluation of that version's conditions, done by a helper in the test. `#B204E7` has exactly the four listed hits. `#09F35B` is exempted by name and has no matched non-shadow hit.
12. **Seed rules.** 8 rules with latest statuses as in the issue's table; at most one ACTIVE version per rule; every condition feature is in `featureCatalog`; every ACTIVE or RETIRED version has an approver different from its creator, and that approver can `RULE_APPROVE`; every backtest's counts sum to `casesEvaluated`; `NIGHT_TRANSFER` v2 has `precision` rounding to 0.52, `formatDayMonth(createdAt) == '22 oct'` and `formatHm(submittedAt) == '08:10'`.
13. **Seed models and metrics.** Exactly one model is ACTIVE; `v5` is first; `featureImportance` of every model sums to 1 (±0.001); v4's gate failed only on RECALL_NOT_WORSE; verdict counts sum to `decisions`; `hourly` has 24 entries; `simulationRunCount` is 17.
14. **No future times.** For `now` values `DateTime(2026,10,25,9,45)` and `DateTime(2026,10,25,0,30)`, a test asserts that no timestamp in the seed is after `now` (transactions, decisions, cases, devices, rule versions, shadow stats, backtests, models). Two builds with the same `now` give the same ids.
15. **Pure Dart.** `grep -rE "package:flutter|dart:ui" lib/data` finds nothing, and `git diff origin/develop -- pubspec.yaml pubspec.lock analysis_options.yaml` is empty.
16. **Docs.** `AGENTS.md` has the `lib/data/` bullet from requirement 5.

## Out of scope
- `AppStore`, sign-in and the password check, and any mutation logic (#12, #15). This job only adds the `demoPassword` constant.
- Widgets, screens, `lib/theme/`, routing, and changes to `lib/main.dart` or `lib/login_screen.dart`.
- JSON (de)serialization, HTTP, persistence.
- A `sessionEvents` list in the seed: the issue defines the `SessionEvent` model but not the list.
- Spanish labels the issue doesn't give.
- `==`, `hashCode`, or validation in model constructors.
- `activeModel` on `DashboardMetrics`, and `recentTransactions` or `recentSessionEvents` on `CaseView`: the issue's model shapes leave them out.
- Changing `monedasegura-infra`, or issues #16 and #21.

## Assumptions
1. **`NIGHT_TRANSFER` v2 `createdAt` is 3 d ago (product decision to confirm).** Intake's reading is binding and #22 expects `22 oct`, but #16 AC2 and #21 expect `hoy · Laura Méndez` from `latest.createdAt`. One side must change: those two issues should expect `hace 3 d · Laura Méndez`, or `RuleRow` should show another date.
2. **`#09F35B` stays an exception to `model.md` §5 (product decision to confirm).** Intake kept the row and asked @nickkmm to check it. No active rule can produce its REVIEW verdict.
3. `NIGHT_TRANSFER` v2's shadow start stays earlier than its creation, as written, per intake.
4. Enum constants use the API codes rather than Dart's lower-camel style: "enum values keep the API codes", and #12 and #15 use them. The lint is silenced in that one file.
5. `cases` is `List<CaseView>`: `shortId` only exists there, the issue's criterion 3 reads verdict and customer from a case, and #16 builds `CaseRow` from seed data.
6. Clamping "today" times to `now` is the simplest way to meet intake's "must stay past": the seed needs no documented limit, and the value still falls on today's date.
7. Enums without Spanish strings in the issue get no `label`, although the issue says "each enum": it requires its exact strings, and no later issue I read asks for those labels.
8. `ACTIVE` and `RETIRED` versions both need an approver, extending intake's rule to `RETIRED`, because `model.md` §6 only reaches `RETIRED` through `ACTIVE`.
9. A later `t` than `now` reads as the most recent value (`hace 1 min`, `hoy`), and months are `days ~/ 30`: the issue gives only the `hace 2 meses` example.
10. `is_night` in seed features is a fixed value, not derived from `occurredAt`: times move with `now`, and the issue fixes `is_night` false for `#B204E7`.
11. `category` gets `allowedValues` from `categoryLabel`'s 14 codes: the API describes this field for `category`, and features.md doesn't list values.
12. Seed values the issue leaves open (scenario mapping, masked counterparties, v1 to v4 feature importance, v5's passing gate, older training counts, SCHEDULED for v2 and v1) are the plausible choices stated above; no screen depends on them beyond what the issue gives.
