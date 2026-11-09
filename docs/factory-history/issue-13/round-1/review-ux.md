VERDICT: PASS

## Summary
- The branch adds shared presentation widgets and tests only. It has no page or screen, so there is no flow to try.
- Per AGENTS.md ("How to check a page here"), I checked it with the widget tests instead of a browser. `flutter test test/widgets` passes: 22 tests.
- The widgets follow the spec and the Spanish-labels policy. Labels come from `lib/data/labels.dart`, and `AppToggle` has `Semantics(toggled)`.

## Findings
None.

## Notes
- `AppButton`, `AppTab`, `AppSegmentedControl` and `OptionCard` use `GestureDetector` with no `Focus`, no keyboard activation (Enter/Space) and no button semantics. Keyboard and screen-reader users can't use them. The spec didn't ask for this, so it isn't blocking. Add `Semantics(button: true)` and focusable activation (for example `InkWell` or `FocusableActionDetector`) in a follow-up before real screens use them.
- Mobile width wasn't checked in a browser. The widgets take their width from their parent, which is the right approach.
