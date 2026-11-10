VERDICT: PASS

## Summary
- Draft editing and the `/rules/new` form are implemented as specified. The screen owns the buffer, validation, store calls and navigation, and the page only gets props and callbacks.
- `isValidCondition` and `ruleCodePattern` are now public and reused, so there is no second regex or validity check. `parseConditionValue` follows the spec.
- `ConditionRow` gets `error` and its doc comment is updated. The old `/rules/new` placeholder tests are updated, and `grep "Disponible pronto" lib test` finds nothing.
- Checks passed (442 tests, build OK). New tests cover the acceptance criteria. Only `*_screen.dart` files reference `AppScope`/`AppStore`.

## Findings
None.

## Notes
- `_seed` is called from `build`. It only mutates fields and is guarded by `_seeded`, so it is acceptable, but it is a little unusual.
- `conditionValueText` moved from `ConditionRow` into `format.dart`. This is a sensible reuse and is tested.
- `ConditionRow.didUpdateWidget` now skips overwriting typed text that parses to the new value (for example "1.000.000"). This is a small extension beyond the spec but needed for the typing flow, and it has a test.
