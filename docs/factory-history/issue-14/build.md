STATUS: READY

# Build: Data-display and feedback gallery widgets

## Summary
- Adds 12 presentation-only gallery widgets in `lib/widgets/` (one file each; `StepperStep` and `AppStepper` share one), all exported from `widgets.dart` (22 exports now).
- The stepper enum is `StepperStepState { done, current, pending }`, so it doesn't clash with Material's `StepState`.
- Adds `AppRadius.xs = 4` for the `FeatureBar` radii. All other values come from theme tokens or private `static const double` fields.
- One widget test file per new widget covers acceptance criteria 1 to 7. `factory/checks.sh` passes (200 tests).
- Draft PR #38 is open.

## Changes
- `lib/theme/app_spacing.dart`: adds `AppRadius.xs = 4`.
- `lib/widgets/kpi_card.dart`: `KpiCard`. White card with a 1 px `borderDefault` border, radius `lg`, padding `xl`, 8 px gaps. Caption label, `metric` value, `badge` delta in `deltaColor`.
- `lib/widgets/score_bar.dart`: `ScoreBar`. 64 x 6 `bgSubtle` track with a left-aligned fill `clamp(score) * 64` wide (8 when the score is null). The fill and text colour is green below 0.6 and for null, amber from 0.6 to below 0.9, and red from 0.9. Text is `formatScore(score) + suffix` in `badge`, with an 8 px gap.
- `lib/widgets/detail_field.dart`: `DetailField`. Caption label and `bodyStrong` value, 2 px gap.
- `lib/widgets/stat_tile.dart`: `StatTile`. `bgCanvas` background, radius `md`, padding 16/12. Caption label and `title` value in `valueColor`.
- `lib/widgets/metric_tile.dart`: `MetricTile`. `StatTile` plus a `badge` note. `onInverse` switches to `onInverseTile` with a 1 px `onInverseBorder` border, and uses `onInverseMuted`, `textInverse` and `onInverseDelta` for the three lines.
- `lib/widgets/feature_bar.dart`: `FeatureBar`. A space-between label row, a 6 px gap, then an 8 px track as wide as the parent. The `accent` fill uses `FractionallySizedBox(widthFactor: fraction.clamp(0, 1))`. Both use radius `AppRadius.xs`.
- `lib/widgets/signal_chip.dart`: `SignalChip`. `bgSubtle` background, radius `sm`, padding 8/4, caption in `textSecondary`.
- `lib/widgets/legend_item.dart`: `LegendItem`. An 8 px dot in `color`, a 4 px gap, then the caption label.
- `lib/widgets/stepper_step.dart`:
  - `StepperStepState`.
  - `StepperStep`: a 20 px circle that depends on the state. Done is `bgInverse` with a 12 px `AppIcons.check` in `textInverse`. Current is `statusReviewBg` with a 1.5 px `statusReview` border. Pending is `bgSurface` with a 1 px `borderStrong` border. The label is `textPrimary`, or `textTertiary` when pending.
  - `AppStepper`: steps joined by 28 x 1.5 connectors with 8 px on each side. A connector is `bgInverse` when the step before it is done, otherwise `borderStrong`.
- `lib/widgets/timeline_event.dart`: `TimelineEvent`. A 10 px `bgInverse` dot with its centre 10 px from the top, a 12 px gap, then a `bodyStrong` title and a caption meta line.
- `lib/widgets/app_banner.dart`: `AppBanner`. `accentSubtle` background, radius `md`, padding 12/8. Optional `leading`, an 8 px gap, then the caption message in `accent`.
- `lib/widgets/empty_state.dart`: `EmptyState`. A 48 px `bgSubtle` circle holding a 20 px icon in `textSecondary`, then a `bodyStrong` title and a centred caption hint, with 8 px gaps.
- `lib/widgets/widgets.dart`: exports the 12 new files, in alphabetical order.
- `test/widgets/{kpi_card,score_bar,detail_field,stat_tile,metric_tile,feature_bar,signal_chip,legend_item,stepper_step,timeline_event,app_banner,empty_state}_test.dart`: widget tests. Each one uses `setDesktopView` and `harness()`.

## Acceptance criteria
1. [x] KpiCard: `kpi_card_test.dart` finds all three texts, and the delta `Text` colour is `AppColors.accent`. Passes.
2. [x] ScoreBar: `score_bar_test.dart` passes. It checks that 0.67 shows `0,67` in `statusReview` with a fill within 1 px of 42.88, 0.96 is `statusBlock`, 0.3 (`0,30`) is `statusApprove`, null shows `—`, and the suffix gives `0,67 · modelo v5`.
3. [x] Text colours: these tests pass:
   - `detail_field_test.dart`
   - `stat_tile_test.dart` (default and custom `valueColor`)
   - `metric_tile_test.dart` (both modes, plus the inverse background and border)
   - `signal_chip_test.dart`
   - `legend_item_test.dart` (label colour, and a dot `Container` decorated with the given colour)
4. [x] FeatureBar: `feature_bar_test.dart` uses a parent 300 px wide. The track is 300 wide and the fill is exactly half of it. Passes.
5. [x] AppStepper: `stepper_step_test.dart` passes. It finds exactly two `Icon`s, both `AppIcons.check` in `textInverse`. The connector colours are `[bgInverse, bgInverse, borderStrong]`.
6. [x] AppBanner and EmptyState: `app_banner_test.dart` shows `x` (in `accent`) and `L`. `empty_state_test.dart` shows the title, the hint and the icon. Both pass.
7. [x] TimelineEvent: `timeline_event_test.dart` shows the title in `textPrimary` and the meta in `textSecondary`. Passes.
8. [x] Exports: `grep -c "^export" lib/widgets/widgets.dart` prints 22, and a loop confirms each of the 12 new files is listed.
9. [x] No store access: the `grep -lE "AppScope|AppStore" <12 files>` command printed nothing.
10. [x] No hard-coded colours or font sizes: `grep -nE "Color\(0x|fontSize" <12 files>` printed nothing.
11. [x] No `StepState` name: `grep -n "StepState\b" lib/widgets/stepper_step.dart | grep -v StepperStepState` printed nothing, and `grep -rn "enum StepState" lib test` printed nothing.
12. [x] Radius token: `lib/theme/app_spacing.dart` line 17 is `static const double xs = 4;` inside `AppRadius`.

Also checked: the only import in the new files outside `flutter/widgets.dart` and `lib/theme/` is `../data/format.dart`, in `score_bar.dart`.

## Validation
- `bash /home/mrjj/ms/monedasegura-app/factory/checks.sh` (pub get, format check, analyze, test, web build) passed with exit 0 after the final commit: no analyzer issues, 200 tests passed, `build/web` built.
- `dart format lib test` reformatted only the new `metric_tile.dart`.
- `flutter test test/widgets`: 42 tests passed.

## Log
### Round 1
- Ran `flutter pub get` and read the spec, the issue, the existing widgets (`status_pill`, `option_card`, `rule_status_badge`) and the archived `progress_feedback.dart`.
- Added `AppRadius.xs`, the 12 widget files and the 12 test files, and updated the exports.
- Changed the stepper doc comment so it no longer names the bare Material enum, which made criterion 11 fail.
- Committed in two commits (`Add a 4 px radius token`, `Add the data-display and feedback gallery widgets`), pushed the branch and opened draft PR #38.
