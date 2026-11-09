DECISION: ACCEPT
RISK: low
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: 12 presentation-only gallery widgets with widget tests.
- Both dependencies (#10 theme, #11 basic gallery) are merged on `develop`. The tokens this issue names (`onInverse*`, `AppTextStyles.metric`, `AppIcons.check`, `formatScore`) already exist.
- The widgets hold no state, use no store and make no API calls, so the work is contained and easy to check with widget tests.
- One naming note for the spec: `StepState` clashes with Flutter's own `StepState` enum.

## Scope
Build each widget the issue lists as one public widget in its own file under `lib/widgets/`, exported from `lib/widgets/widgets.dart`, with the constructors, colours, sizes and behaviour the issue gives:
`KpiCard`, `ScoreBar`, `DetailField`, `StatTile`, `MetricTile` (normal and `onInverse`), `FeatureBar`, `SignalChip`, `LegendItem`, `StepperStep` + `AppStepper` (same file), `TimelineEvent`, `AppBanner`, `EmptyState`.

- `ScoreBar`: the fill is `score * 64` px wide (8 px when the score is null). The colour level is Low < 0.6, Mid 0.6 to under 0.9, High >= 0.9, and null uses the Low colours. The text is `formatScore(score) + suffix`, so null shows `—`.
- `FeatureBar`: the fill is `fraction` (0 to 1) of the track width. Clamp values outside that range.
- `AppStepper`: draws a connector between each pair of steps. It is `#14213D` only when the step before it is done.
- Every value comes from `lib/theme/`, with no hex colours or font sizes in widgets. Every widget gets a doc comment and must not mention `AppScope` or `AppStore`.
- Tests under `test/widgets/` cover acceptance criteria 1 to 7, pumped through `harness()`.
- **`StepState` name clash:** Flutter's `material.dart` already exports a `StepState` enum. Exporting another one from `widgets.dart` would make imports ambiguous in any file that imports both. The spec writer should give the enum a name that doesn't collide (for example `StepperStepState`) and keep the three values `done`, `current` and `pending`. Using `hide` everywhere is not a good alternative.
- The archived PR #29 code (`archive/pr-29-flutter-prototype`) can be reused where it fits. The values in this issue win where they differ.

Left out, as the issue says: composite rows (case, rule, condition), charts and screens.

## Why
This is a self-contained set of presentational widgets that follows the pattern already in `lib/widgets/` (for example `status_pill.dart` and `rule_status_badge.dart`). The theme and format helpers it relies on are in place (`lib/theme/app_colors.dart` has the `onInverse*` tokens, `lib/data/format.dart` has `formatScore` returning `—` for null). It needs no contract or data-model change, and it fits in one reviewable PR.
