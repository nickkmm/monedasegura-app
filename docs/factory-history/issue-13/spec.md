# Basic gallery widgets

> Issue #13: Build the basic gallery widgets: button, input, badges, pill, avatar, toggle, tab, segment, option card

## Summary
- Adds the first shared widgets folder, `lib/widgets/`: ten public, presentation-only widgets from the Figma component gallery (button, text field, verdict badge, rule status badge, status pill, avatar, toggle, tab and tab bar, segmented control, option card), plus a `widgets.dart` barrel.
- Every color, radius, spacing, shadow and text style comes from the existing `lib/theme/` tokens, and every Spanish label from `lib/data/labels.dart`. All the colors the issue lists already exist as `AppColors` tokens.
- Adds one widget test file per widget under `test/widgets/`, covering the issue's acceptance criteria 1 to 9.
- Adds one line to AGENTS.md about `lib/widgets/` and the barrel. Nothing else changes: no screens, no data layer, no API.

## Context
- **There are no widgets yet.** `lib/widgets/` does not exist on `develop`, so this task creates it. The app today is `lib/main.dart` plus a placeholder `lib/login_screen.dart`.
- **Theme** (`lib/theme/`, from #10):
  - `app_colors.dart` has every color the issue names. `textPrimary` #161B26, `textSecondary` #545B69, `textTertiary` #8B919D, `textInverse` #FFFFFF; `accent` #2B59C3, `accentSubtle` #E8EEFA; `bgInverse` #14213D, `bgSurface` #FFFFFF, `bgSubtle` #E9EBEF, `bgHover` #EEF0F3; `borderDefault` #DFE2E8, `borderStrong` #C5CAD3, `borderFocus` #2B59C3; `statusApprove`/`statusApproveBg` #2F7D55/#E5F2EA, `statusReview`/`statusReviewBg` #B86E00/#FBF0DC, `statusBlock`/`statusBlockBg` #B42318/#FBE6E3.
  - `app_spacing.dart` has `AppSpacing` (xxs 2, xs 4, sm 8, md 12, lg 16, xl 24…), `AppRadius` (sm 6, md 10, full 999), and `AppShadows.sm` and `AppShadows.focusRing`.
  - `app_text_styles.dart` has `body`, `bodyStrong`, `caption` and `badge`. Their default color is `textPrimary`, so set other colors with `copyWith(color: ...)`.
  - `app_icons.dart` is the only file allowed to name the Lucide icon set.
- **Data layer** (#11):
  - `lib/data/models/enums.dart` defines `Verdict`, `RuleStatus` and `ModelStatus`, all exported through `lib/data/models/models.dart`.
  - `lib/data/labels.dart` defines `degradedLabel` ('Degradada') and the `.label` extensions on `Verdict`, `RuleStatus` and `ModelStatus`. These give exactly the Spanish strings the issue lists.
- **Test helpers:** `test/helpers/harness.dart` provides `harness(Widget)` (MaterialApp with the app theme and the es_CO locale) and `setDesktopView(tester)`. `test/theme/theme_test.dart` shows the house style for tests.
- **Reference code:** the tag `archive/pr-29-flutter-prototype` has earlier versions in `lib/widgets/ms_button.dart`, `ms_text_field.dart`, `badges.dart`, `ms_avatar.dart`, `ms_tabs.dart`, `ms_segmented.dart` and `option_card.dart`, with tests in `test/widgets/shared_widgets_test.dart`. Read them with `git show archive/pr-29-flutter-prototype:<path>`. The builder may reuse logic from there, but the names, files, signatures and values in this spec and the issue win. Never import or recreate that tag's `lib/data/models.dart`, `mock_data.dart` or `prototype_labels.dart`.
- **Repo rules** (AGENTS.md "This repo"): each component is one shared widget, built once; widgets get their data through parameters and report through callbacks; no hex colors, font sizes or icons outside `lib/theme/`.

## Requirements
1. Create the files below under `lib/widgets/`. Each holds one public widget, with the exact public API given in issue #13 (constructor names, parameter names, types and defaults):
   - `app_button.dart`: `AppButtonVariant { primary, secondary, ghost, danger }` and `AppButton`.
   - `app_text_field.dart`: `AppTextField`.
   - `verdict_badge.dart`: `VerdictBadge` and `VerdictBadge.degraded()`.
   - `rule_status_badge.dart`: `RuleStatusBadge`.
   - `status_pill.dart`: `StatusTone { success, accent, neutral, warning, danger }`, `StatusPill` and `StatusPill.model(ModelStatus)`.
   - `app_avatar.dart`: `AppAvatar`.
   - `app_toggle.dart`: `AppToggle`.
   - `app_tab.dart`: `AppTab` and `AppTabBar`. This is the one file the issue allows to hold two widgets.
   - `segmented_control.dart`: `AppSegmentedControl<T>`.
   - `option_card.dart`: `OptionCard`.
2. Create `lib/widgets/widgets.dart`, which exports every file in requirement 1.
3. Each widget renders the geometry, colors, text styles, states and Spanish strings given for it in issue #13, section "Specification":
   - Every color is an `AppColors` constant. The danger button's hover is `AppColors.statusBlock` at 88 % opacity (`withValues(alpha: 0.88)`), not a new literal.
   - Every radius, spacing and shadow is an `AppRadius`, `AppSpacing` or `AppShadows` constant.
   - Every text style is an `AppTextStyles` style, with `copyWith(color:)` only.
   - The widgets contain no `Color(0x…)` literal and no `fontSize:`. Fixed component dimensions (button height 40, field height 44, toggle 36 x 20 with a 16 px knob, dot 6, icon 16, avatar 32, tab height 40, option card min height 64) can be numeric values or named constants inside the widget file.
4. Labels come from `lib/data/labels.dart`, never from strings typed into the widget: `verdict.label`, `degradedLabel`, `status.label` for `RuleStatus` and `ModelStatus`.
5. `AppButton`:
   - Hover uses a `MouseRegion`, as an internal hover flag, and shows the hover colors in the issue's table.
   - When `onPressed == null`, the button is wrapped in `Opacity(opacity: 0.4)`, ignores taps and hover, and shows `SystemMouseCursors.basic`. When enabled, it shows `SystemMouseCursors.click`.
   - `expand: true` makes it full width.
   - The icon is 16 px, with an 8 px gap before the label.
6. `AppTextField`:
   - It has a label above the field, with a 4 px gap.
   - The field is 44 high, with a decoration the test can read: a `DecoratedBox` or `Container` with a `BoxDecoration`.
   - Focused: border 1.5 `AppColors.borderFocus` and `boxShadow: AppShadows.focusRing`.
   - `errorText`: border 1 `AppColors.statusBlock`, and the message below the field in `caption` `statusBlock`, with a 4 px gap.
   - All the issue's parameters are passed through to the inner `TextField`. When the widget is given no controller, it owns its own `FocusNode` and controller and disposes them.
7. `AppToggle`:
   - The knob animates over 150 ms (for example with `AnimatedAlign` or `AnimatedPositioned`).
   - Tapping calls `onChanged(!value)`. With `onChanged == null`, tapping does nothing.
   - The toggle is wrapped in `Semantics(toggled: value)`.
8. `AppTabBar` renders one `AppTab` per label, with a 16 px gap between them and a 1 px `borderDefault` bottom border across the full width. Tapping tab `i` calls `onSelected(i)`. Only the active tab has the 2 px `bgInverse` bottom border.
9. `AppSegmentedControl<T>`: tapping an option calls `onChanged` with that option's `T`. With `onChanged == null`, it renders the same way and ignores taps.
10. `OptionCard` uses the three color sets (not selected, selected, selected + `danger`), takes its width from its parent, and calls `onTap` when tapped.
11. Shared widgets are pure presentation:
    - None of the new files under `lib/widgets/` references `AppScope`, `AppStore` or `Navigator`, or imports `lib/app/` or `lib/data/app_store.dart`.
    - The only internal state is visual (hover, focus, and an owned controller or focus node).
    - Every public widget has a doc comment that describes its parameters, including what a `null` callback means.
12. Add one test file per widget file under `test/widgets/`: `app_button_test.dart`, `app_text_field_test.dart`, `verdict_badge_test.dart`, `rule_status_badge_test.dart`, `status_pill_test.dart`, `app_avatar_test.dart`, `app_toggle_test.dart`, `app_tab_test.dart`, `segmented_control_test.dart` and `option_card_test.dart`.
    - Every test pumps through `harness()` and calls `setDesktopView()`.
    - Tests import the widgets through `package:monedasegura_app/widgets/widgets.dart`.
    - Hover tests use `tester.createGesture(kind: PointerDeviceKind.mouse)`.
13. AGENTS.md, section "This repo (monedasegura-app)": add a bullet that says shared components live in `lib/widgets/`, one public widget per file, exported from `lib/widgets/widgets.dart`, and are pure presentation (parameters in, callbacks out, never `AppScope` or `AppStore`).

## Acceptance criteria
1. **AppButton.** `test/widgets/app_button_test.dart` passes (`flutter test test/widgets/app_button_test.dart`). It asserts that:
   - for each of the four variants, the label renders and the `BoxDecoration` color and border, plus the label color, match the issue's Default column;
   - hovering the primary button with a mouse gesture changes its background to `AppColors.bgInverse`;
   - tapping an enabled button calls `onPressed`;
   - with `onPressed: null`, tapping does nothing and an ancestor `Opacity` has `opacity == 0.4`.
2. **AppTextField.** `test/widgets/app_text_field_test.dart` passes. It asserts that:
   - the label and hint texts show;
   - after tapping the field, the decoration border is width 1.5 in `AppColors.borderFocus` and `boxShadow == AppShadows.focusRing`;
   - with `errorText: 'X'`, the text 'X' shows in color `AppColors.statusBlock`;
   - `enterText` calls `onChanged` with the typed value.
3. **Badges and pill.** `test/widgets/verdict_badge_test.dart`, `rule_status_badge_test.dart` and `status_pill_test.dart` pass. They assert that:
   - `VerdictBadge` shows "Aprobada", "En revisión" and "Bloqueada", and `VerdictBadge.degraded()` shows "Degradada", each with its text color from the issue;
   - `RuleStatusBadge` shows "Borrador", "Shadow", "Pendiente", "Activa" and "Retirada";
   - `StatusPill.model` shows "Activo", "Candidato" and "Retirado".
4. **AppAvatar.** `test/widgets/app_avatar_test.dart` passes. It asserts that `AppAvatar(initials: 'VR')` shows "VR", that `tester.getSize` of the avatar is 32 x 32, and that the decoration shape is a circle.
5. **AppToggle.** `test/widgets/app_toggle_test.dart` passes. It asserts that:
   - tapping calls `onChanged` with `!value`;
   - after the animation settles, the knob's center x relative to the track is 26 when `value: true` and 10 when `value: false`.
6. **AppTabBar.** `test/widgets/app_tab_test.dart` passes. It asserts that with 3 labels, tapping the third calls `onSelected(2)`, and that only the selected tab's decoration has a 2 px bottom border.
7. **AppSegmentedControl.** `test/widgets/segmented_control_test.dart` passes. It asserts that tapping an option calls `onChanged` with that option's value, and that with `onChanged: null` tapping does not throw and nothing changes.
8. **OptionCard.** `test/widgets/option_card_test.dart` passes. It asserts the background, border and title colors for not selected, selected, and selected + `danger`, and that tapping calls `onTap`.
9. **Structure.**
   - `ls lib/widgets` lists exactly the ten files of requirement 1 plus `widgets.dart`.
   - `grep -c "export" lib/widgets/widgets.dart` is 10.
   - `grep -rnE "AppScope|AppStore" lib/widgets` prints nothing.
10. **Tokens only.** `grep -rnE "Color\(0x|fontSize:" lib/widgets` prints nothing, and `grep -rn "lucide" lib/widgets` prints nothing.
11. **Docs.** AGENTS.md contains a bullet that mentions `lib/widgets/widgets.dart`.

## Out of scope
- Data-display widgets (the next task), rows (case, rule, condition), sidebar, top bar, cards, page frames, screens and dropdown menus.
- Using the new widgets in `lib/login_screen.dart` or any other existing screen.
- Changing `lib/data/` or `lib/app/`, or anything from the archive tag's `models.dart`, `mock_data.dart` or `prototype_labels.dart`.
- Adding variants, sizes or parameters beyond the signatures in issue #13. Examples: loading states on the button, a prefix or suffix on the text field, a disabled toggle style.
- New color tokens. Every color already exists in `AppColors`. Only add a token in `lib/theme/` if a value truly has none, and do it the existing way.
- Editing `factory/checks.sh` or `factory/config.json`.

## Assumptions
- **The tab file holds two widgets, and the barrel exports ten files.** `AppTab` and `AppTabBar` share `app_tab.dart` because the issue names that file for both.
- **The danger hover uses `AppColors.statusBlock.withValues(alpha: 0.88)`** rather than a new token. The issue defines it as "same at 88 % opacity", which is a derivation, not a new color.
- **Fixed component dimensions can be numeric values in the widget file.** The repo's rule bans hex colors, font sizes and icons outside the theme, not geometry, and `lib/theme/` has no size tokens.
- **A disabled `AppToggle` (`onChanged == null`) only ignores taps** and has no special look. The issue defines no disabled style, and the "null means disabled" convention covers the behaviour.
- **AppTextField gets its own internal `FocusNode`** to drive the focus styling. The issue's signature has no focus-node parameter, and focus is the visual state widgets are allowed to keep.
- **One test file per widget file**, so the badges get two files and the tabs one. The issue asks for "one test file per widget under `test/widgets/`".
