STATUS: READY

# Build: Models screen with retraining

## Summary
- `ModelsScreen` is now a stateful host over a new stateless `ModelsPage`. The page shows the production model with deltas, the thresholds, the version table and the feature importance.
- "Reentrenar ahora" only shows with `MODEL_TRAIN`. It calls `retrainNow()` and shows a Spanish SnackBar for each outcome, including `DomainError`.
- `TableHeaderRow` gets optional `height` / `horizontalPadding` / `radius`, with unchanged defaults. In the versions table, "Versión" stretches instead of a fixed 148, so the table fits at 1440 x 900 (see the deviation below).
- Round 2: the threshold ticks "0,60" and "0,90" now sit under the segment boundaries they name, not spread evenly.
- A new `loadInterFont()` test helper lets tests that open the models screen measure text with Inter.

## Changes
- `lib/screens/models/models_screen.dart`: a `StatefulWidget` host. It reads `AppScope.of` once (models, activeModel, scoreThresholds, now, can(MODEL_TRAIN)) and renders `AppShell(title: 'Modelos', subtitle: 'Modelo de scoring · LightGBM')`. `_retrain` calls `AppScope.read(context).retrainNow()`. It then shows "{v} entrenado y activado." or "{v} quedó como candidato: no pasó el control de calidad.", or "No se pudo reentrenar: no hay un modelo activo." when a `DomainError` is caught.
- `lib/screens/models/models_page.dart` (new): `ModelsPage` with private `_ProductionCard`, `_ThresholdsCard`, `_ThresholdRow`, `_VersionsCard`, `_FeatureCard` and `_CardTitle`. The baseline is the latest RETIRED version trained before the active one. Decimal deltas are rounded to 2 places before the sign is chosen, and the note is "—" when there is no baseline. Sizes with no token are named `static const double` fields. The threshold ticks are a `Stack`: "0" and "1" sit at the ends in a space-between row, and each threshold is an `Align` at `Alignment(fraction * 2 - 1, 0)`, so it sits under its boundary.
- `lib/widgets/table_header.dart`: adds optional `height` (40), `horizontalPadding` (`AppSpacing.xl`) and `radius` (0), and documents them in the doc comment. The colour moved into a `BoxDecoration` so the radius can apply.
- `test/widgets/table_header_test.dart`: new test for the 30 px height, the 12 px padding and the `AppRadius.sm` radius.
- `test/screens/models_test.dart` (new): 11 tests covering the criteria below, plus the tick positions.
- `test/helpers/harness.dart`: adds `loadInterFont()`, the same loader `rule_row_test.dart` already uses inline.
- `test/screens/dashboard_test.dart`, `test/app/navigation_test.dart`: add `setUpAll(loadInterFont)`. Both open the models screen, and the default test font draws every glyph as a square, which overflows the shared `StatusPill` and `FeatureBar` in their fixed cells. No assertions changed.

### Deviation from the spec
The spec gives the versions table fixed column widths of 148/130/150/70/70/110 and the `TableHeaderRow` gap of 16 between columns. The left card's table area at 1440 px is 680 px wide (1440 − 240 sidebar − 64 padding − 360 − 24 − 48 card padding − 24 row padding). The fixed widths plus five 16 px gaps need 758 px, which would overflow and break requirement 4. The Figma widths add up to about 680 because the design has no gaps. So "Versión" uses `TableHeaderCell(flex: true)` in the header and `Expanded` in the rows: it takes the space left over, about 70 px. The other five widths are exactly as specified, and no shared-widget API was added beyond the spec.

## Acceptance criteria
1. [x] Laura Cárdenas at /models sees all the production texts and deltas: test "shows the production model and its deltas" passes ("+0,02 vs. anterior" found exactly twice, display "v5" found once).
2. [x] Thresholds legend and ticks: test "shows the decision thresholds" passes. Test "ModelsPage places the threshold ticks at their positions" checks that the centres of "0,60" and "0,90" sit at 60 % and 90 % of the scale, within half the label width. This test fails on the round 1 layout.
3. [x] Versions table (v5 above v1, "25 oct · 02:00", "Manual · Laura C.", "Candidato", "Retirado" ×3) and the six feature labels with 100 %, 78 % and 27 %: test "shows the versions table and the feature importance" passes.
4. [x] Retraining: v6 above v5, "Activo" ×2, "Retirado" ×4, display text "v6" (no display "v5"), snackbar "v6 entrenado y activado.": test "retraining adds v6 as the active model" passes.
5. [x] Camilo Torres sees "Modelos" and no "Reentrenar ahora": test "hides retraining without MODEL_TRAIN" passes.
6. [x] SCORE_REVIEW set to `score >= 0.5` through the full lifecycle (Laura Méndez creates, shadows, backtests and submits; Diego approves) shows "< 0,50", "0,50 – 0,90" and the tick "0,50": test "reads the thresholds from the active score rules" passes.
7. [x] `grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files (case_queue, models, case_detail, dashboard, login). `models_page.dart` has no match.
8. [x] Page-alone test with fake data and a recording callback: "ModelsPage reports the retrain tap once" passes, taps == 1. It also checks the negative deltas "-0,03" and "-50".
9. [x] `onRetrain: null` shows no button: "ModelsPage hides the retrain button without a callback" passes.
10. [x] `activeModel: null` shows "Sin modelo activo" ×2, the hint, no "vs. anterior", no `FeatureBar` and no `MetricTile`: "ModelsPage shows the empty production and feature cards" passes.
11. [x] No earlier RETIRED version gives "—" ×4: "ModelsPage shows a dash without an earlier retired version" passes.
12. [x] `test/widgets/table_header_test.dart` "takes the given height, padding and radius" passes (height 30). The existing table header test and the case queue tests pass unchanged.
13. [x] `grep -rn "Color(0x\|fontSize" lib/screens/models/` returns nothing.

## Validation
- `dart format` on the changed files only: clean.
- `flutter analyze`: no issues.
- `flutter test test/screens/models_test.dart test/widgets/table_header_test.dart`: all passed.
- `bash /home/mrjj/ms/monedasegura-app/factory/checks.sh` (round 2): exit 0 (format clean, analyze clean, 348 tests passed, web build ok).
- UI checked by widget tests at 1440 x 900 with Inter loaded, as AGENTS.md asks (no browser tool for Flutter web). The full-app tests raised no overflow exceptions.

## Log
### Round 1
- Started from a clean branch with no earlier build.md or commits. Ran `flutter pub get`.
- Added the `TableHeaderRow` sizing parameters and their test, built the models screen and page, and wrote `models_test.dart`.
- With the default test font, the shared `StatusPill` and `FeatureBar` overflowed their fixed cells, which broke the navigation and dashboard tests that open /models. Following the `rule_row_test.dart` precedent, I added a shared `loadInterFont()` helper and used it in those tests.
- Made "Versión" the flex column so the table fits at 1440 px (see the deviation above).
- Commits: "Add sizing parameters to TableHeaderRow", "Build the models screen and page", "Test the models screen and page". Pushed and opened draft PR #48.

### Round 2
- review-ui.md (CHANGES), finding 1: the ticks were spread evenly, so "0,60" and "0,90" did not sit under their boundaries. I replaced the space-between tick row with a `Stack`. "0" and "1" stay at the ends, and each threshold is an `Align` at `Alignment(fraction * 2 - 1, 0)`, with the same text and style. I added a page-alone test for the positions, confirmed it fails without the fix, and ran checks.sh (exit 0). Commit "Place the threshold ticks at their proportional positions", pushed to PR #48.
- review-ui notes (28 px padding vs the dashboard card, the green "—" note on inverse tiles, the flexible "Versión" column, the button centring): optional, and they follow the spec or shared widgets, so I changed nothing. review-code.md and review-ux.md: PASS, nothing to address.
- The spec still says "a space-between row" for the ticks; the reviewer's fix follows the issue's intent (ticks at the thresholds).
