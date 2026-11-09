STATUS: READY

# Build: Domain models, Spanish labels, formatters and mock seed

## Summary
- Adds a pure Dart data layer in `lib/data/`: API enums with the RBAC map, immutable models, Spanish labels and formatters without `intl`.
- `MockSeed.build(now)` reproduces the Figma data: 12 cases, 8 rules, 5 models and the dashboard metrics, with no timestamp after `now`.
- `factory/checks.sh` passes, and all 16 acceptance criteria have evidence below.
- Two product decisions from the spec stay open for a person: `NIGHT_TRANSFER` v2's 3 d age, and the `#09F35B` exception.
- Draft PR: https://github.com/nickkmm/monedasegura-app/pull/26

## Changes
- `lib/data/models/enums.dart`: the 15 API enums with `code` and `fromCode`, and `rolePermissions`.
- `lib/data/models/app_user.dart`: `AppUser` and `UserRef`, with no password field.
- `lib/data/models/customer.dart`: `Customer`.
- `lib/data/models/transaction.dart`: `Device`, `Transaction` and `SessionEvent`.
- `lib/data/models/decision.dart`: `RuleHit` and `Decision`.
- `lib/data/models/fraud_case.dart`: `FraudCase` and the `CaseView` read model.
- `lib/data/models/rule.dart`: `ConditionOp`, `Condition`, `ShadowStats`, `BacktestCounts`, `Backtest`, `Rule`, `RuleVersion` (with the three clear flags) and `RuleView`.
- `lib/data/models/feature_definition.dart`: `FeatureDefinition` and the 20-entry `featureCatalog`.
- `lib/data/models/model_version.dart`: `ModelMetrics`, `QualityGate` and `ModelVersion`.
- `lib/data/models/dashboard_metrics.dart`: `HourBucket`, `DashboardAlert` and `DashboardMetrics`.
- `lib/data/models/models.dart`: barrel export.
- `lib/data/labels.dart`: Spanish label getters, `degradedLabel`, `categoryLabel` and `featureLabel`.
- `lib/data/format.dart`: number, date and relative-time formatters.
- `lib/data/mock/mock_seed.dart`: `MockSeed`, with the `demoPassword` constant.
- `test/data/format_test.dart`, `test/data/models_test.dart`, `test/data/labels_test.dart`, `test/data/mock_seed_test.dart`: tests for the criteria below.
- `AGENTS.md`: one "Data layer" bullet under "This repo (monedasegura-app)".

## Acceptance criteria
Test evidence comes from `flutter test test/data/<file>`, run per file. `format_test.dart` had 16 tests, `models_test.dart` 36, `mock_seed_test.dart` 39 and `labels_test.dart` 14, and all passed. Each criterion below names the tests or code I read to confirm that the file asserts it.

1. [x] Formatters: `format_test.dart` passes. Its "numbers", "dates", "formatAgo" and "formatDayAgo" groups assert every listed example, at 4 min, 3 h, 9 d, 70 d, same day and previous day.
2. [x] Formatter edges: `format_test.dart` passes and asserts `2,96 %`, `0,67`, `0,52`, `25 oct`, `02:00` and `09:52:14`. It also asserts `hace 1 min` at 30 s, `hace 1 h` at 60 min, `hace 2 meses` at 60 d, and `ayer` for 23:50 against 00:10.
3. [x] RBAC: `models_test.dart` group "RBAC" passes, covering ADMIN's 10, RISK_LEAD's RULE_APPROVE, ANALYST's two missing permissions, AUDITOR's 4 and the two-role union.
4. [x] User: `models_test.dart` group "AppUser" passes (`VR`, `can` agrees with `permissions`). `grep -ic password lib/data/models/app_user.dart` printed 0.
5. [x] Enums: `models_test.dart` group "enums" passes, with a round trip and an `ArgumentError` for the 15 enums plus `ConditionOp`, and the 7 symbols.
6. [x] Model getters: `models_test.dart` group "model getters" passes, covering 79 and `0,52`, precision 0, `latest`, `active`, `version(n)`, `clearBacktest`, `#B204E7`, and both `typeLabel` values.
7. [x] Feature catalog: `models_test.dart` "has 20 entries, in order" passes. I also compared all 19 descriptions with `features.md` by reading them, and they match.
8. [x] Labels: `labels_test.dart` passes, with one test per enum plus `categoryLabel`, `featureLabel`, `degradedLabel` and the empty DATASET_FRAUD strings.
9. [x] Seed cases: `mock_seed_test.dart` group "cases" passes, covering 9 and 3 cases, `#B204E7`, the two assigned open cases, the two-way links and the short-id prefixes.
10. [x] Seed personal data: `mock_seed_test.dart` group "customers" passes, covering the masked documents, 10 customers, and `Andrés P.` with `mar 2023`, 41 and 0.
11. [x] Seed verdicts: `mock_seed_test.dart` group "verdicts" and the "#B204E7 is the Figma detail screen" test pass. The hit evaluation also holds for `#B204E7`, not only the other cases.
12. [x] Seed rules: `mock_seed_test.dart` group "rules" passes, covering statuses, one ACTIVE at most, catalog features, approvers, backtest sums, and `0,52`, `22 oct` and `08:10` for `NIGHT_TRANSFER` v2.
13. [x] Seed models and metrics: `mock_seed_test.dart` groups "models" and "metrics" pass, covering one ACTIVE, `v5` first, importance sums, v4's failed check, verdict sums, 24 `hourly` entries and 17 runs.
14. [x] No future times: `mock_seed_test.dart` group "time" passes for 09:45 and 00:30, plus two extra clocks (00:00 and 1 Jan 00:01). Two builds give the same ids and times.
15. [x] Pure Dart: `grep -rE "package:flutter|dart:ui" lib/data` found nothing (exit 1). `git diff origin/develop --stat -- pubspec.yaml pubspec.lock analysis_options.yaml` was empty.
16. [x] Docs: `AGENTS.md` has the bullet (`grep -c "Data layer" AGENTS.md` printed 1).

## Validation
- `bash <main checkout>/factory/checks.sh` (`flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, `flutter build web --release`): passed, exit 0, on the final code before committing. The commits changed no content.
- `flutter test test/data/<file>` for each of the 4 files: passed.
- The greps and the `git diff` listed under criteria 4, 15 and 16: as expected.
- `git status --porcelain`: empty after committing and pushing.
- `factory/bin/gate --hook` was not run by hand; the orchestrator runs the real gate.

## Log
### Round 1
An earlier builder stopped before committing, so I resumed from its uncommitted work and checked all of it against the spec, the issue and the API schemas.

- Kept the `AGENTS.md` change, because spec requirement 5 calls for it.
- Added the `// Prototype-only: not in decision-api.yaml.` comment to `Rule.createdAt` and `FraudCase.decisionId`. Neither field is in the API schemas, and requirement 15 says every such field carries the comment, although its list doesn't name these two.
- Added a `formatAgo` assertion at 1 day (`hace 1 d`), because criterion 1 lists the previous day for both relative-time formatters.
- Found no other gaps. Committed in four steps, pushed the branch and opened draft PR #26.

For the human reviewer, unchanged from the spec's assumptions:
- `NIGHT_TRANSFER` v2 is created 3 d ago. That satisfies #22 ("22 oct") but contradicts the `hoy · Laura Méndez` that #16 and #21 expect.
- `#09F35B` keeps a REVIEW verdict that no active rule can produce. A code comment marks it as a known exception to `model.md` §5.
