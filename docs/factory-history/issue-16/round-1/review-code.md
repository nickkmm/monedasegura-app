VERDICT: PASS

## Summary
- Adds CaseRow, RuleRow, ConditionRow and TableHeaderRow/TableHeaderCell in lib/widgets/, exported alphabetically from widgets.dart.
- Layout, widths, text styles, hover, cursor, tap and the "—" rules all match the spec. Only theme tokens and existing data helpers are used.
- No AppScope/AppStore, hex colors or font sizes appear in the new files.
- Four widget test files cover the acceptance criteria; checks already passed.

## Findings
None.

## Notes
- ConditionRow's `_rawValue` uses `v == v.truncate()`, which would throw for NaN or infinity. Seed data never has these, so it is not blocking.
- The new widgets use class-level doc comments to describe their parameters, as score_bar.dart does. Per-field doc comments are not needed.
