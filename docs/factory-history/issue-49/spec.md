# Show only the date in the rules table at narrow widths

> Issue #49: Show only the date in the rules table at narrow widths

## Summary
- The "Actualizada" column has only 42 px at 1280, so the plan is date only below a switch point, date and author above it.
- Commit `8acc0da` applies cleanly to `origin/develop` and is reused, with two measured corrections.
- Its 84 px date column is too narrow: "hace 10 meses" needs 84.06 px. The spec requires 88 px.
- Its 1418 px switch point is too low: date plus author can need up to 186.9 px against 180 px there. The spec moves it to 1425 px.
- `RuleRow` has no other user in `lib/`, and its default output stays the same. The duplicate Inter setup in `test/app/navigation_test.dart` also goes.

## Context
All of this was checked on `origin/develop` at `f55ff7f`.

**The widget and its users**
- `lib/widgets/rule_row.dart` (`RuleRow`) lays out the row with a fixed 300 px "Regla" column, fixed columns for the rest, and an `Expanded` "Actualizada" showing `'<date> · <author>'`. The date comes from `formatDayAgo` in `lib/data/format.dart`.
- `lib/screens/rules/rules_page.dart` (`_RulesTable`) is the only user of `RuleRow` in `lib/`. It builds the matching header with `TableHeaderRow` and `TableHeaderCell` from `lib/widgets/table_header.dart`, which already support fixed `width` and `flex` cells, so no change is needed there.
- `docs/` and `AGENTS.md` don't mention `RuleRow` outside `docs/factory-history/`, so no doc changes are needed.

**The layout numbers**
- The table card is the window width minus 304 px (`lib/widgets/app_shell.dart` has a 1280 px minimum). So the card is 976 px at 1280.
- The row's inner width is the card minus 50 px (1 px borders and 24 px padding each side).
- In full mode, "Regla" and the other fixed columns plus the gaps take 884 px, which leaves "Actualizada" 42 px at 1280, 180 px at 1418 and 202 px at 1440.

**Existing work: commit `8acc0da`**
It is on `factory/004-build-the-rules-list` and changes only four files: `rules_page.dart`, `rule_row.dart`, `test/screens/rules_test.dart` and `test/widgets/rule_row_test.dart`. It adds a `compact` flag to `RuleRow`, with `RuleRow.compactDateWidth` for the date column, and a `LayoutBuilder` in `_RulesTable` that chooses the mode from the card width. It passes `git apply --check` on `origin/develop`.

**Measurements**
These were taken with Inter loaded, using the row's caption style, on a scratch copy of `origin/develop` with the commit applied.

| Value | Width |
|---|---|
| "hace 2 meses" | 78.93 px |
| "hace 10 meses" (widest up to 11 months) | 84.06 px |
| "hace 11 meses" | 81.37 px |
| "hace 44 meses" (widest of every "hace N d" and every "hace N meses" up to N = 99) | 87.11 px |
| " · Laura Cárdenas" (widest author suffix of the six seed users) | 99.79 px |
| "hace 11 meses · Laura Cárdenas" | 181.15 px |
| "hace 44 meses · Laura Cárdenas" (computed: 87.11 + 99.79) | 186.90 px |
| "Actualizada" header (`AppTextStyles.label`) | 62.66 px |
| Widest seed rule description at 1280, on `HIGH_AMOUNT_NEW_DEVICE` | 232.89 px |
| Widest seed rule code at 1280, also `HIGH_AMOUNT_NEW_DEVICE` | 202.40 px |

**What the numbers mean for the commit**
- `formatDayAgo` has no upper limit in months, so "hace 12 meses" and beyond are real outputs. With 84 px, "hace 10 meses" loses a character.
- The intake's "hace 11 meses · Laura Cárdenas" is not the widest case. It already fails at 1418 (180 px) and at 1419 (181 px against 181.15 px).
- Date only: an 88 px column fits every value up to 99 months. At 1280, "Regla" then gets 254 px, which still fits every seed code and description.
- Date and author: 186.90 px needs a 187 px column, so 884 + 187 + 50 = a 1121 px card, which is a 1425 px window.
- Both corrections were tried on the scratch copy: both widest values rendered untruncated, and `rules_test.dart`, `rule_row_test.dart` and `navigation_test.dart` passed with the width cases moved to 1424 and 1425.

**Test helpers to reuse**
- `loadInterFont` and `setDesktopView` in `test/helpers/harness.dart`.
- `pumpApp` and `kTestNow` in `test/helpers/pump_app.dart`.

**The test cleanup**
`test/app/navigation_test.dart` calls `setUpAll` twice for the font: one inline `FontLoader('Inter')` block and one `setUpAll(loadInterFont)`.

## Requirements
1. Bring the change in `8acc0da` into this branch, for example with `git cherry-pick 8acc0da`, then apply requirements 2 and 3. Take nothing else from `factory/004-build-the-rules-list`, including its job record.
2. `RuleRow.compactDateWidth` is 88.
3. `_RulesTable` uses date-only mode when the card is narrower than 1121 px, which means a window narrower than 1425 px. The constant's comment states the window width and why it was chosen: the widest date and author fits from there. The mode depends on the width available to the table, not on the screen size, and it applies to the header and every row together.
4. In date-only mode:
   - each row's "Actualizada" shows only the date, in full, such as "hace 2 meses";
   - the "Actualizada" header is not truncated;
   - header and values share the same right edge;
   - "Regla" takes the remaining space instead of 300 px, in both the header and the rows, and no seed rule code or description is truncated at 1280.
5. In full mode, "Regla" keeps its fixed 300 px and "Actualizada" shows `'<date> · <author>'` as it does today, untruncated and aligned with its header.
6. `RuleRow`'s default (`compact: false`) has the same output and layout as today. The new mode applies only when a caller opts in, and the doc comment on `RuleRow` describes it.
7. All visible text stays as it is today. No new Spanish copy is added.
8. Remove the inline `FontLoader('Inter')` `setUpAll` block and its comment from `test/app/navigation_test.dart`, leaving only `setUpAll(loadInterFont)`. Remove the `package:flutter/services.dart` import, which nothing else in that file uses. Adjust the remaining comment if it needs to mention the rules screen as well.
9. Add or update widget tests:
   - in `test/screens/rules_test.dart`, the "Actualizada" group runs through the whole app at window widths 1280, 1366 and 1424 for date-only mode, and at 1425 and 1440 for full mode. The 1418 and 1417 cases from `8acc0da` move to these values;
   - a date-only test where the widest date "hace 44 meses" is not truncated;
   - a full-mode test at the switch point (1425 px window or 1121 px card) where "hace 44 meses · Laura Cárdenas" is not truncated;
   - the `RuleRow` test from `8acc0da` for `compact: true` is kept.

## Acceptance criteria
1. **Date only at 1280.** `flutter test test/screens/rules_test.dart --plain-name "Actualizada"` passes, with a case at window width 1280 asserting that, for all 8 seed rules, the row shows only the date, such as "hace 2 meses" for `VELOCITY_5M`, and `RenderParagraph.didExceedMaxLines` is false for it. No "date · author" text is present.
2. **Header at 1280.** The same 1280 case asserts that the "Actualizada" header is not truncated and that its right edge equals each date's right edge.
3. **"Regla" at 1280.** The same 1280 case asserts that every seed rule code and description is not truncated and that the app raises no layout exception.
4. **Date and author at 1440.** The same test group has a case at window width 1440 asserting that, for all 8 seed rules, "date · author" shows in full, such as "hace 2 meses · Laura Méndez" for `VELOCITY_5M`, not truncated and right-aligned with the header.
5. **Both sides of the switch.** The same group has cases at window widths 1424 (date only) and 1425 (date and author), and both pass.
6. **Widest values.** Test names or code in `test/screens/rules_test.dart` or `test/widgets/rule_row_test.dart` contain "hace 44 meses" in date-only mode and "hace 44 meses · Laura Cárdenas" at the switch point, each asserting no truncation, and `flutter test` passes.
7. **Constants.** `grep -n "compactDateWidth = 88" lib/widgets/rule_row.dart` finds one line and `grep -n "1121" lib/screens/rules/rules_page.dart` finds the switch constant.
8. **New `RuleRow` mode.** `flutter test test/widgets/rule_row_test.dart` passes, including a `compact: true` test showing only the date in a column of `RuleRow.compactDateWidth`.
9. **Default `RuleRow` unchanged.**
   - `git diff origin/develop -- test/widgets/rule_row_test.dart` shows no removed lines, so every existing test stays as it was and passes;
   - `compact` defaults to `false` in `lib/widgets/rule_row.dart`.
10. **Rules list unchanged otherwise.** The existing groups in `test/screens/rules_test.dart` ("the list", "navigation", "the page alone") keep their assertions and pass.
11. **Only the expected code changes.** `git diff --name-only origin/develop... -- lib` lists exactly `lib/screens/rules/rules_page.dart` and `lib/widgets/rule_row.dart`.
12. **Duplicate setup removed.**
    - `grep -c "loadInterFont" test/app/navigation_test.dart` prints 1;
    - `grep -c "FontLoader\|rootBundle\|flutter/services.dart" test/app/navigation_test.dart` prints 0;
    - `flutter test test/app/navigation_test.dart` passes.

## Out of scope
- Showing the author on the rule detail screen (#22), or anywhere else below the switch point: no tooltip, no second line. The issue accepts this as a known limit.
- Any other table or column change, and any wider rework of the rules screen or of `TableHeaderRow`.
- Changing `formatDayAgo`, for example to show years after 12 months.
- Other commits or files from `factory/004-build-the-rules-list`.
- Moving the inline font setup in `test/widgets/rule_row_test.dart` to `loadInterFont`, or any font cleanup beyond requirement 8 and what `8acc0da` already does.
- Layout changes below the 1280 px minimum. `AppShell` keeps laying out at 1280 and scrolling.

## Assumptions
- **The switch point moves from 1418 to 1425 px.** Intake allowed this if measurement justified it, and 1418 truncates real formatter values. 1440 is still comfortably in full mode.
- **"In full" covers up to 99 months (over 8 years), not just the 11 months intake considered.** `formatDayAgo` has no limit, and the wider allowance only costs 4 px of "Regla" and 7 px of switch point. Three-digit months are not covered.
- **"Regla" gets 254 px at 1280 rather than 258 px.** This follows from the 88 px date column. Intake's figure was "about 258", and its real requirement, that seed codes and descriptions fit, still holds with over 20 px to spare.
- **The `test/screens/rules_test.dart` change in `8acc0da` that swaps its inline font setup for `loadInterFont` stays.** It is part of the commit being reused and uses the shared helper, so backing it out would be extra work for no benefit.
- **"Regla" jumps from about 398 px to 300 px when crossing the switch point.** This is accepted because it is how the reused design works, and nothing is truncated on either side.
