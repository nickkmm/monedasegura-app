# Design tokens, Inter font, Lucide icon set and app theme

> Issue #10: Add the design tokens, Inter font, icon set and app theme

## Summary
- Adds the Figma design tokens as Dart constants in `lib/theme/` (`AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles`, `AppIcons`), using the exact values in issue #10.
- Bundles Inter (Regular, Medium, SemiBold, plus the OFL license) as local assets, and adds `lucide_icons_flutter` for the 20 gallery icons.
- Adds `buildAppTheme()` and changes only the `theme:` line in `lib/main.dart` to use it.
- Adds the shared test helpers `harness()` and `setDesktopView()` and a theme test that covers acceptance criteria 1 to 4.
- Builds the scope intake accepted, with no rescoping. The tag `archive/pr-29-flutter-prototype` is a reference only, and the issue's values win where they differ.

## Context
- `lib/main.dart` defines `MonedaSeguraApp`, a `MaterialApp` with `locale: Locale('es', 'CO')`, `supportedLocales: [Locale('es', 'CO')]`, `localizationsDelegates: GlobalMaterialLocalizations.delegates` and `theme: ThemeData(colorSchemeSeed: Color(0xFF4453C9), useMaterial3: true)`. Home is `LoginScreen` (`lib/login_screen.dart`), which reads `Theme.of(context).textTheme.headlineMedium`.
- `pubspec.yaml` depends only on `flutter` and `flutter_localizations`. Its `flutter:` section has `uses-material-design: true` and no fonts or assets. No `assets/` folder exists.
- `lib/theme/`, `lib/widgets/` and `test/helpers/` do not exist yet. Existing code is the data layer (`lib/data/...`) and `lib/app/app_scope.dart`, with tests under `test/data/` and `test/app/`. These tests import through `package:monedasegura_app/...`.
- `test/widget_test.dart` pumps `MonedaSeguraApp` and checks the Spanish sign-in labels. It must stay unchanged and keep passing.
- Reference only: `git show archive/pr-29-flutter-prototype:lib/theme/app_theme.dart`, `lib/theme/tokens.dart` and `lib/widgets/ms_icon.dart`. That code uses different names (`MsColors`, `MsText`, an `MsIconName` enum mapped to Material icons), and the tag contains no font files. Do not copy its naming or its Material icon mapping.
- `factory/checks.sh` runs `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` and `flutter build web --release`.
- The Flutter SDK may only be at `$HOME/development/flutter/bin` (see `factory/checks.sh`).

## Requirements
1. Create `lib/theme/app_colors.dart` with `abstract final class AppColors`. It holds one `static const Color` for every row of the issue's AppColors table, with the exact names and hex values. That is 33 constants. Each `/` row (`statusApprove` / `statusApproveBg`, and so on) gives two constants. The `onInverse*` alpha colors use the given ARGB literals: `0xB8FFFFFF`, `0x29FFFFFF`, `0x1FFFFFFF`, `0x14FFFFFF`. `onInverseDelta` is `0xFF8CD9B2`.
2. Create `lib/theme/app_spacing.dart` with these three classes:
   - `abstract final class AppSpacing`: `xxs` 2, `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32, `xxxl` 48.
   - `abstract final class AppRadius`: `sm` 6, `md` 10, `lg` 14, `full` 999.
   - `abstract final class AppShadows`: `static const List<BoxShadow> sm = [BoxShadow(color: Color(0x0F121214), offset: Offset(0, 1), blurRadius: 2)]` and `static const List<BoxShadow> focusRing = [BoxShadow(color: Color(0x1F3045E8), spreadRadius: 4)]`.
   - Spacing and radius values are `static const double`.
3. Create `lib/theme/app_text_styles.dart` with `abstract final class AppTextStyles`. It holds ten `static const TextStyle` values: `hero`, `display`, `metric`, `title`, `heading`, `body`, `bodyStrong`, `caption`, `badge`, `label`. Each has `fontFamily: 'Inter'`, `color: AppColors.textPrimary`, and the `fontSize`, `fontWeight` and `letterSpacing` from the issue's table. `height` is line height divided by font size, written as a fraction (for example `28 / 22`).
4. Add `lucide_icons_flutter` to `dependencies` in `pubspec.yaml` and commit the updated `pubspec.lock`.
5. Create `lib/theme/app_icons.dart` with `abstract final class AppIcons`:
   - The 20 `static const IconData` fields named in the issue (`shield`, `inbox`, `dashboard`, `sliders`, `cpu`, `play`, `search`, `chevronRight`, `check`, `close`, `back`, `bell`, `filter`, `clock`, `logout`, `users`, `plus`, `zap`, `phone`, `pin`). Each maps to the Lucide icon in the issue's table through the package's `LucideIcons` class.
   - `static const double size = 20;`
   - `static const List<IconData> all` with the 20 fields in that order.
   - This is the only file that imports `lucide_icons_flutter`.
6. Create `lib/theme/app_theme.dart` with a top-level `ThemeData buildAppTheme()`. It returns:
   - `ThemeData` with `useMaterial3: true`, `fontFamily: 'Inter'`, `scaffoldBackgroundColor: AppColors.bgCanvas`, `dividerColor: AppColors.borderDefault` and `splashFactory: NoSplash.splashFactory`.
   - `colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent).copyWith(primary: AppColors.accent, surface: AppColors.bgSurface, error: AppColors.statusBlock)`.
   - A `textTheme` that maps `displaySmall` to `display`, `headlineSmall` to `title`, `titleMedium` to `heading`, `bodyMedium` to `body`, `bodySmall` to `caption`, `labelLarge` to `bodyStrong` and `labelSmall` to `label`.
   - Nothing beyond what the issue lists.
7. Download Inter from Google Fonts (static Regular 400, Medium 500, SemiBold 600) to `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-Medium.ttf` and `assets/fonts/Inter-SemiBold.ttf`. Put the SIL Open Font License text in `assets/fonts/OFL.txt`. They must be real TrueType files, not placeholders or HTML error pages.
8. In the `flutter:` section of `pubspec.yaml`, declare the `Inter` font family exactly as the issue's YAML block shows (Regular without a weight, Medium `weight: 500`, SemiBold `weight: 600`). Do not add `google_fonts` or any runtime font fetching.
9. In `lib/main.dart`, replace the `theme: ThemeData(...)` argument with `theme: buildAppTheme()` and add the import it needs. Change nothing else in the file.
10. Create `test/helpers/harness.dart` with two helpers:
    - `Widget harness(Widget child)`: returns `MaterialApp(theme: buildAppTheme(), locale: const Locale('es', 'CO'), supportedLocales: const [Locale('es', 'CO')], localizationsDelegates: GlobalMaterialLocalizations.delegates, home: Scaffold(body: Center(child: child)))`.
    - `Future<void> setDesktopView(WidgetTester tester)`: sets `tester.view.physicalSize = const Size(1440, 900)` and `tester.view.devicePixelRatio = 1`, and registers `addTearDown` calls that run `tester.view.resetPhysicalSize()` and `tester.view.resetDevicePixelRatio()`.
11. Create `test/theme/theme_test.dart`. It asserts:
    - every `AppColors` constant, by exact `Color` equality (AC 1);
    - `fontSize`, `fontWeight`, `height` and `letterSpacing` of all ten `AppTextStyles` (AC 2);
    - `buildAppTheme().scaffoldBackgroundColor == AppColors.bgCanvas`, and that the theme's default font family is `Inter`, for example `buildAppTheme().textTheme.bodyMedium!.fontFamily == 'Inter'` (AC 3);
    - `AppIcons.all.length == 20` and `AppIcons.all.toSet().length == 20` (AC 4);
    - at least one `testWidgets` that pumps `harness(...)` with `setDesktopView` applied, so both helpers are exercised.
12. Update the "This repo (monedasegura-app)" section of `AGENTS.md` with one bullet. It says that design tokens live in `lib/theme/` (`AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTextStyles`, `AppIcons`, `buildAppTheme()`), that widgets never write hex colors, font sizes or icons outside it, and that widget tests use `test/helpers/harness.dart`.

## Acceptance criteria
1. Each `AppColors` constant equals the issue's value. Verify: `flutter test test/theme/theme_test.dart` passes, and reading the test shows one assertion per constant (33 in total, for example `AppColors.accent == const Color(0xFF2B59C3)` and `AppColors.onInverseMuted == const Color(0xB8FFFFFF)`).
2. All ten `AppTextStyles` have the issue's size, weight, `height` and `letterSpacing`, and use family `Inter`. Verify: the same test asserts them. For example, `title` is 22, `FontWeight.w600`, `28 / 22`, `-0.33`, and `hero` is 44, `w600`, `52 / 44`, `-1.1`.
3. `buildAppTheme()` returns a theme with `scaffoldBackgroundColor == AppColors.bgCanvas`, `colorScheme.primary == AppColors.accent` and Inter as the default font. Verify: the same test.
4. `AppIcons.all` has 20 distinct entries and `AppIcons.size == 20`. Verify: the same test.
5. The fonts are bundled. Verify: `file assets/fonts/Inter-*.ttf` reports TrueType font data for all three, `assets/fonts/OFL.txt` contains "SIL OPEN FONT LICENSE", and `pubspec.yaml` declares the three assets with weights 500 and 600 for Medium and SemiBold. `flutter build web --release` succeeds, and `build/web/assets/FontManifest.json` lists the family `Inter`.
6. No runtime font fetching. Verify: `grep -rn google_fonts pubspec.yaml lib` returns nothing.
7. `lib/main.dart` differs from `origin/develop` only in the theme line and its import. Verify: `git diff origin/develop -- lib/main.dart`.
8. `test/widget_test.dart` and `lib/login_screen.dart` are unchanged and the widget test passes. Verify: `git diff --stat origin/develop -- test/widget_test.dart lib/login_screen.dart` is empty, and `flutter test test/widget_test.dart` passes.
9. `test/helpers/harness.dart` exports `harness(Widget)` and `setDesktopView(WidgetTester)` with the behavior in requirement 10, and a test in `test/theme/theme_test.dart` uses both. Verify: read the file and run `flutter test test/theme/theme_test.dart`.
10. `lucide_icons_flutter` is imported only in `lib/theme/app_icons.dart`. Verify: `grep -rln lucide_icons_flutter lib test` lists only that file.
11. `AGENTS.md` has the theme bullet from requirement 12. Verify: `grep -n "lib/theme/" AGENTS.md`.

## Out of scope
- Any widget or screen, including an icon wrapper widget like PR #29's `MsIcon`. Do not create `lib/widgets/` in this task.
- A dark theme, responsive breakpoints, or component themes (button, input, card) beyond what requirement 6 lists.
- Any change to `lib/login_screen.dart`, `test/widget_test.dart`, or anything in `lib/main.dart` other than the theme line and its import.
- The data layer (`lib/data/`), `lib/app/`, and the files from the archive tag (`lib/data/models.dart`, `mock_data.dart`, `prototype_labels.dart`).
- `google_fonts`, variable-font Inter, extra Inter weights, or SVG icon exports.
- Changes to `factory/checks.sh`, `factory/config.json`, CI workflows or the Dockerfile.

## Assumptions
- `lucide_icons_flutter` exposes camelCase members on `LucideIcons` (`layoutDashboard`, `slidersVertical`, `logOut`, `mapPin`, `smartphone`, `arrowLeft`, `x`). If the version pub resolves names one of them differently, the builder uses that version's member for the same Lucide glyph and notes it in build.md. Reason: the issue fixes the glyph, not the package's Dart identifier.
- Use the latest `lucide_icons_flutter` version compatible with the repo's Dart SDK (`^3.13.0`), with a caret constraint. Reason: the issue names no version.
- The theme test checks the 33 color constants individually rather than in a loop over a map built from the class. Reason: the issue's AC 1 asks to assert "every value", and explicit assertions are easiest for the approver to check.
- `harness()` also sets `supportedLocales: [Locale('es', 'CO')]`. Reason: `main.dart` sets it, and the issue asks for "the same localization delegates as `main.dart`". Without the supported locale, `es_CO` would not resolve.
- AGENTS.md gets a one-bullet note about `lib/theme/` and the test harness. Reason: later factory tasks rely on AGENTS.md to find shared foundations, the same way it already lists the data layer.
