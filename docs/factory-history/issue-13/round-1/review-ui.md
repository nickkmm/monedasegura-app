VERDICT: CHANGES

## Summary
- The branch adds ten gallery widgets under `lib/widgets/` and a barrel. No screen imports them yet, so nothing shows on a page and no dev server or browser check was needed. AGENTS.md says reviewers check UI here by widget tests and by reading the code against the issue values.
- Every color, radius, spacing, shadow and text style I checked matches the issue #13 values and comes from `lib/theme/`. Labels match `lib/data/labels.dart` and the issue strings exactly.
- `flutter test test/widgets` passes (22 tests). No hex literal, `fontSize:` or lucide reference appears in `lib/widgets`.
- One visible inconsistency: the clickable toggle and segmented control show the default cursor on web, while the button, tab and option card show a click cursor.
- Two contrast points on the Figma tokens are noted below for a design decision. They do not block this round.

## Findings
1. `lib/widgets/app_toggle.dart:` the toggle has no `MouseRegion`, so on web a tappable toggle shows the arrow cursor. Wrap it in `MouseRegion(cursor: onChanged == null ? SystemMouseCursors.basic : SystemMouseCursors.click)`, the same rule `AppButton` and `OptionCard` use.
2. `lib/widgets/segmented_control.dart:` the segments are tappable `GestureDetector`s with no cursor, so they show the arrow on web. Add the same `MouseRegion` cursor rule per segment (or around the control), so `onChanged == null` shows `SystemMouseCursors.basic`. Keep the read-only look unchanged.

## Notes
- Contrast of the Figma text tokens (WCAG ratio, computed from the hex values). These come from the issue, so I did not change them; they need a design decision:
  - Option card subtitle `#8B919D` on the selected + danger background `#FBE6E3` is about 2.6:1, and on the white default card about 3.2:1. Both are below 4.5:1 for 12 px text. A possible fix is `AppColors.textSecondary` (#545B69, about 5.7:1 on `#FBE6E3`) for the subtitle on the danger card, but that departs from the issue, so confirm it in Figma first.
  - Verdict REVIEW badge `#B86E00` on `#FBF0DC` is about 3.5:1, and Approve `#2F7D55` on `#E5F2EA` is about 4.35:1 (just under 4.5:1). These are theme token values, so this is a system-wide question, not something for this PR.
- `AppTextField`: the border goes from 1 px to 1.5 px on focus, which moves the inner content by 0.5 px. This is hardly visible, but a constant 1.5 px border (with a `borderDefault` color when unfocused) would avoid the shift.
- `AppTextField`: when `errorText` is set and the field is focused, the focus ring is dropped and only the red border shows. That is a reasonable call and matches the build notes, so keep it.
- `AppToggle`: `Semantics(toggled: value)` has no label and no tap action. On the screens that use it, pass the label through a `Semantics` wrapper, or add it when the first screen needs it.
- Disabled look: `AppToggle` (with `onChanged == null`) and `AppSegmentedControl` (read-only) have no dimmed style. The issue defines none, so this is fine for now.
- `AppTabBar` and `AppSegmentedControl` look right against the issue geometry (gap 16, underline 2 px, segment padding 16/4, radius 6/10). The toggle knob centres at x 26 (on) and x 10 (off), as the issue requires.
