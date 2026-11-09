ESCALATE

## Summary
- Adds `lib/widgets/` with ten presentation-only gallery widgets (button, text field, two badges, pill, avatar, toggle, tab/tab bar, segmented control, option card), a 10-export barrel, and one test file per widget.
- Round 2 added a click cursor to the toggle and the segmented control (UI review finding). All three reviews now PASS and the gate passes on `f0cca74`.
- The change stays inside intake's Scope. The only file outside the new folders is a one-line AGENTS.md bullet that the spec asked for.
- No auth, permissions, JWT, migration, env var, docker-compose, CI or dependency changes, and nothing that differs from `monedasegura-infra/docs/`.
- Escalated only because a person always merges in this project. Recommendation: merge.

## Why
Every acceptance criterion in the spec is met. build.md backs each one, and I re-ran the structure and token greps and the toggle and button tests myself; all passed. The final round has `GATE: PASS` and three `VERDICT: PASS` reviews. Their open Notes are design or follow-up items (Figma token contrast, semantics and keyboard activation for later screens), not defects in this PR.

## Acceptance criteria
1. AppButton: met. `app_button_test.dart` covers the four variants, hover to `bgInverse`, tap, and disabled `Opacity` 0.4. I re-ran it and it passed.
2. AppTextField: met. `app_text_field_test.dart` covers focus border 1.5 `borderFocus` + `focusRing`, the error text in `statusBlock`, and `onChanged`. It passed in round-2 checks.
3. Badges and pill: met. The verdict, rule-status and pill tests check every Spanish label and its text color, with labels taken from `labels.dart`. They passed in checks.
4. AppAvatar: met. The test checks "VR", a 32 x 32 size and `BoxShape.circle`.
5. AppToggle: met. I read the code and test, and re-ran the test: tap reports `!value`, knob center x is 26 when on and 10 when off, null `onChanged` ignores taps, `AnimatedAlign` runs 150 ms, and `Semantics(toggled:)` is present.
6. AppTabBar: met. The test checks that tapping the third tab calls `onSelected(2)` and that only the selected tab has the 2 px bottom border.
7. AppSegmentedControl: met. The test checks that a tap returns the value and that a null `onChanged` doesn't throw or change anything.
8. OptionCard: met. The test checks the colors for all three states and that tapping calls `onTap`.
9. Structure: met. I checked it myself: `ls lib/widgets` shows the ten files plus `widgets.dart`, `grep -c export` is 10, and there are no `AppScope`, `AppStore` or `Navigator` references.
10. Tokens only: met. I checked it myself: no `Color(0x`, `fontSize:` or `lucide` in `lib/widgets`.
11. Docs: met. AGENTS.md has a "Shared widgets" bullet naming `lib/widgets/widgets.dart`.

## For the human
Recommendation: merge

This is a low-risk UI-only PR. It adds new widgets and tests, plus one AGENTS.md line, and nothing in the app uses the widgets yet. None of the project's "check before merging" triggers apply: no contract or data-model drift, no migration, env var or `docker-compose.yml`, no JWT, permissions, scoring token or simulator access.

What to check, if you want to:
- Optional walkthrough: no screen uses the widgets yet, so `flutter run -d chrome` won't show them. Review relies on the widget tests.
- Design follow-ups the UI review raised (not blockers for this PR):
  - The option card subtitle `#8B919D` on the danger background `#FBE6E3` has about 2.6:1 contrast.
  - The REVIEW badge `#B86E00` on `#FBF0DC` has about 3.5:1 contrast.
  - The text field shifts by 0.5 px when its border goes from 1 px to 1.5 px on focus. The issue specifies those two widths.
- Before screens use these widgets: add a semantics label and keyboard activation to the tappable widgets.

Files to look at: `lib/widgets/app_button.dart`, `lib/widgets/app_text_field.dart`, `lib/widgets/app_toggle.dart`, `lib/widgets/segmented_control.dart`, `lib/widgets/option_card.dart`, `AGENTS.md` (line 95).
