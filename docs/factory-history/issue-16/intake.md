DECISION: ACCEPT
RISK: medium
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: four presentation-only shared widgets (`CaseRow`, `RuleRow`, `ConditionRow`, `TableHeaderRow`), each with widget tests.
- Everything they build on is already in `develop`: `ScoreBar`, `VerdictBadge`, `RuleStatusBadge`, `CaseView`, `RuleView`, `Condition`/`ConditionOp`, the formatters, `AppIcons.chevronRight`/`close` and the mock seed records the tests use.
- No contract, data model or feature catalog change is needed. The widgets only render models that already exist.
- Rated medium risk because it adds several files and `ConditionRow` has an editable mode with two dropdowns and a text input. There is nothing sensitive in it.

## Scope
Build these four shared widgets in `lib/widgets/`, one public widget per file, each exported from `lib/widgets/widgets.dart`. They follow the issue's sizes, colors, text styles and Spanish strings exactly, and take every value from `lib/theme/`:

- **`CaseRow`** (`caseView`, `now`, optional `onTap`): one case on one line. Columns in order: short id, masked name, COP amount, type label, `ScoreBar` (it shows "—" when there is no score), `VerdictBadge`, flexible space, relative time ("hace 4 min") and a chevron. On hover the background turns `#EEF0F3` and the chevron darkens. It shows a click cursor and calls `onTap` only when `onTap` is set. Text that doesn't fit ends in an ellipsis.
- **`RuleRow`** (`rule`, `now`, optional `onTap`): the rule's **latest** version. Columns: code over description, `v{n}`, action label, `RuleStatusBadge`, 7-day hits (or "—"), backtest candidate precision (or "—" when there is no backtest or the status is RETIRED/DRAFT), flexible space, then "`formatDayAgo(submittedAt ?? createdAt)` · creator's full name", then a chevron. Hover and tap work as in `CaseRow`.
- **`ConditionRow`** (`condition`, `editable`, `featureNames`, plus the `onFeatureChanged`, `onOpChanged`, `onValueChanged` and `onRemove` callbacks):
  - Read-only: three boxes showing the feature name, `op.symbol` and the display value. Booleans show "Sí"/"No". `amount` and `spend_24h` use COP format. Other numbers use `formatDecimal` without trailing zeros. Strings and lists are shown as they are.
  - Editable: a feature dropdown (`featureNames`), an operator dropdown (`ConditionOp.values`, shown by symbol), a value text input seeded with the raw value, and a remove icon. Each change calls its callback.
- **`TableHeaderRow`** / **`TableHeaderCell`**: a 40 px header strip whose cells have a label, an optional fixed width or flex, and an alignment. Labels use `AppTextStyles.label` in `#8B919D`.

Tests go under `test/widgets/`, use `setDesktopView()` and `MockSeed.build(DateTime(2026,10,25,9,45))`, and cover acceptance criteria 1 to 5 exactly as the issue lists them. That includes the `grep` check that none of the new files mention `AppScope` or `AppStore`.

The issue leaves out the screens that use these widgets, as well as pagination, sorting, filtering, the sidebar and the top bar. The archived PR #29 code may be reused only where it matches this issue and the factory's data layer.

## Why
Issues #13, #14 and #33 have landed the parts this work needs. `lib/widgets/score_bar.dart`, `verdict_badge.dart` and `rule_status_badge.dart` exist. `CaseView` (`lib/data/models/fraud_case.dart`) already provides `shortId`, `typeLabel` and a nullable `score`. `RuleView.latest` and `RuleVersion.submittedAt`/`hits7d`/`backtest` are in `lib/data/models/rule.dart`. The seed in `lib/data/mock/mock_seed.dart` contains cases b204e7, 7f0b6a and 09f35b and the rules NIGHT_TRANSFER and ATO_PASSWORD_RESET. The issue is fully specified, presentation-only, and fits in one reviewable PR.

## Questions
