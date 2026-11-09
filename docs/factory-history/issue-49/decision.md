ESCALATE

## Summary
- Recommend merging: all 12 acceptance criteria are met, the gate passed and all three reviews passed in round 1.
- Below a 1425 px window, the rules table's "Actualizada" column shows only the date, and "Regla" takes the freed space. From 1425 px up, it still shows date and author.
- The switch point moved from the issue's proposed 1418 px to 1425 px, because measurement showed long values would lose characters at 1418.
- `ESCALATE` is only here because a person always merges in this project; no risk trigger applies.
- One check is left for you: a quick look at the table in Chrome, which agents can't do here.

## Why
The change is a layout fix in two `lib/` files plus tests, and it stays inside intake's Scope. It touches no contract, data model, feature catalog, migration, environment variable, deploy config, dependency, JWT handling or permission. The spec's assumptions are measured layout choices, not product or business decisions, and the decision to show only the date came from the issue.

## Acceptance criteria
1. Date only at 1280: met. The 1280 case in the "Actualizada" group checks all 8 seed rules for the date alone, untruncated, with no "date · author" text. I read the test and reran it, and it passes.
2. Header at 1280: met. The same case asserts the header isn't truncated and that its right edge equals each date's right edge.
3. "Regla" at 1280: met. The same case checks every seed code and description for truncation, and `pumpAtWidth` asserts no layout exception. By my arithmetic from the spec's widths, the column gets 254 px, against a widest description of 232.89 px.
4. Date and author at 1440: met. The 1440 case checks all 8 rules in full, right-aligned with the header.
5. Both sides of the switch: met. The cases at 1424 (date only) and 1425 (date and author) pass. `setDesktopView` sets the pixel ratio to 1, so these are real logical widths.
6. Widest values: met. "hace 44 meses" at a 1120 px card and "hace 44 meses · Laura Cárdenas" at a 1121 px card each assert no truncation.
7. Constants: met. The diff has `compactDateWidth = 88` and `_fullLastChangeWidth = 1121`.
8. New `RuleRow` mode: met. The `compact: true` test asserts the date alone in a column of `RuleRow.compactDateWidth`.
9. Default `RuleRow` unchanged: met. I confirmed 0 removed lines in `test/widgets/rule_row_test.dart`, and `compact` defaults to `false`. Reading the diff, the default layout is the same 300 px rule cell and `Expanded` last-change cell.
10. Rules list unchanged otherwise: met. The only lines removed from `test/screens/rules_test.dart` are the inline font setup and its import, and the existing groups pass.
11. Only the expected code changes: met. I confirmed the diff in `lib/` is exactly `rules_page.dart` and `rule_row.dart`.
12. Duplicate setup removed: met. I confirmed the counts of 1 and 0 with the spec's greps, and `test/app/navigation_test.dart` passes.

Evidence I checked myself: the rules, rule row and navigation test files pass (40 tests) at commit `4af8a5e`, and `rules_page.dart` is the only place in `lib/` that builds a `RuleRow`. The full suite (368 tests) comes from `round-1/checks.md`, which says `GATE: PASS`. GitHub reports the PR's `ci` check as passing and the PR as mergeable.

## For the human
Recommendation: merge

No project rule requires holding this PR. Before merging, please run `flutter run -d chrome`, open the rules screen and check:
- At about 1280 px, "Actualizada" shows only the date, and its header and values are complete and aligned.
- At 1440 px, it shows date and author, such as "hace 2 meses · Laura Méndez".
- Resizing across 1425 px switches the header and all rows together.

No agent ran the app in a browser, so the widths above come from widget tests using the bundled Inter font.

Limits you are accepting, none of which block the merge:
- **Tight fit at the switch point:** the longest date and author, "hace 44 meses · Laura Cárdenas", measures 186.90 px in a 187 px column at exactly 1425 px. If it renders slightly wider in a real browser, or a real author name is longer, it ends in an ellipsis and the app doesn't break. Seed values are well within the limit.
- **Author hidden below 1425 px:** the author appears nowhere at those widths until the rule detail screen (#22) ships. The issue accepts this, but the limit now starts at 1425 px rather than the 1418 px it states.
- **Column jump:** "Regla" goes from about 398 px to 300 px when crossing the switch point. The spec accepts this, and nothing is truncated on either side.
- **Three-digit months:** the 88 px date column fits dates up to "hace 99 meses". Older dates, which aren't realistic for this data, could be cut off.

Files to look at:
- `lib/widgets/rule_row.dart`
- `lib/screens/rules/rules_page.dart`
- `test/screens/rules_test.dart`, the "Actualizada" group
