# Data-display and feedback gallery widgets

> Issue #14: Build the data-display and feedback gallery widgets

## Summary
- Add 12 presentation-only gallery widgets to `lib/widgets/`, one per file (`StepperStep` and `AppStepper` share a file), all exported from `widgets.dart`.
- Each one copies the existing shared-widget pattern (`status_pill.dart`, `app_avatar.dart`): it takes its values through the constructor, styles itself only with `lib/theme/` tokens and has a doc comment.
- The stepper enum is named `StepperStepState`, because Flutter's `material.dart` already exports a `StepState` enum.
- `AppRadius.xs = 4` is added to the theme so `FeatureBar` can use the 4 px radius without hard-coding it.
- Widget tests under `test/widgets/` cover the issue's acceptance criteria 1 to 7.

## Context
- **Shared widgets** live in `lib/widgets/`, one public widget per file, exported from `lib/widgets/widgets.dart`. That file exports 10 widgets today: `app_avatar`, `app_button`, `app_tab`, `app_text_field`, `app_toggle`, `option_card`, `rule_status_badge`, `segmented_control`, `status_pill` and `verdict_badge`. They import `package:flutter/widgets.dart` and the theme files, and they declare one-off sizes as private `static const double` fields. For example, `StatusPill` has `_dot = 6` and `_gap = 6`, and `OptionCard` has `_minHeight = 64`. Each class has a doc comment that names its Figma node and explains its parameters.
- **Theme tokens:**
  - `lib/theme/app_colors.dart` has every colour this issue uses:
    - text: `textPrimary #161B26`, `textSecondary #545B69`, `textTertiary #8B919D`, `textInverse #FFFFFF`
    - accent: `accent #2B59C3`, `accentSubtle #E8EEFA`
    - backgrounds: `bgInverse #14213D`, `bgSurface #FFFFFF`, `bgCanvas #F3F4F6`, `bgSubtle #E9EBEF`
    - borders: `borderDefault #DFE2E8`, `borderStrong #C5CAD3`
    - status: `statusApprove #2F7D55`, `statusReview #B86E00`, `statusReviewBg #FBF0DC`, `statusBlock #B42318`
    - dark cards: `onInverseTile`, `onInverseBorder`, `onInverseMuted`, `onInverseDelta #8CD9B2`
  - `lib/theme/app_text_styles.dart` has `metric`, `title`, `body`, `bodyStrong`, `caption` and `badge`.
  - `lib/theme/app_spacing.dart` holds `AppSpacing` (xxs 2, xs 4, sm 8, md 12, lg 16, xl 24), `AppRadius` (sm 6, md 10, lg 14, full 999) and `AppShadows`. There is no 4 px radius token yet.
  - `lib/theme/app_icons.dart` has `AppIcons.check`.
- **Formatting:** `lib/data/format.dart` has `formatScore(double?)`. It returns `—` for null and a 2-digit comma decimal otherwise (`0,67`).
- **Tests:** existing tests are in `test/widgets/<widget>_test.dart` (for example `status_pill_test.dart`). They call `setDesktopView(tester)` and pump through `harness(...)` from `test/helpers/harness.dart`. They check text colour with `tester.widget<Text>(find.text(..)).style?.color`.
- **Reference code:** the tag `archive/pr-29-flutter-prototype` has earlier versions (`lib/widgets/score_bar.dart`, `kpi_card.dart`, `data_display.dart`, `progress_feedback.dart`, and `test/widgets/shared_widgets_test.dart`). They use `MsColors` and `tokens.dart`, which don't exist here. Builders may adapt their structure, but this spec's values win.
- **Name clash:** Flutter's `package:flutter/material.dart` exports `StepState` (used by Material's `Stepper`).

## Requirements
1. Create these files under `lib/widgets/`. Each holds the public widget named and uses exactly the constructor signature, layout and values in issue #14:
   - `kpi_card.dart`: `KpiCard`
   - `score_bar.dart`: `ScoreBar`
   - `detail_field.dart`: `DetailField`
   - `stat_tile.dart`: `StatTile`
   - `metric_tile.dart`: `MetricTile`
   - `feature_bar.dart`: `FeatureBar`
   - `signal_chip.dart`: `SignalChip`
   - `legend_item.dart`: `LegendItem`
   - `stepper_step.dart`: `StepperStepState`, `StepperStep` and `AppStepper`
   - `timeline_event.dart`: `TimelineEvent`
   - `app_banner.dart`: `AppBanner`
   - `empty_state.dart`: `EmptyState`
2. Add every new file to `lib/widgets/widgets.dart`, keeping the export list in alphabetical order.
3. The stepper enum is `enum StepperStepState { done, current, pending }`, not `StepState`. `StepperStep` takes `required StepperStepState state`, and `AppStepper` takes `required List<(String, StepperStepState)> steps`.
4. `ScoreBar` behaviour:
   - The track is 64 x 6 with a full radius, in `AppColors.bgSubtle`. The fill is left-aligned and `score * 64` px wide (8 px when the score is null), with the score clamped to 0 to 1.
   - The fill colour and the text colour are the same and depend on the score:
     - below 0.6: `statusApprove`
     - 0.6 up to (but not including) 0.9: `statusReview`
     - 0.9 and above: `statusBlock`
     - null: `statusApprove`
   - The text is `formatScore(score) + suffix`, in the `badge` style. There is an 8 px gap between the track and the text.
5. `FeatureBar`: the fill width is `fraction.clamp(0, 1)` times the track width. The track takes the parent's width, so use `FractionallySizedBox` or `LayoutBuilder`. The track and the fill are 8 high with a 4 px radius.
6. `AppStepper`:
   - Shows the steps in a row with an 8 px gap on each side of a 28 x 1.5 connector between consecutive steps.
   - Connector `i` (between step `i` and step `i+1`) is `AppColors.bgInverse` when step `i` is `done`, and `AppColors.borderStrong` otherwise.
   - A `done` step shows a 12 px `AppIcons.check` icon in `AppColors.textInverse` on a 20 px `bgInverse` circle.
7. `MetricTile(onInverse: true)` uses these colours:
   - background `onInverseTile` with a 1 px `onInverseBorder` border
   - label `onInverseMuted`
   - value `textInverse`
   - note `onInverseDelta`

   With `onInverse: false` it looks like `StatTile` (`bgCanvas`, label and note `textSecondary`, value `textPrimary`).
8. Add `static const double xs = 4;` to `AppRadius` in `lib/theme/app_spacing.dart` and use it for the `FeatureBar` radii. Map every other radius to an existing token: 14 is `lg`, 10 is `md`, 6 is `sm`, and "full" is `full`.
9. Write no hex colour or font size outside `lib/theme/`. One-off dimensions not in the spacing or radius scale (64, 6, 20, 12, 28, 1.5, 48, 10, the 6 px `FeatureBar` gap, and the 1.5 border) are private `static const double` fields on the widget, as `StatusPill` does.
10. The widgets are pure presentation. They take no callbacks and keep no state (they are `StatelessWidget`s), and they never reference `AppScope`, `AppStore`, navigation or `lib/data/models/`. They only import `lib/data/format.dart`, and only `ScoreBar` needs it.
11. Every public widget and the enum have a doc comment that names the Figma node id from the issue and describes each parameter.
12. Add widget tests under `test/widgets/`, one `<file>_test.dart` per new widget file, using `setDesktopView` and `harness()`. They cover the acceptance criteria below.

## Acceptance criteria
1. **KpiCard.** `KpiCard(label: 'Transacciones hoy', value: '12.480', delta: '+8,2 % vs. ayer', deltaColor: AppColors.accent)` shows all three texts, and the delta `Text` has style colour `AppColors.accent`. Verify in `test/widgets/kpi_card_test.dart`.
2. **ScoreBar.** Verify each case in `test/widgets/score_bar_test.dart`:
   - `ScoreBar(score: 0.67)` shows `0,67` in `AppColors.statusReview`, and the fill is about 43 px wide (`tester.getSize` within 1 px of 42.88).
   - `score: 0.96` shows its text in `AppColors.statusBlock`.
   - `score: 0.3` shows its text in `AppColors.statusApprove`.
   - `score: null` shows `—`.
   - `ScoreBar(score: 0.67, suffix: ' · modelo v5')` shows `0,67 · modelo v5`.
3. **Text colours.** Each widget shows its texts in these colours. Verify each in its own test file.
   - `DetailField`: label `textSecondary`, value `textPrimary`.
   - `StatTile`: label `textSecondary`, value in the given `valueColor`, which defaults to `textPrimary`.
   - `MetricTile`, default mode: label and note `textSecondary`, value `textPrimary`.
   - `MetricTile(onInverse: true)`: label `onInverseMuted`, value `textInverse`, note `onInverseDelta`.
   - `SignalChip`: text `textSecondary`.
   - `LegendItem`: label `textSecondary`, and a dot `Container` decorated with the given colour.
4. **FeatureBar.** `FeatureBar(label: .., valueLabel: .., fraction: 0.5)` in a fixed-width parent draws a fill whose width is half the track's (`tester.getSize`). Verify in `test/widgets/feature_bar_test.dart`.
5. **AppStepper.** `AppStepper` with four steps (done, done, current, pending) shows exactly two `Icon`s with `AppIcons.check` in `AppColors.textInverse`. Of its three connectors, the first two are `AppColors.bgInverse` and the third is `AppColors.borderStrong`. Verify in `test/widgets/stepper_step_test.dart`.
6. **AppBanner and EmptyState.** `AppBanner(message: 'x', leading: Text('L'))` shows both `x` and `L`, and the message colour is `AppColors.accent`. `EmptyState(icon: AppIcons.inbox, title: .., hint: ..)` shows its title and hint. Verify in `test/widgets/app_banner_test.dart` and `test/widgets/empty_state_test.dart`.
7. **TimelineEvent.** `TimelineEvent(title: .., meta: ..)` shows the title in `textPrimary` and the meta in `textSecondary`. Verify in `test/widgets/timeline_event_test.dart`.
8. **Exports.** `grep -c "^export" lib/widgets/widgets.dart` returns 22. Every one of the 12 new files appears in that file.
9. **No store access.** Running the following prints nothing:
   ```bash
   grep -lE "AppScope|AppStore" lib/widgets/kpi_card.dart lib/widgets/score_bar.dart lib/widgets/detail_field.dart lib/widgets/stat_tile.dart lib/widgets/metric_tile.dart lib/widgets/feature_bar.dart lib/widgets/signal_chip.dart lib/widgets/legend_item.dart lib/widgets/stepper_step.dart lib/widgets/timeline_event.dart lib/widgets/app_banner.dart lib/widgets/empty_state.dart
   ```
10. **No hard-coded colours or font sizes.** `grep -nE "Color\(0x|fontSize" <the 12 new files>` prints nothing.
11. **No `StepState` name.** `grep -n "StepState\b" lib/widgets/stepper_step.dart` prints only matches of `StepperStepState`. No file declares `enum StepState`.
12. **Radius token.** `lib/theme/app_spacing.dart` contains `static const double xs = 4;` inside `AppRadius`.

## Out of scope
- Composite rows (case row, rule row, condition row), charts and screens. Don't use any new widget in a screen yet.
- A wrapper card widget (such as the archived `ms_card.dart`) or table parts (`table_parts.dart`) from the archive tag.
- Changing existing widgets or their tests, or any theme token other than the one `AppRadius.xs` addition.
- Callbacks, hover or tap behaviour, animations or extra constructor options the issue doesn't list.
- `lib/data/models.dart`, `mock_data.dart`, `prototype_labels.dart` or `tokens.dart` from the archive tag.
- `factory/checks.sh` and `factory/config.json` (protected).

## Assumptions
- **Enum name `StepperStepState`.** It avoids the clash with Flutter's `StepState`, as intake asked, and keeps the issue's three values.
- **New `AppRadius.xs = 4` token.** The issue requires radii from `lib/theme/`, and 4 is not in the scale. One token is the smallest fix.
- **One-off sizes as private constants.** Sizes such as 64, 6, 20, 28, 1.5 and 48 become private constants, not theme tokens. This follows the existing `StatusPill` and `OptionCard` pattern, and the rule only bans hex colours and font sizes.
- **ScoreBar clamps the score to 0 to 1.** This keeps the fill inside the track. The issue gives no behaviour for out-of-range values.
- **Null ScoreBar uses the Low colour.** The issue says so explicitly, even though the archived code used the tertiary colour.
- **No AGENTS.md change.** It already describes the `lib/widgets/` convention, and the new widgets add no new rule.
- **One test file per widget file.** This matches the existing `test/widgets/` layout. The archive's single `shared_widgets_test.dart` is not reused.
