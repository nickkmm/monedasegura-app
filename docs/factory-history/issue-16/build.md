STATUS: READY

# Build: Case row, rule row, condition row and table header widgets

## Summary
- Adds four presentation-only shared widgets: `CaseRow`, `RuleRow`, `ConditionRow` and `TableHeaderRow` (with `TableHeaderCell`).
- All four are exported from `lib/widgets/widgets.dart` in alphabetical order. They reuse `ScoreBar`, `VerdictBadge`, `RuleStatusBadge`, the models, the labels, the formatters and the theme tokens.
- Each widget has widget tests against `MockSeed.build(DateTime(2026, 10, 25, 9, 45))`. They cover criteria 1 to 9.
- Round 2: the editable feature and operator dropdowns now show a 20 px `AppIcons.chevronDown` in `textTertiary`. This is a new icon in `lib/theme/app_icons.dart`. The remove icon dims to 40 % when `onRemove` is null.
- `factory/checks.sh` passes. Draft PR #41 is open.

## Changes
- `lib/widgets/case_row.dart`: `CaseRow`, a stateful widget that keeps only its hover state. It is a 60 px row with 24 px horizontal padding, 16 px gaps and a `borderDefault` bottom border. The background is `bgSurface`, or `bgHover` while hovered. Cells, left to right: id 112 px, customer 200 px, amount 140 px, type 150 px, `ScoreBar` in a 120 px cell plus an extra 24 px gap, `VerdictBadge`, a Spacer, the age 84 px right-aligned, then the chevron (`textPrimary` on hover). It shows a click cursor and handles taps only when `onTap` is set.
- `lib/widgets/rule_row.dart`: `RuleRow`, a 64 px row for `rule.latest`. Cells: code and description 300 px, `v{n}` 56 px, action label 96 px, `RuleStatusBadge` in a 130 px cell, hits 90 px (`—` when null), precision 80 px. Precision is `—` when there is no backtest or the status is DRAFT or RETIRED. Then an Expanded "day-ago · author" caption with an ellipsis, and the chevron. Hover, cursor and tap work as in `CaseRow`.
- `lib/widgets/condition_row.dart`: `ConditionRow`, three 40 px boxes with an 8 px gap: feature 220 px in `accent`, operator 90 px, value Expanded.
  - Read-only: each box is plain text and there is no remove icon. A private `_displayValue` shows bools as Sí/No, `amount`/`spend_24h` as `formatCop(round)`, other numbers through `formatDecimal` with trailing zeros removed, strings as is and lists joined with ", ".
  - Editable: the feature dropdown includes the current feature even when `featureNames` lacks it. The operator dropdown lists `ConditionOp.values` by symbol. The value is a borderless `TextField` seeded with the raw value from `_rawValue`. A 20 px `AppIcons.close` icon with a click cursor calls `onRemove`.
  - A `null` callback disables its control. The controller re-syncs in `didUpdateWidget` when the raw value changes and differs from the current text.
- `lib/widgets/table_header.dart`: `TableHeaderCell` is a configuration class with label, width, flex and align. `TableHeaderRow` is a 40 px band on `bgSubtle` with 24 px padding and 16 px gaps. Labels use `AppTextStyles.label` in `textTertiary`. A cell with a width becomes a `SizedBox`, a flex cell becomes `Expanded`, and any other cell takes its intrinsic size.
- `lib/theme/app_icons.dart` (round 2): adds `AppIcons.chevronDown` (Lucide `chevronDown`) as the dropdown indicator. It is not a gallery icon, so it stays out of `AppIcons.all`, and the theme test that expects 20 gallery icons is unchanged.
- `lib/widgets/condition_row.dart` (round 2): both dropdowns use the chevron-down icon instead of `SizedBox.shrink()`. The remove icon is wrapped in an `Opacity` of 0.4 when `onRemove` is null.
- `lib/widgets/widgets.dart`: the four new exports, kept alphabetical.
- `test/widgets/case_row_test.dart`, `rule_row_test.dart`, `condition_row_test.dart`, `table_header_test.dart`: the new tests.
  - `rule_row_test.dart` loads the bundled Inter font in `setUpAll`. The default test font draws every glyph as a 12 px square, which made the "Pendiente" badge overflow its 130 px cell by 4 px in tests only.

## Acceptance criteria
1. [x] CaseRow b204e7 shows "#B204E7", "Andrés P.", "$ 3.250.000", "Compra en línea", "0,67", "En revisión" and "hace 4 min". Evidence: `flutter test test/widgets/case_row_test.dart`, test "shows the cells of a review case", passed.
2. [x] 7f0b6a shows "Transferencia" and "Bloqueada", and 09f35b shows "—". Evidence: test "shows a blocked transfer and a case without score", passed.
3. [x] A tap calls `onTap` once, and a mouse hover makes the row decoration color `AppColors.bgHover`. Evidence: tests "tapping calls onTap once" and "hovering highlights the row", passed. A further test checks that a row without `onTap` has no click cursor.
4. [x] RuleRow NIGHT_TRANSFER shows "NIGHT_TRANSFER", "Transferencia de noche ≥ $ 2.000.000", "v2", "Revisar", "Pendiente", "61", "0,52" and "hoy · Laura Méndez". Evidence: `flutter test test/widgets/rule_row_test.dart`, passed.
5. [x] ATO_PASSWORD_RESET shows "Borrador", and `find.text('—')` finds 2 widgets. Evidence: same file, passed.
6. [x] `Condition('amount', gte, 2000000)` shows "amount", "≥" and "$ 2.000.000", with no close icon. Evidence: `flutter test test/widgets/condition_row_test.dart`, passed.
7. [x] `Condition('is_night', eq, true)` shows "Sí". Evidence: same file, passed. The same test also checks No, 300, 0,6 and list values.
8. [x] In editable mode, tapping the close icon calls `onRemove`, and `enterText` calls `onValueChanged` with that text. Evidence: same file, passed. The same test checks that the field starts as "2000000", and a separate test checks the feature dropdown selection.
9. [x] Each TableHeaderRow label has `style.color == AppColors.textTertiary`. Evidence: `flutter test test/widgets/table_header_test.dart`, passed. The test also checks that a fixed-width cell measures 112 px.
10. [x] All four files exist, and `grep -E "case_row|rule_row|condition_row|table_header" lib/widgets/widgets.dart` lists all four exports.
11. [x] `grep -nE "AppScope|AppStore"` on the four files prints nothing.
12. [x] `grep -nE "Color\(0x|fontSize"` on the four files prints nothing.

## Validation
- Round 2: `bash /home/mrjj/ms/monedasegura-app/factory/checks.sh` exits 0. `dart format` changed 0 files, `flutter analyze` found no issues, `flutter test` passed all 268 tests, and `flutter build web --release` built.
- Round 2: the new test "editable dropdowns show a chevron" in `test/widgets/condition_row_test.dart` passes. It finds two `AppIcons.chevronDown` icons, both 20 px and `textTertiary`. The read-only test checks that there are none.
- The criteria 10 to 12 greps give the results listed above.

## Log
### Round 1
- Ran `flutter pub get` and implemented the four widgets, the exports and the tests from the spec. The archived `pr-29` widgets were the starting point, ported to the current data layer and theme.
- The first test run failed one rule_row test: the "Pendiente" badge overflowed by 4 px. This only happens with the test font, so the fix was in the test: it now loads Inter. The widget layout still follows the spec.
- Ran checks.sh (it passed), committed, pushed and opened draft PR #41.

### Round 2
- review-ui finding 1 (CHANGES): the editable dropdowns had no indicator, so they looked read-only. Fixed: I added `AppIcons.chevronDown` to `lib/theme/app_icons.dart` and use it as the `icon` of both dropdowns, at `AppIcons.size` in `textTertiary`. A test covers it. I left `AppIcons.all` alone, because it lists the 20 gallery icons and `theme_test.dart` asserts that count.
- review-ux note (optional): the remove icon kept full opacity when `onRemove` was null. Fixed: it now dims to 0.4, as `AppButton` does when disabled.
- Other notes were not acted on. They are marked non-blocking and belong to the host screens or the design owners: horizontal scroll at phone width, keyboard focus, the tap target and tooltip for the remove icon, `textTertiary` contrast, and NaN values in `_rawValue`.
- checks.sh passes. Pushed commit f03e1f6 to PR #41.
