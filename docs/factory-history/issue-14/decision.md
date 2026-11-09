ESCALATE

## Summary
- Adds 12 presentation-only gallery widgets from issue #14 under `lib/widgets/`, each in its own file (`StepperStep` and `AppStepper` share one), all exported from `widgets.dart` (22 exports).
- Adds one theme token, `AppRadius.xs = 4`, for the `FeatureBar` radii. The spec asked for it.
- The round 1 gate passed at HEAD `e57fdcf` (200 tests, analyze clean, web build OK). All three reviews (code, UI, UX) are PASS with no findings.
- No high-risk area is touched: no auth, JWT, permissions, migrations, env vars, CI, docker-compose, dependencies or contract changes.
- Escalated only because a person always merges in this project. Recommendation: merge.

## Why
Every acceptance criterion in the spec is met, and build.md and the tests show it. I re-checked several myself: ScoreBar thresholds and fill, the AppStepper connector rule, the export count, and the store and hex greps. The change stays inside intake's Scope: 26 files, all new widgets and tests, plus the one radius token the spec named. The review Notes describe things to handle later, not defects in this PR: a possible `FeatureBar` label overflow, the `AppStepper` row overflowing on a phone, contrast values the issue itself sets, and a few untested clamp cases.

## Acceptance criteria
1. KpiCard texts and delta colour `accent`: met. `kpi_card_test.dart` passes in the gate.
2. ScoreBar: met. I read `score_bar.dart`: the score is clamped, the colour switch is <0.6 / <0.9 / else with null as Low, the null fill is 8 px and the text is `formatScore(score) + suffix`. `score_bar_test.dart` checks a fill of 42.88 ±1 and the amber, red and green colours, null showing `—`, and the suffix text.
3. Text colours of DetailField, StatTile, MetricTile (both modes), SignalChip and LegendItem: met. Each has its own test file, and all pass.
4. FeatureBar fill is half the track: met. `feature_bar_test.dart` uses a 300 px parent, and `FractionallySizedBox` uses the clamped fraction.
5. AppStepper: met. I read `stepper_step.dart`: connector `i` is `bgInverse` when step `i` is done, otherwise `borderStrong`, and a done step shows a 12 px `AppIcons.check` in `textInverse`. The test checks for two icons and the connector colours `[bgInverse, bgInverse, borderStrong]`.
6. AppBanner and EmptyState: met. Both tests pass, and the banner message is in `accent`.
7. TimelineEvent title and meta colours: met. `timeline_event_test.dart` passes.
8. Exports: met. I ran `grep -c "^export"` and it returned 22. All 12 new files are listed in alphabetical order.
9. No `AppScope`/`AppStore`: met. I ran the grep on the 12 files and it found nothing.
10. No `Color(0x` or `fontSize` in the 12 files: met. I ran the grep and it found nothing.
11. No bare `StepState`: met. The enum is `StepperStepState`, and build.md shows the grep came back clean.
12. `AppRadius.xs = 4`: met. It is in the diff of `lib/theme/app_spacing.dart`.

## For the human
Recommendation: merge

- This is a self-contained UI-only change. It touches no contract, data model, feature catalog, migration, env var, `docker-compose.yml`, JWT, permissions, scoring token or simulator access rule.
- What I'd like from you: confirm you're fine with the new `AppRadius.xs = 4` theme token. It is a small addition the spec chose so the 4 px radius wouldn't be hard-coded. Optionally, run `flutter test test/widgets` locally.
- Follow-ups for the screens that will use these widgets, not blockers:
  - `FeatureBar`: wrap the label in `Expanded` so a long label doesn't overflow.
  - `AppStepper`: wrap it in a horizontal scroll view on narrow screens.
  - The issue sets two caption colours that fall below WCAG AA contrast: `textTertiary` for the pending step and `statusReview` for the mid score. The designer may want to revisit them.
- Files to look at:
  - `lib/widgets/score_bar.dart`
  - `lib/widgets/stepper_step.dart`
  - `lib/widgets/metric_tile.dart`
  - `lib/widgets/feature_bar.dart`
  - `lib/theme/app_spacing.dart`
  - `lib/widgets/widgets.dart`
