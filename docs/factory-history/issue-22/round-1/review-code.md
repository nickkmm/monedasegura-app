VERDICT: PASS

## Summary
- The stateful host screen and the callback-only `RuleEditorPage` match the spec: derived flags, approver selection, `DomainError` to SnackBar, empty states and the `Regla` title.
- The page's stepper states, backtest tiles (sign rounding, "—" for missing recall, singular forms), timeline, approver box, reject dialog and versions card follow requirements 10 to 25.
- `formatConditionValue` moved to `format.dart` and `ConditionRow` now calls it. The seed recall is changed to 0.742 and 0.773 and its test updated.
- The page and dialog reference neither `AppScope` nor `AppStore`. There are 26 new widget tests plus formatter tests, and the checks passed.

## Findings
None.

## Notes
- Criterion 4's `/rules` list check is deferred because #21 is not merged. This is allowed by the spec, and the PR body must say so.
- The `ruleId` closures capture `version.version` at build time. That is fine, because every rebuild refreshes them.
