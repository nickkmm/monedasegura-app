# Case row, rule row, condition row and table header widgets

> Issue #16: Build the case row, rule row and condition row widgets

## Summary
- Four presentation-only shared widgets go into `lib/widgets/`: `CaseRow`, `RuleRow`, `ConditionRow` and `TableHeaderRow` (with `TableHeaderCell`). Each is exported from `widgets.dart`.
- They reuse `ScoreBar`, `VerdictBadge`, `RuleStatusBadge`, the domain models, `labels.dart`, `format.dart` and the `lib/theme/` tokens. Nothing is re-implemented.
- Each widget gets widget tests under `test/widgets/` against `MockSeed.build(DateTime(2026,10,25,9,45))`. The tests cover issue criteria 1 to 5.
- No screens, data-model, contract or doc changes. Intake accepted the issue as written.

## Context
- **Shared widgets** live in `lib/widgets/`, one public widget per file, exported alphabetically from `lib/widgets/widgets.dart`. They are pure presentation: parameters in, callbacks out, never `AppScope`/`AppStore` (AGENTS.md, "Shared widgets"). Each class has a doc comment describing its parameters, as in `lib/widgets/score_bar.dart` and `lib/widgets/app_text_field.dart`.
- **Widgets to reuse:**
  - `ScoreBar({required double? score})` in `lib/widgets/score_bar.dart` shows `formatScore`, which gives "0,67", or "—" when the score is null.
  - `VerdictBadge({required Verdict verdict})` in `lib/widgets/verdict_badge.dart` shows "En revisión" or "Bloqueada".
  - `RuleStatusBadge({required RuleStatus status})` in `lib/widgets/rule_status_badge.dart` shows "Pendiente" or "Borrador".
- **Hover pattern:** `lib/widgets/app_button.dart`, `option_card.dart` and `app_tab.dart` use a `MouseRegion` with local hover state. `test/widgets/app_button_test.dart` (around line 60) shows how to test hover with `tester.createGesture(kind: PointerDeviceKind.mouse)`.
- **Models** (`lib/data/models/`):
  - `CaseView` in `fraud_case.dart` provides `shortId` (e.g. `#B204E7`), `customer.maskedName`, `amount` (an int), `typeLabel`, `score` (nullable), `verdict` and `openedAt`.
  - `RuleView` in `rule.dart` has `rule` (a `Rule` with `code` and `description`) and `latest` (`versions.first`).
  - `RuleVersion` provides `version`, `action`, `status`, `hits7d?`, `backtest?.candidate.precision`, `submittedAt?`, `createdAt` and `createdBy.fullName` (a `UserRef` in `app_user.dart`).
  - `Condition(feature, op, value)` holds a `value` that is a num, bool, String or List. `ConditionOp` has `.symbol` (`≥`, `=`, `en`…).
- **Labels and formatters:**
  - `lib/data/labels.dart` provides `RuleAction.label` ("Revisar" or "Bloquear").
  - `lib/data/format.dart` provides `formatCop`, `formatInt`, `formatDecimal(v, digits: 2)`, `formatAgo` and `formatDayAgo`.
- **Theme** (`lib/theme/`):
  - Colors in `AppColors`:
    - `textPrimary` `#161B26`
    - `textSecondary` `#545B69`
    - `textTertiary` `#8B919D`
    - `accent` `#2B59C3`
    - `bgSurface` `#FFFFFF`
    - `bgHover` `#EEF0F3`
    - `bgSubtle` `#E9EBEF`
    - `borderDefault` `#DFE2E8`
  - Spacing in `AppSpacing`: `sm` 8, `md` 12, `lg` 16, `xl` 24.
  - Radius: `AppRadius.md` 10.
  - Text styles: `AppTextStyles.body`, `bodyStrong`, `caption` and `label`.
  - Icons: `AppIcons.chevronRight`, `AppIcons.close` and `AppIcons.size` (20).
- **Seed data** (`lib/data/mock/mock_seed.dart`, `MockSeed.build(now)` with `.cases` and `.rules`):
  - Cases:
    - `b204e7…`: Andrés P., $ 3.250.000, shopping_net, score 0.67, REVIEW, 4 min old.
    - `7f0b6a…`: a BLOCK transfer.
    - `09f35b…`: no score.
  - Rules:
    - `NIGHT_TRANSFER`: latest v2, PENDING_APPROVAL, REVIEW, hits 61, candidate 41/79, which displays as "0,52". It was submitted today and created by Laura Méndez.
    - `ATO_PASSWORD_RESET`: v1, DRAFT, no hits, no backtest.
- **Test helpers:** `harness()` and `setDesktopView()` in `test/helpers/harness.dart`.
- **Reference code:** the archived implementation is at `git show archive/pr-29-flutter-prototype:lib/widgets/{case_row,rule_row,condition_row}.dart`. It may be adapted, but it uses old imports (`models.dart`, `mock_data.dart`, `tokens.dart`, `MsIcon`) and a different `ConditionRow` API. Those must be replaced with the current data layer and theme.

## Requirements
1. **`lib/widgets/case_row.dart`: `CaseRow`**
   - Constructor: `CaseRow({Key? key, required CaseView caseView, required DateTime now, VoidCallback? onTap})`.
   - Layout: a row 60 px high with 24 px horizontal padding and a 16 px gap. Background `bgSurface`, `bgHover` while hovered. A 1 px bottom border in `borderDefault`.
   - Cells, left to right, exactly as the issue lists them:
     1. `shortId`: width 112, `caption` `textSecondary`.
     2. `customer.maskedName`: width 200, `bodyStrong` `textPrimary`.
     3. `formatCop(amount)`: width 140, `bodyStrong` `textPrimary`.
     4. `typeLabel`: width 150, `body` `textSecondary`.
     5. `ScoreBar(score: caseView.score)` in a 120 px cell, followed by an extra 24 px gap.
     6. `VerdictBadge(verdict: caseView.verdict)`.
     7. Flexible space, then `formatAgo(openedAt, now)`: width 84, right aligned, `caption` `textTertiary`.
     8. A 20 px `AppIcons.chevronRight` icon in `textTertiary`, which turns `textPrimary` on hover.
   - Text cells are single-line and end in an ellipsis when they overflow.
   - When `onTap` is non-null: a click cursor, and tapping calls `onTap`. When it is null: no click cursor and no tap handling.
2. **`lib/widgets/rule_row.dart`: `RuleRow`**
   - Constructor: `RuleRow({Key? key, required RuleView rule, required DateTime now, VoidCallback? onTap})`.
   - Shows `rule.latest`.
   - Layout: 64 px high, 24 px horizontal padding, 16 px gap, a bottom border in `borderDefault`. Hover, cursor and tap behave as in `CaseRow`.
   - Cells:
     1. Width 300: `rule.rule.code` in `bodyStrong` `textPrimary`, above `rule.rule.description` in `caption` `textSecondary`. Both are single-line with an ellipsis.
     2. `v{latest.version}`: width 56, `body` `textSecondary`.
     3. `latest.action.label`: width 96, `body` `textPrimary`.
     4. A 130 px cell holding `RuleStatusBadge(status: latest.status)`, aligned left.
     5. Hits: `formatInt(hits7d)`, or `—` when it is null. Width 90, right aligned, `bodyStrong` `textPrimary`.
     6. Precision: `formatDecimal(latest.backtest!.candidate.precision)`. It shows `—` when there is no backtest or the status is `RETIRED` or `DRAFT`. Width 80, right aligned, `bodyStrong` `textPrimary`.
     7. Flexible space, then `'${formatDayAgo(latest.submittedAt ?? latest.createdAt, now)} · ${latest.createdBy.fullName}'` in `caption` `textTertiary`, with an ellipsis.
     8. A 20 px chevron in `textTertiary`, which turns `textPrimary` on hover.
3. **`lib/widgets/condition_row.dart`: `ConditionRow`**
   - Constructor: `ConditionRow({Key? key, required Condition condition, bool editable = false, List<String> featureNames = const [], ValueChanged<String>? onFeatureChanged, ValueChanged<ConditionOp>? onOpChanged, ValueChanged<String>? onValueChanged, VoidCallback? onRemove})`.
   - Layout: a row with an 8 px gap holding three boxes. Each box is 40 px high, with background `bgSurface`, a 1 px border in `borderDefault`, radius `AppRadius.md` and 12 px horizontal padding. Text uses `body`.
     - Feature box: width 220, text in `accent`.
     - Operator box: width 90, text in `textPrimary`.
     - Value box: `Expanded`, text in `textPrimary`.
   - **Read-only** (`editable == false`): plain `Text` in each box, and no remove icon.
     - Feature box: the feature name.
     - Operator box: `op.symbol`.
     - Value box: the display value:
       - bool: `Sí` or `No`.
       - `num` when the feature is `amount` or `spend_24h`: `formatCop(value.round())`.
       - Other `num`: `formatDecimal` with trailing zeros, and a dangling comma, removed. For example `300` shows "300" and `0.6` shows "0,6".
       - String: shown as is.
       - List: its elements joined with `, `.
   - **Editable** (`editable == true`):
     - Feature box: a dropdown whose items are `featureNames`. The current feature is included even when it is not in the list. Selecting an item calls `onFeatureChanged`.
     - Operator box: a dropdown of `ConditionOp.values`, labeled by `symbol`. Selecting one calls `onOpChanged`.
     - Value box: a borderless `TextField`. Its initial text is the raw value: `true`/`false` for bools, digits without separators for numbers (`2000000`; non-integers use `toString()`), strings as is, lists joined with `, `. Typing calls `onValueChanged`.
     - Then a 20 px `AppIcons.close` icon in `textTertiary` with a click cursor. Tapping it calls `onRemove`.
   - A `null` callback disables that control.
   - Only short-lived visual state may live in the widget: the text controller. The controller re-syncs in `didUpdateWidget` when the condition's raw value changes and differs from the current text.
   - The numeric and value formatting is a private helper inside this file.
4. **`lib/widgets/table_header.dart`: `TableHeaderRow` and `TableHeaderCell`**
   - Constructors: `TableHeaderRow({Key? key, required List<TableHeaderCell> cells})` and `TableHeaderCell({String label = '', double? width, bool flex = false, TextAlign align = TextAlign.left})`.
   - Layout: 40 px high, 24 px horizontal padding, 16 px gap, background `bgSubtle`. Each label uses `AppTextStyles.label` in `textTertiary`.
   - A cell with `width` is a `SizedBox` of that width. A cell with `flex: true` is `Expanded`. Otherwise the cell takes its intrinsic size.
   - `TableHeaderCell` is a plain configuration class that `TableHeaderRow` renders. Both live in this one file.
5. Export `case_row.dart`, `condition_row.dart`, `rule_row.dart` and `table_header.dart` from `lib/widgets/widgets.dart`, keeping alphabetical order.
6. No hex color, font size or icon outside `lib/theme/`: every value comes from the tokens listed in Context. No `AppScope`, `AppStore`, navigation or app data inside these widgets.
7. Every public class and constructor parameter has a doc comment, following the existing widgets.
8. Add tests:
   - `test/widgets/case_row_test.dart`, `rule_row_test.dart`, `condition_row_test.dart` and `table_header_test.dart`.
   - Each uses `setDesktopView()` and `harness()`. The row tests use data from `MockSeed.build(DateTime(2026, 10, 25, 9, 45))`, looked up by case id prefix or rule code.
   - The tests cover the acceptance criteria below.

## Acceptance criteria
1. Rendering `CaseRow` for the seed case whose id starts with `b204e7`, with `now = DateTime(2026,10,25,9,45)`, shows "#B204E7", "Andrés P.", "$ 3.250.000", "Compra en línea", "0,67", "En revisión" and "hace 4 min". Verify with `flutter test test/widgets/case_row_test.dart`.
2. `CaseRow` for case `7f0b6a…` shows "Transferencia" and "Bloqueada", and for case `09f35b…` shows "—". Same test file.
3. Tapping a `CaseRow` with an `onTap` calls it once. Hovering it with a mouse gesture makes the row's background decoration `AppColors.bgHover` (`#EEF0F3`). Same test file.
4. `RuleRow` for `NIGHT_TRANSFER` shows "NIGHT_TRANSFER", "Transferencia de noche ≥ $ 2.000.000", "v2", "Revisar", "Pendiente", "61", "0,52" and "hoy · Laura Méndez". Verify with `flutter test test/widgets/rule_row_test.dart`.
5. `RuleRow` for `ATO_PASSWORD_RESET` shows "Borrador", and `find.text('—')` finds two widgets. Same test file.
6. `ConditionRow(condition: Condition('amount', ConditionOp.gte, 2000000))` shows "amount", "≥" and "$ 2.000.000", and no `AppIcons.close` icon. Verify with `flutter test test/widgets/condition_row_test.dart`.
7. `ConditionRow(condition: Condition('is_night', ConditionOp.eq, true))` shows "Sí". Same test file.
8. With `editable: true`, tapping the `AppIcons.close` icon calls `onRemove`, and entering text in the value field calls `onValueChanged` with that text. Same test file.
9. A `TableHeaderRow` with several cells renders each label, and each label's `Text.style.color` is `AppColors.textTertiary` (`#8B919D`). Verify with `flutter test test/widgets/table_header_test.dart`.
10. `lib/widgets/case_row.dart`, `rule_row.dart`, `condition_row.dart` and `table_header.dart` exist, and `grep -E "case_row|rule_row|condition_row|table_header" lib/widgets/widgets.dart` lists all four.
11. `grep -nE "AppScope|AppStore" lib/widgets/case_row.dart lib/widgets/rule_row.dart lib/widgets/condition_row.dart lib/widgets/table_header.dart` prints nothing.
12. `grep -nE "Color\(0x|fontSize" lib/widgets/case_row.dart lib/widgets/rule_row.dart lib/widgets/condition_row.dart lib/widgets/table_header.dart` prints nothing.

## Out of scope
- Any screen that uses these widgets (dashboard, queue, rules list, rule editor), and pagination, sorting, filtering, the sidebar and the top bar.
- Changing `ScoreBar`, `VerdictBadge`, `RuleStatusBadge`, the models, `labels.dart`, `format.dart`, `mock_seed.dart`, `AppStore` or the theme. Adding new formatters to `format.dart` is also out of scope.
- Parsing or validating the edited condition value back into a typed value. `ConditionRow` only reports the raw string.
- Restoring `lib/data/models.dart`, `mock_data.dart`, `prototype_labels.dart`, `tokens.dart` or `MsIcon` from the archive tag.
- Changes to `factory/checks.sh`, `factory/config.json` or the sibling repos.

## Assumptions
- "`rule.code`" and "`rule.description`" in the issue mean `RuleView.rule.code` and `.description`. That is the only place those fields exist on `RuleView`.
- The number formatting without trailing zeros lives in a private helper in `condition_row.dart`, not in `format.dart`. Nothing else needs it yet, and keeping it private keeps the change small.
- List values display, and seed the text field, as their elements joined with `, `. The issue says "as is", and a comma-separated list is the readable form of that.
- In editable mode, the feature dropdown includes the current feature even when `featureNames` doesn't list it. Without it, a dropdown cannot show a value that is not among its items.
- `amount`/`spend_24h` values are rounded to an int before `formatCop`, because `formatCop` takes an int.
- No AGENTS.md or delivery-doc update is needed. The new widgets follow the conventions those docs already describe.
