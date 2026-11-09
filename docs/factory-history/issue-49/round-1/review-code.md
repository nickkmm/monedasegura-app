VERDICT: PASS

## Summary
- The date-only mode is built as specced: `RuleRow.compact` (default false), `compactDateWidth = 88`, and a `LayoutBuilder` in `_RulesTable` that switches at a 1121 px card.
- The header and rows share one `compact` flag. "Regla" is flexible in date-only mode and fixed at 300 px otherwise.
- Tests cover widths 1280, 1366 and 1424 (date only) and 1425 and 1440 (full), plus both "hace 44 meses" cases. The existing `rule_row_test.dart` tests have no removed lines.
- The duplicate font setup is gone from `navigation_test.dart`: `loadInterFont` appears once and there are no `FontLoader`, `rootBundle` or `services.dart` matches.
- The checks passed (368 tests). The diff in `lib` touches only the two expected files.

## Findings
None.

## Notes
- The switch constant's comment gives the window width (1425 px) and the reason, as required.
