STATUS: READY

# Build: Show only the date in the rules table at narrow widths

## Summary
- Below a 1425 px window, "Actualizada" shows only the date, in full, and "Regla" takes the remaining space.
- From 1425 px up, the table keeps "Regla" at 300 px and shows date and author, as it does today.
- Reuses commit `8acc0da`, corrected to an 88 px date column and a 1121 px card switch point.
- `RuleRow` only changes when a caller passes `compact: true`; the rules table is its only user.
- Removes the duplicate Inter font setup from `test/app/navigation_test.dart`. Draft PR: #53.

## Changes
- `lib/widgets/rule_row.dart`: adds `compact` (default `false`) and `RuleRow.compactDateWidth = 88`. In compact mode the date sits in a fixed column and the rule cell expands. The doc comment describes the mode.
- `lib/screens/rules/rules_page.dart`: `_RulesTable` uses a `LayoutBuilder` to choose the mode for the header and all rows. It is compact when the card is narrower than `_fullLastChangeWidth = 1121`, and the constant's comment gives the 1425 px window and the reason.
- `test/screens/rules_test.dart`: adds the "Actualizada" group, with full-app cases at 1280, 1366, 1424, 1425 and 1440, plus the widest values at card widths 1120 and 1121. Its inline font setup becomes `setUpAll(loadInterFont)`, as in `8acc0da`.
- `test/widgets/rule_row_test.dart`: adds the `compact: true` test from `8acc0da`.
- `test/app/navigation_test.dart`: removes the inline `FontLoader` block and the `flutter/services.dart` import, and updates the remaining comment to mention the rules screen.

## Acceptance criteria
1. [x] **Date only at 1280:** `flutter test test/screens/rules_test.dart --plain-name "Actualizada"` passes (7 tests). The 1280 case checks all 8 seed rules for the date alone, such as "hace 2 meses" for `VELOCITY_5M`, with `didExceedMaxLines` false and no "date · author" text.
2. [x] **Header at 1280:** the same case checks that the header is not truncated and that its right edge equals each date's right edge.
3. [x] **"Regla" at 1280:** the same case checks every seed code and description for truncation, and `pumpAtWidth` asserts `tester.takeException()` is null.
4. [x] **Date and author at 1440:** the 1440 case checks all 8 rules, including "hace 2 meses · Laura Méndez", not truncated and right-aligned with the header.
5. [x] **Both sides of the switch:** the cases at 1424 (date only) and 1425 (date and author) pass.
6. [x] **Widest values:** in `rules_test.dart`, 'just below the switch point "hace 44 meses" fits' (card 1120) and 'at the switch point "hace 44 meses · Laura Cárdenas" fits' (card 1121) pass, each asserting no truncation. The full `flutter test` passes.
7. [x] **Constants:** `grep` finds `rule_row.dart:32: static const double compactDateWidth = 88;` and `rules_page.dart:110: static const double _fullLastChangeWidth = 1121;`.
8. [x] **New `RuleRow` mode:** `flutter test test/widgets/rule_row_test.dart` passes (run together with the rules and navigation test files), including the `compact: true` test that shows only the date in a column of `RuleRow.compactDateWidth`.
9. [x] **Default `RuleRow` unchanged:** `git diff origin/develop -- test/widgets/rule_row_test.dart` has 0 removed lines, and `rule_row.dart:28` has `this.compact = false`.
10. [x] **Rules list unchanged otherwise:** the "the list", "navigation" and "the page alone" groups pass. The only lines removed from `rules_test.dart` are the inline font setup and its import, so their assertions are unchanged.
11. [x] **Only the expected code changes:** `git diff --name-only origin/develop... -- lib` lists exactly `lib/screens/rules/rules_page.dart` and `lib/widgets/rule_row.dart`.
12. [x] **Duplicate setup removed:** the `loadInterFont` count is 1, the `FontLoader|rootBundle|flutter/services.dart` count is 0, and `flutter test test/app/navigation_test.dart` passes (run together with the two test files above).

## Validation
- `bash factory/checks.sh` from the worktree: passed (exit 0). Format changed 0 of 123 files, `flutter analyze` found no issues, `flutter test` passed 368 tests, and `flutter build web --release` built.
- `flutter test test/screens/rules_test.dart test/widgets/rule_row_test.dart test/app/navigation_test.dart`: passed (40 tests).
- `flutter test test/screens/rules_test.dart --plain-name "Actualizada"`: passed (7 tests).
- Mutation checks, both restored before committing:
  - with `compactDateWidth = 84`, the "hace 44 meses" test fails;
  - with the switch at 1114, the 1424 case and the "hace 44 meses" test fail.
- Not run: a walk through the app with `flutter run -d chrome`. AGENTS.md leaves that to a person, because agents check pages with widget tests here.
- CI on the PR had not been checked when this was written.

## Log
### Round 1
- Cherry-picked `8acc0da` cleanly, taking nothing else from `factory/004-build-the-rules-list`.
- Applied the 88 px date column and the 1121 px card switch point, and moved the test widths to 1424 and 1425.
- Dropped the 1000 px case that came with `8acc0da`, because the spec lists 1280, 1366 and 1424 for date-only mode and leaves layouts below 1280 out of scope.
- Added the widest-value tests through `RulesPage` at card widths 1120 and 1121, rather than `RuleRow` alone, so they also exercise the switch constant.
- Added a one-line comment on `compactDateWidth` saying what it fits.
- Removed the duplicate font setup from the navigation test.
- Opened draft PR #53.
