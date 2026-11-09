DECISION: ACCEPT
RISK: medium
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: design tokens, bundled Inter font, the Lucide icon map and `buildAppTheme()`.
- The issue lists every value (colors, spacing, radii, shadows, text styles, icons) and gives testable acceptance criteria, so nothing is left to guess.
- No contract or data-model change is needed. It only touches `lib/theme/`, `pubspec.yaml`, assets, tests and one line of `lib/main.dart`.
- Rated medium risk: every later widget builds on this, and it adds a package dependency and binary font assets.

## Scope
Build exactly what issue #10 specifies:
- `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles` and `AppIcons` under `lib/theme/`, using the values in the issue's tables. Letter spacing is in px. `height` is line height divided by font size.
- `buildAppTheme()` returns Material 3 with the Inter font, `bgCanvas` as the scaffold background, the color scheme overrides (primary, surface, error), the divider color, no splash, and the textTheme mapping listed in the issue.
- Inter Regular, Medium and SemiBold as static TTFs plus `OFL.txt` in `assets/fonts/`, declared in `pubspec.yaml` with weights 400, 500 and 600. No runtime font fetching (no `google_fonts`).
- Add `lucide_icons_flutter`. `AppIcons` exposes the 20 named icons, `size = 20` and `all` (the 20 entries, in the issue's order).
- In `lib/main.dart`, replace only the `theme:` argument with `buildAppTheme()`.
- Test helpers `harness(child)` and `setDesktopView(tester)` as described in the issue.
- `test/theme/theme_test.dart` covers acceptance criteria 1 to 4. `flutter build web --release` succeeds. `test/widget_test.dart` passes unchanged.

Left out, as the issue says: any widget or screen, a dark theme, changes to `lib/login_screen.dart`, and responsive breakpoints. The reverted PR #29 code (tag `archive/pr-29-flutter-prototype`) is only a reference. Where it differs, the values in this issue win.

## Why
The repo has no `lib/theme/` yet. `lib/main.dart` still uses a seed-color `ThemeData`, and `pubspec.yaml` has no fonts and no icon package. This issue lays the base that later UI tasks need, and it fits in one PR. It is fully specified and touches no API, data model or feature catalog, so nothing in `monedasegura-infra` has to change first. Getting the font files means a download from Google Fonts (or reusing them from the archive tag, if they are there), which the builder needs to plan for.
