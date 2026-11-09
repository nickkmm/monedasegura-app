STATUS: READY

# Build: Basic gallery widgets

## Summary
- New `lib/widgets/` with ten presentation-only gallery widgets plus the `widgets.dart` barrel (10 exports).
- All colors, radii, spacing, shadows and text styles come from `lib/theme/`; labels from `lib/data/labels.dart`.
- One widget test file per widget file under `test/widgets/` (24 tests), covering acceptance criteria 1 to 8.
- AGENTS.md gets a "Shared widgets" bullet. `factory/checks.sh` passes; draft PR #35.
- Round 2: the toggle and segmented control show a click cursor when tappable (basic when `onChanged` is null), as the UI review asked.

## Changes
- `lib/widgets/app_button.dart`: `AppButtonVariant` and `AppButton` (MouseRegion hover flag, hover colors per variant, danger hover `statusBlock.withValues(alpha: 0.88)`, disabled wrapped in `Opacity(0.4)` with basic cursor and no hover, `expand` full width, 16 px icon + 8 px gap).
- `lib/widgets/app_text_field.dart`: `AppTextField` (caption label, 4 px gap, 44 px `Container` with `BoxDecoration`; default border 1 `borderDefault`, focused 1.5 `borderFocus` + `AppShadows.focusRing`, error border 1 `statusBlock` + caption message below; owns its `FocusNode` and, when none is given, its controller, disposing both; all issue parameters passed to the inner `TextField`). When `errorText` is set the error styling replaces the focus styling (stated in the class doc comment since round 2).
- `lib/widgets/verdict_badge.dart`: `VerdictBadge` and `VerdictBadge.degraded()`.
- `lib/widgets/rule_status_badge.dart`: `RuleStatusBadge` (same geometry as the verdict badge).
- `lib/widgets/status_pill.dart`: `StatusTone`, `StatusPill`, `StatusPill.model(ModelStatus)`.
- `lib/widgets/app_avatar.dart`: `AppAvatar` (circle, `badge` text in `textInverse`).
- `lib/widgets/app_toggle.dart`: `AppToggle` (36 x 20 track, 16 px knob, `AnimatedAlign` 150 ms, `Semantics(toggled:)`, null `onChanged` ignores taps; `MouseRegion` click cursor when tappable, basic otherwise).
- `lib/widgets/app_tab.dart`: `AppTab` and `AppTabBar` (gap 16, 1 px `borderDefault` bottom border across the row; only the active tab has a decoration with a 2 px `bgInverse` bottom border, inactive tabs reserve 2 px bottom padding so labels align).
- `lib/widgets/segmented_control.dart`: `AppSegmentedControl<T>` (`MouseRegion` click cursor when `onChanged` is set, basic when read-only).
- `lib/widgets/option_card.dart`: `OptionCard` (three color sets, min height 64, width from parent).
- `lib/widgets/widgets.dart`: barrel exporting the ten files.
- `test/widgets/*_test.dart`: ten test files, one per widget file, all through `harness()` + `setDesktopView()` and importing `package:monedasegura_app/widgets/widgets.dart`.
- `AGENTS.md`: "Shared widgets" bullet in "This repo (monedasegura-app)".

## Acceptance criteria
1. [x] AppButton: `flutter test test/widgets/` passes `app_button_test.dart` (four variants' background/border/label color, mouse-gesture hover -> `bgInverse`, tap calls `onPressed`, disabled tap does nothing with ancestor `Opacity` 0.4).
2. [x] AppTextField: `app_text_field_test.dart` passes (label + hint, focus border 1.5 `borderFocus` + `focusRing`, `errorText: 'X'` in `statusBlock`, `enterText` -> `onChanged`).
3. [x] Badges and pill: `verdict_badge_test.dart`, `rule_status_badge_test.dart`, `status_pill_test.dart` pass (all Spanish labels with their text colors).
4. [x] AppAvatar: `app_avatar_test.dart` passes ("VR", size 32 x 32, `BoxShape.circle`).
5. [x] AppToggle: `app_toggle_test.dart` passes (tap -> `!value`; knob center x 26 on, 10 off after `pumpAndSettle`; null `onChanged` ignores taps).
6. [x] AppTabBar: `app_tab_test.dart` passes (third tap -> `onSelected(2)`; only the selected tab's decoration has a 2 px bottom border).
7. [x] AppSegmentedControl: `segmented_control_test.dart` passes (tap -> value; `onChanged: null` tap throws nothing, selection unchanged).
8. [x] OptionCard: `option_card_test.dart` passes (bg/border/title colors for the three states, width from parent, tap -> `onTap`).
9. [x] Structure: `ls lib/widgets` lists the ten files + `widgets.dart`; `grep -c "export" lib/widgets/widgets.dart` = 10; `grep -rnE "AppScope|AppStore" lib/widgets` prints nothing (also no `Navigator`, `lib/app/` or `app_store` imports).
10. [x] Tokens only: `grep -rnE "Color\(0x|fontSize:" lib/widgets` and `grep -rn "lucide" lib/widgets` print nothing.
11. [x] Docs: `grep -n "lib/widgets/widgets.dart" AGENTS.md` matches line 95.

## Validation
- `dart format` on the changed widget and test files: done.
- `flutter analyze`: No issues found.
- `flutter test test/widgets`: 24 tests, all passed.
- `bash /home/mrjj/ms/monedasegura-app/factory/checks.sh` from the worktree (round 2, commit `f0cca74`): exit 0 (format clean, analyze clean, 181 tests passed, web release build succeeded).
- Grep checks for criteria 9 and 10 run again after round 2: still clean.

## Log
### Round 1
Ran `flutter pub get`, built the ten widgets and the barrel from the spec and issue #13 (reusing logic from the `archive/pr-29-flutter-prototype` widgets, with this issue's names and values), wrote one test file per widget, added the AGENTS.md bullet, ran the checks (pass), committed in two commits, pushed and opened draft PR https://github.com/nickkmm/monedasegura-app/pull/35. Choices worth reviewing: `AppTextField` lets the error styling override focus styling (no ring while in error); `AppTab`/`OptionCard`/`AppButton` show a click cursor when tappable; the two 24 px badges each carry their own small private layout (no shared helper file, since `lib/widgets` must list exactly eleven files).

### Round 2
Reviews: code PASS, ux PASS, ui CHANGES.
- ui finding 1 (`app_toggle.dart` has no cursor): wrapped the toggle in a `MouseRegion` with `SystemMouseCursors.click` when `onChanged` is set and `basic` when it is null. Added a test in `app_toggle_test.dart`.
- ui finding 2 (`segmented_control.dart` has no cursor): wrapped the control in a `MouseRegion` with the same rule. The read-only look is unchanged. Added a test in `segmented_control_test.dart`.
- code note (say in the doc comment that the error styling beats focus): added one sentence to the `AppTextField` doc comment.
- Not changed (notes only, outside the spec): the contrast of the Figma tokens (needs a design decision), the 0.5 px shift when the border goes to 1.5 px on focus (the issue gives 1 px default and 1.5 px focused), the badge layout copied in three files (needs a spec change), semantics and keyboard activation for the tappable widgets (left for the screen work), the AGENTS.md bullet sitting inside the factory block (same place as the Theme and Data layer bullets).
Checks pass on `f0cca74`, pushed to PR #35.
