DECISION: ACCEPT
RISK: low
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: nine small presentational widgets from the Figma component gallery, each with widget tests.
- Both dependencies are already on `develop`: the theme (#10) and the data layer (#11, with enums and Spanish labels).
- The work only adds new files under `lib/widgets/` and `test/widgets/`. No contract, data model or screen changes.
- The issue gives exact values, signatures and acceptance criteria, so the spec writer has nothing left to guess.

## Scope
Build the following as pure-presentation widgets, one public widget per file in `lib/widgets/`, all exported from `lib/widgets/widgets.dart`, using the signatures, values and Spanish strings in the issue exactly:
- `AppButton`: four variants (primary, secondary, ghost, danger), each with a hover state; disabled when `onPressed` is null (40 % opacity, no hover, basic cursor); optional icon; `expand`; `height`.
- `AppTextField`: label, hint, focused border plus focus ring, `errorText` state, and the callbacks listed in the issue.
- `VerdictBadge` (including `.degraded()`), `RuleStatusBadge`, and `StatusPill` (including `.model`). Their labels come from `lib/data/labels.dart`.
- `AppAvatar`, `AppToggle` (animated, with `Semantics(toggled:)`), `AppTab` and `AppTabBar`, `AppSegmentedControl<T>` (read-only when `onChanged` is null), and `OptionCard` (not selected, selected, selected + danger).

Every color, spacing, radius, shadow and text style comes from `lib/theme/`. If a value the issue needs has no token yet, add the token in `lib/theme/`, never a literal in a widget. The widgets never use `AppScope` or `AppStore`, and they only keep short-lived visual state (hover, focus). Add one test file per widget under `test/widgets/`, covering acceptance criteria 1 to 9 and using `harness()` / `setDesktopView()`.

Left out, as the issue says: data-display widgets, rows, sidebar and top bar, screens, and dropdown menus. Do not reuse `lib/data/models.dart`, `mock_data.dart` or `prototype_labels.dart` from the archived PR #29 tag.

## Why
Everything this task builds on is already in the repo. `lib/theme/app_colors.dart` and `lib/theme/app_spacing.dart` provide `AppColors.bgInverse`, `AppRadius`, `AppShadows.sm` and `AppShadows.focusRing`. `lib/data/models/enums.dart` defines `Verdict`, `RuleStatus` and `ModelStatus`, and `lib/data/labels.dart` already has their Spanish labels, including `degradedLabel`. The widgets are small, self-contained and new, and they don't touch auth, data or the API, so they fit in one PR and are easy to check with widget tests.

## Questions
