VERDICT: PASS

## Summary
- Round 2 changes only what round 1 asked for: a click cursor on `AppToggle` and `AppSegmentedControl` (`f0cca74`), plus a doc comment on `AppTextField`'s error-over-focus rule.
- Both cursor fixes follow the rule `AppButton` and `OptionCard` already use: `SystemMouseCursors.basic` when `onChanged` is null, `click` otherwise. The segments sit inside the control's `MouseRegion`, so they inherit the cursor.
- Each fix has a widget test that reads the `MouseRegion` cursor in both the enabled and the null-callback state. No existing test was changed or skipped.
- The new `AppTextField` doc matches the code: `focused` is false when `error` is set, so the error border replaces the focus border and the ring.
- `checks.sh` passed on `f0cca74` (round-2 `checks.md`). I read the code and ran no new commands.

## Findings
None.

## Notes
- Round 1 UI note on `AppTextField` (focus border 1 px to 1.5 px shifts the content by 0.5 px) is not addressed. It follows the issue's focused value, so it is fine to leave.
- Round 1 notes on the badge layout repeated three times, the AGENTS.md bullet inside the factory block, and the missing `Semantics` role and label on tappable widgets remain open. None of them blocks this PR.
