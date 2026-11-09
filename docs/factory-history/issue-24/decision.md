ESCALATE

## Summary
- The stub "Modelos" screen is replaced. It now shows the production model with its deltas, the threshold scale, the version table, the feature importance, and "Reentrenar ahora" for users with `MODEL_TRAIN`.
- `TableHeaderRow` gets optional `height`, `horizontalPadding` and `radius` parameters. The defaults are unchanged, and the case queue tests still pass.
- Round 2 fixed the one UI finding from round 1: the threshold ticks now sit under their boundaries. In round 2, the gate passed and all three reviews passed.
- All 13 acceptance criteria are met. I re-ran the models, table header and case queue tests myself (all pass) and repeated the criterion 7 and 13 greps.
- ESCALATE only because a person always merges in this project. My recommendation is merge.

## Why
Every spec criterion is covered by a test, and I confirmed the key ones. The final round has `GATE: PASS` and three `VERDICT: PASS` reviews, and none of their Notes describes a real problem. The change stays inside intake's scope. It touches no auth or JWT handling, migration, environment variable, docker-compose file, CI setting, dependency or `monedasegura-infra/docs` contract. The screen only reads the existing `store.can(MODEL_TRAIN)` to show or hide a button, which is the documented pattern, and it does not change any permission rule.

## Acceptance criteria
1. Production texts and deltas for Laura Cárdenas: met. The test "shows the production model and its deltas" passes.
2. Threshold legend and ticks: met. The legend and tick tests pass. A position test checks that "0,60" and "0,90" sit at 60 % and 90 % of the scale.
3. Version table order, "25 oct · 02:00", "Manual · Laura C.", "Candidato", "Retirado" x3, the six features, and 100 % / 78 % / 27 %: met. The test passes.
4. Retraining gives v6 above v5, "Activo" x2, "Retirado" x4, v6 in the display text and no v5 there, and the snackbar: met. I read the test (models_test.dart lines 172-191), it asserts exactly these, and it passes when I run it.
5. Camilo Torres sees no "Reentrenar ahora": met. The test passes.
6. The thresholds follow a newly approved `SCORE_REVIEW` at 0.5: met. The test passes.
7. Only `*_screen.dart` files use `AppScope`/`AppStore`: met. I re-ran the grep: it matches 5 screen files and not models_page.dart.
8. The page-alone retrain callback fires exactly once: met. The test passes.
9. With `onRetrain: null` there is no button: met. The test passes.
10. The no-active-model empty states show: met. The test passes.
11. With no earlier retired version, the note is "—" x4: met. The test passes.
12. The `TableHeaderRow` sizing test passes, and the existing header and case queue tests are unchanged: met. I re-ran both and they pass.
13. No `Color(0x` or `fontSize` in lib/screens/models/: met. I re-ran the grep and it returns nothing.

## For the human
Recommendation: merge

Nothing blocks this. Please walk through `/models` with `flutter run -d chrome` as Laura Cárdenas and as Camilo Torres, since agents can only check UI through widget tests. Things worth a look:
- **"Versión" column width.** The issue's widths (148/130/150/70/70/110 plus the 16 px gaps) do not fit at 1440 px, so "Versión" stretches to take what is left (about 70 px). The other columns match the issue. Check that the table looks right next to the Figma frame `18:1222`.
- **Threshold ticks.** "0,60" and "0,90" now sit under their boundaries instead of in an evenly spaced row. This follows the issue's intent; spec.md still says "space-between row". If the thresholds ever get close together (within about 5 %), their labels would overlap. That can't happen with the seed values.
- **Copy the builder chose.** When retraining fails because there is no active model, the snackbar reads "No se pudo reentrenar: no hay un modelo activo." The store's error message is in English, so it is not shown to the user. The button stays enabled even when there is no active model.
- **Dashboard check left out.** Intake removed the issue's check that the Dashboard shows v6 after retraining, because the Dashboard was a stub at that point. The Dashboard has since merged (PR #46), so that check could be a follow-up.
- **Test helper.** The new `loadInterFont()` helper is also added to dashboard_test.dart and navigation_test.dart, because both open /models. No assertions changed.

Files to look at:
- lib/screens/models/models_page.dart
- lib/screens/models/models_screen.dart
- lib/widgets/table_header.dart
- test/screens/models_test.dart
- test/helpers/harness.dart
