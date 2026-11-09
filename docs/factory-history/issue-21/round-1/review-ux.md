VERDICT: PASS

## Summary
- AGENTS.md says there is no browser tool for this repo, so I checked the code against the spec and ran the widget tests. I did not start a dev server.
- `flutter test test/screens/rules_test.dart` passes with 13 of 13 tests.
- The tabs and their live counts, the table headers, the empty state, the lifecycle legend and the permission-gated "Nueva regla" button all match the spec.
- The Screen and Page split follows the repo pattern. The copy is in Spanish and comes from the shared labels.

## Findings
None.

## Notes
- Rows use `RuleRow.onTap`, so keyboard and semantics behaviour depends on that shared widget. That is outside this change.
- The table has a fixed-width layout. `AppShell` handles narrow screens, so the table cannot be checked at phone width without a manual walkthrough.
