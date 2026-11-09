STATUS: READY

# Build: Design tokens, Inter font, Lucide icon set and app theme

## Summary
- Adds the Figma tokens in `lib/theme/`: `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles`, `AppIcons` and `buildAppTheme()`.
- Bundles Inter (Regular, Medium 500, SemiBold 600, static TTFs from Google Fonts) with `OFL.txt`, and adds `lucide_icons_flutter ^4.0.2`.
- `lib/main.dart` now uses `buildAppTheme()`. Only the theme line and its import changed.
- Adds the shared test helpers `harness()` and `setDesktopView()`, plus `test/theme/theme_test.dart`. `factory/checks.sh` passes.
- AppColors has 31 constants, not 33. That is one per row of the issue table; the spec's "33" is a miscount.

## Changes
- `pubspec.yaml`, `pubspec.lock`: adds `lucide_icons_flutter: ^4.0.2` and declares the `Inter` font family exactly as the issue's YAML shows.
- `assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`: static Inter v20 instances from the Google Fonts CSS API (fonts.gstatic.com). `assets/fonts/OFL.txt` is the license from `google/fonts/ofl/inter`.
- `lib/theme/app_colors.dart`: `abstract final class AppColors` with one `static const Color` for each row of the issue table.
- `lib/theme/app_spacing.dart`: `AppSpacing`, `AppRadius` and `AppShadows` (`sm`, `focusRing`).
- `lib/theme/app_text_styles.dart`: the ten `AppTextStyles`. Each uses Inter and `textPrimary`, with `height` written as a fraction.
- `lib/theme/app_icons.dart`: the 20 `AppIcons` mapped to `LucideIcons.*`, plus `size = 20` and `all`. This is the only file that imports `lucide_icons_flutter`. Every Lucide name in the issue exists in v4.0.2 under that exact name, so nothing was renamed.
- `lib/theme/app_theme.dart`: `buildAppTheme()` as requirement 6 describes.
- `lib/main.dart`: `theme: buildAppTheme()` and `import 'theme/app_theme.dart';`.
- `test/helpers/harness.dart`: `harness(Widget)` and `setDesktopView(WidgetTester)`, as requirement 10 describes.
- `test/theme/theme_test.dart`: assertions for colors, text styles, spacing, radius, shadows, the theme and the icons, plus one `testWidgets` that uses both helpers.
- `AGENTS.md`: one **Theme** bullet in the "This repo" section.

## Acceptance criteria
1. [x] Each AppColors constant equals the issue's value. `flutter test test/theme/theme_test.dart` passes, and the test has one `expect` per constant: 31 in total, one for every row of the issue table. The issue table has 4 text, 2 accent, 5 bg, 3 border, 6 status, 6 nav and 5 onInverse colors, which makes 31. The spec's "33 in total" is an arithmetic slip, and no row is missing. Examples: `AppColors.accent` equals `Color(0xFF2B59C3)` and `onInverseMuted` equals `Color(0xB8FFFFFF)`.
2. [x] All ten AppTextStyles match: the test checks family `Inter`, color, size, weight, `height` (as a fraction) and `letterSpacing` for each. Examples: `title` is 22 / w600 / 28/22 / -0.33, and `hero` is 44 / w600 / 52/44 / -1.1.
3. [x] The theme test asserts `scaffoldBackgroundColor == bgCanvas`, `colorScheme.primary == accent` and `textTheme.bodyMedium!.fontFamily == 'Inter'`. It also checks surface, error, divider, splash and the textTheme mapping.
4. [x] The test asserts `AppIcons.size == 20`, `all.length == 20` and `all.toSet().length == 20`.
5. [x] `file assets/fonts/Inter-*.ttf` prints "TrueType Font data" for all three files. `grep -c "SIL OPEN FONT LICENSE" assets/fonts/OFL.txt` prints 1. `pubspec.yaml` declares Medium with `weight: 500` and SemiBold with `weight: 600`. `flutter build web --release` succeeds, and the families in `build/web/assets/FontManifest.json` include `Inter`.
6. [x] `grep -rn google_fonts pubspec.yaml lib` prints nothing.
7. [x] `git diff origin/develop -- lib/main.dart` shows only the added import and the `theme:` line change.
8. [x] `git diff --stat origin/develop -- test/widget_test.dart lib/login_screen.dart` is empty, and `flutter test test/widget_test.dart` passes.
9. [x] `test/helpers/harness.dart` matches requirement 10. The test `harness applies the app theme on a desktop view` calls both helpers and checks the theme, the `es_CO` locale and the 1440x900 view at DPR 1.
10. [x] `grep -rln lucide_icons_flutter lib test` prints only `lib/theme/app_icons.dart`.
11. [x] `grep -n "lib/theme/" AGENTS.md` matches line 94, the Theme bullet.

## Validation
- `dart format lib/theme test/theme test/helpers lib/main.dart`: no changes.
- `flutter test test/theme/theme_test.dart test/widget_test.dart`: all 7 tests passed.
- `bash /home/mrjj/ms/monedasegura-app/factory/checks.sh` from the worktree: exit 0. It ran pub get, format check, analyze ("No issues found!"), `flutter test` (157 tests, all passed) and `flutter build web --release` ("Built build/web"). The web build also prints a warning about CupertinoIcons not being bundled. That comes from the framework, not from this change.

## Log
### Round 1
- Built spec.md from scratch: tokens, theme, fonts, Lucide icons, test harness, theme tests and the AGENTS.md bullet.
- The spec says 33 AppColors, but the issue table gives 31. I implemented and tested all 31 rows and noted it above.
- The machine has no git `user.name` or `user.email`. I committed with per-command `git -c user.name=Jujoroco06 -c user.email=117993651+Jujoroco06@users.noreply.github.com`, which is the authenticated `gh` user. No git config was changed.
- Pushed `factory/001-add-the-design-tokens` and opened draft PR #34 (https://github.com/nickkmm/monedasegura-app/pull/34).
