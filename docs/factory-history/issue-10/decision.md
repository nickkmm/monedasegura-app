ESCALATE

## Summary
- Issue #10 is built: the Figma tokens are in `lib/theme/` (AppColors, AppSpacing, AppRadius, AppShadows, AppTextStyles, AppIcons) along with `buildAppTheme()`. Inter is bundled as three real TTFs plus OFL.txt, and `main.dart` now uses `buildAppTheme()`.
- Round 1 passed: the gate is PASS (157 tests, analyze clean, web build OK) and the code, UI and UX reviews all say PASS.
- I re-ran the theme test and the existing widget test myself, and both pass. I checked the color hex values against the issue table one by one.
- I escalate because the change adds a dependency (`lucide_icons_flutter ^4.0.2`), and a person merges every PR in this project anyway.
- Recommendation: merge.

## Why
Every acceptance criterion is met with evidence I could verify, the change stays inside intake's Scope, and no review Note describes a real problem in this change. The only escalation trigger is the new package dependency. Nothing in the project's "don't merge yet" list applies: no contract, data model or catalog drift, no migration, env var or docker-compose change, and no JWT or permission code.

## Acceptance criteria
1. Each AppColors constant matches the issue: met. `theme_test.dart` has one `expect` per constant. There are 31 constants, not the 33 the spec says, but I counted the issue table myself (4+2+5+3+6+6+5 = 31). The spec miscounted and no token is missing. I compared every hex value in `app_colors.dart` with the issue table.
2. The ten AppTextStyles have the right size, weight, height and letterSpacing in Inter: met. They are asserted in the test, and I read the values against the issue table (for example title is 22 / w600 / 28/22 / -0.33).
3. The theme uses the canvas background, the accent as primary and Inter as the default font: met. The test asserts these plus surface, error, divider, no splash and the textTheme mapping.
4. AppIcons has 20 distinct entries and size 20: met. This is asserted, and the Lucide names match the issue's table.
5. The fonts are bundled: met. `file` reports TrueType for all three TTFs, OFL.txt holds the SIL OFL text, pubspec declares weights 500 and 600, and the web build passed in checks.log.
6. No runtime font fetching: met. `grep google_fonts pubspec.yaml lib` finds nothing.
7. `main.dart` changes only the theme line and its import: met (I read the diff).
8. `widget_test.dart` and `login_screen.dart` are unchanged and the widget test passes: met. The diff stat for both is empty, and I ran the test and it passed.
9. The `harness()` and `setDesktopView()` helpers work and a test uses both: met. Both are in `test/helpers/harness.dart`, and the last test in `theme_test.dart` uses them.
10. Only `app_icons.dart` imports `lucide_icons_flutter`: met (checked with grep).
11. AGENTS.md has the Theme bullet: met.

## For the human
Recommendation: merge.

- **Decision needed:** accept the new dependency `lucide_icons_flutter ^4.0.2` (pub.dev, pinned in `pubspec.lock`). Only `lib/theme/app_icons.dart` imports it, so swapping it later touches one file. Also accept the roughly 975 KB of bundled Inter font files under the SIL OFL license.
- **Quick manual check:** run `flutter run -d chrome` and open the sign-in screen once to confirm Inter loads and the screen still looks right. Agents cannot drive a browser here.
- **Non-blocking points for later tasks** (from review-ui.md):
  - `login_screen.dart` still reads `headlineMedium`, which the issue's textTheme mapping doesn't cover, so the login title keeps the Material 3 default size.
  - `ColorScheme.fromSeed` leaves the `surfaceContainer*` and `surfaceTint` roles seed-tinted, so cards and dialogs would not use `bgSurface`.
  - `textTertiary` and `statusReview` on its background are below WCAG AA contrast for small text. These colors come straight from Figma.
- **Files to look at:** `pubspec.yaml`, `pubspec.lock`, `lib/theme/app_theme.dart`, `lib/theme/app_icons.dart`, `lib/main.dart`, `test/theme/theme_test.dart`, `test/helpers/harness.dart`, `AGENTS.md`.
