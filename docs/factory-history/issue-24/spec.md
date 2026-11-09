# Models screen with retraining

> Issue #24: Build the models screen with retraining

## Summary
- Replace the stub `ModelsScreen` with a stateful host and add a stateless `ModelsPage`. The page shows the production model, the decision thresholds, the version table and the feature importance, plus "Reentrenar ahora" for users with `MODEL_TRAIN`.
- Everything the screen needs is already in `AppStore`: `models`, `activeModel`, `scoreThresholds`, `retrainNow()` and `can()`. The screen is built from the existing `lib/widgets/` components.
- Following intake, criterion 4 leaves out the issue's Dashboard cross-check. Everything else in the issue's acceptance list is covered by `test/screens/models_test.dart`.
- `TableHeaderRow` gets optional size parameters so the compact 30 px header can reuse it. Its defaults stay the same, so the case queue does not change.

## Context
- **Stub to replace:** `lib/screens/models/models_screen.dart`. Today it is a `StatelessWidget` that renders `AppShell(active: NavDestination.models, title: 'Modelos', subtitle: '', child: SizedBox.shrink())`. The route `/models` (`AppRoutes.models` in `lib/app/routes.dart`) already builds `ModelsScreen()` and guards it with `MODEL_READ`.
- **Host/page pattern to copy:** `lib/screens/dashboard/dashboard_screen.dart` + `dashboard_page.dart`. Only the screen calls `AppScope.of(context)`. The page is a `StatelessWidget` that takes plain values and callbacks and splits its content into private section widgets (`_KpiRow`, `_ModelCard`, …). The dashboard's `_ModelCard` already shows a dark `bgInverse` card with `onInverseMuted` text, which is a useful reference for the production card. For SnackBars, follow `lib/screens/cases/case_detail_screen.dart`: it catches `DomainError` and shows a fixed Spanish SnackBar through `ScaffoldMessenger`.
- **Store (`lib/data/app_store.dart`):**
  - `models` returns the versions newest first, sorted by version number.
  - `activeModel` returns the ACTIVE version, or null when there is none.
  - `retrainNow()` (around line 381) needs `MODEL_TRAIN` and throws `DomainError('conflict', …)` when there is no active model. It returns the created `ModelVersion`. The new version is MANUAL, trained by the current user and gets metrics +0.01. When the quality gate passes, it becomes ACTIVE and the old active version becomes RETIRED; otherwise it stays CANDIDATE. The method calls `notifyListeners()`.
  - `scoreThresholds` (around line 733) returns `({double review, double block})`. The values come from the active `SCORE_REVIEW` / `SCORE_BLOCK` rules' `score >= x` condition (0.6 / 0.9 in the seed).
  - `now` and `can(PermissionCode)` complete what the screen reads.
- **Model data:** `lib/data/models/model_version.dart` defines `ModelVersion` (`version`, `trigger`, `trainedBy: UserRef?`, `status`, `metrics: ModelMetrics(prAuc, precision, recall, featureImportance)`, `trainedAt`, `trainingRows`, `fraudsSeen`). The seed in `lib/data/mock/mock_seed.dart` (around line 990) has:
  - v5: ACTIVE, SCHEDULED, today 02:00.
  - v4: CANDIDATE, MANUAL by Laura Cárdenas.
  - v3, v2, v1: RETIRED.

  Users: Laura Cárdenas is a DATA_SCIENTIST (has `MODEL_TRAIN`). Camilo Torres is an ANALYST (no `MODEL_TRAIN`). Laura Méndez and Diego Salazar are RISK_LEADs (rule write/approve).
- **Labels and formatters:**
  - `lib/data/labels.dart`: `ModelTrigger.label` ("Automático" / "Manual"), `ModelStatus.label` (used by `StatusPill.model`) and `featureLabel(name)`.
  - `lib/data/format.dart`: `formatInt`, `formatDecimal`, `formatDayMonth`, `formatHm`, `formatDayAgo` ("hoy" / "ayer" / …).
- **Shared widgets (`lib/widgets/`, exported by `widgets.dart`):**
  - `AppShell`
  - `AppCard` (white card, border, radius 14, default padding 24)
  - `MetricTile(label, value, note, onInverse)`
  - `StatusPill.model(status)`
  - `AppButton(label, onPressed)` (primary by default)
  - `FeatureBar(label, valueLabel, fraction)`
  - `EmptyState(icon, title, hint)`
  - `TableHeaderRow(cells: [TableHeaderCell(label, width)])`. It is currently fixed at height 40, horizontal padding 24, `bgSubtle`, no radius. It is used by `lib/screens/cases/case_queue_page.dart`.
- **Theme:** `lib/theme/`. The issue's colors map to tokens:
  - `#14213D` = `AppColors.bgInverse`
  - `#E9EBEF` = `bgSubtle`
  - `#DFE2E8` = `borderDefault`
  - `#8B919D` = `textTertiary`
  - `#545B69` = `textSecondary`
  - `#161B26` = `textPrimary`
  - `#2F7D55` / `#B86E00` / `#B42318` = `statusApprove` / `statusReview` / `statusBlock`
  - `onInverseMuted`
  - Radius 6 = `AppRadius.sm`, radius 14 = `AppRadius.lg`. `AppIcons.cpu` exists.
- **Tests:**
  - `test/helpers/pump_app.dart`: `pumpApp(tester, store:, signInAs:, initialRoute:)` at `kTestNow` = 2026-10-25 09:45.
  - `test/helpers/harness.dart`: `harness()` / `setDesktopView()` for pumping a widget alone.
  - The pattern to follow is `test/screens/dashboard_test.dart`. Rule lifecycle calls for criterion 6 are shown in `test/data/app_store_rules_test.dart` ("goes from draft to active with two people").
- **Reference implementation:** `git show archive/pr-29-flutter-prototype:lib/screens/models_page.dart`. Reuse its layout ideas only. Use this repo's data layer and store, never that tag's `models.dart`, `mock_data.dart` or `prototype_labels.dart`.

## Requirements
1. **Host screen.** `lib/screens/models/models_screen.dart` keeps the public `ModelsScreen()` (const constructor) and becomes a `StatefulWidget`.
   - Its `build` reads `AppScope.of(context)` once: `store.models`, `store.activeModel`, `store.scoreThresholds`, `store.now` and `store.can(PermissionCode.MODEL_TRAIN)`.
   - It renders `AppShell(active: NavDestination.models, title: 'Modelos', subtitle: 'Modelo de scoring · LightGBM', child: ModelsPage(...))`.
2. **Retraining.** The screen passes `onRetrain` to the page only when the user can `MODEL_TRAIN`, and `null` otherwise. `onRetrain` calls `AppScope.read(context).retrainNow()` and then shows a `SnackBar`:
   - `'{version} entrenado y activado.'` when the returned version's status is ACTIVE.
   - Otherwise `'{version} quedó como candidato: no pasó el control de calidad.'`.
   - On `DomainError`, it shows the fixed Spanish SnackBar `'No se pudo reentrenar: no hay un modelo activo.'` and does not crash.
3. **Page.** Add `lib/screens/models/models_page.dart` with a public `StatelessWidget` `ModelsPage`. Its constructor takes `models` (`List<ModelVersion>`), `activeModel` (`ModelVersion?`), `reviewThreshold` and `blockThreshold` (`double`), `now` (`DateTime`) and `onRetrain` (`VoidCallback?`).
   - It never calls `AppScope`, never touches `AppStore` and never navigates.
   - Private section widgets (in the page file or `lib/screens/models/widgets/`) get their data through constructor parameters the same way.
4. **Layout.**
   - Two rows with a vertical gap of 24 (`AppSpacing.xl`). Each row has an `Expanded` left card, a 24 gap and a right card 360 wide. Use `IntrinsicHeight` + `CrossAxisAlignment.stretch` like the dashboard, so the cards in a row share the same height.
   - The page content must not overflow at 1440 x 900.
5. **Production model card** (left, row 1).
   - Container: bg `AppColors.bgInverse`, radius `AppRadius.lg`, padding 28, column gap 20.
   - Header row, space-between: "Modelo en producción" in `AppTextStyles.label` with `onInverseMuted` color, and `StatusPill.model(ModelStatus.ACTIVE)`.
   - Then a column with gap 6:
     - The version in `AppTextStyles.display` with `textInverse` color.
     - The line `'Entrenado ${formatDayAgo(trainedAt, now)} a las ${formatHm(trainedAt)} · ${trigger.label.toLowerCase()} · ${formatInt(trainingRows)} transacciones'` in `body` with `onInverseMuted` color.
   - Then four `MetricTile(onInverse: true)` in a row with gap 12, each `Expanded`:
     - "PR-AUC" `formatDecimal(prAuc)`
     - "Recall" `formatDecimal(recall)`
     - "Precisión" `formatDecimal(precision)`
     - "Fraudes vistos" `formatInt(fraudsSeen)`
6. **Metric deltas.**
   - The baseline is the RETIRED version with the latest `trainedAt` that is still earlier than the active version's `trainedAt`.
   - Decimal metrics: note = sign + `formatDecimal(delta)` + `' vs. anterior'`. Fraudes vistos: note = sign + `formatInt(delta)` + `' vs. anterior'`.
   - The sign is `'+'` when delta >= 0 and `'-'` when it is negative. Round decimal deltas to 2 places before choosing the sign, so float noise never prints `-0,00`.
   - With no baseline, every note is `'—'`.
   - The seed gives "+0,02 vs. anterior", "+0,02 vs. anterior", "+0,01 vs. anterior" and "+120 vs. anterior".
7. **No active model.** The production card shows only the header label "Modelo en producción" and the text "Sin modelo activo" in `display` style with `textInverse` color. It has no pill, no training line and no tiles.
8. **Thresholds card** (right, row 1): `AppCard`, gap 16, heading "Umbrales de decisión" (`heading`), caption "Según el puntaje de riesgo del modelo" (`caption`, `textSecondary`, 2 px below).
   - **Scale** (gap 8):
     - A bar of three segments, height 10, radius 5, with 3 px gaps between them, colored `statusApprove`, `statusReview` and `statusBlock`.
     - The segment widths are proportional to `review`, `block - review` and `1 - block` (use `Expanded` with `flex` from the fractions, e.g. ×1000 rounded).
   - **Ticks:** a space-between row with "0", `formatDecimal(review)`, `formatDecimal(block)` and "1", in `caption` with `textTertiary` color.
   - **Legend** (column gap 12). Each row is space-between: an 8 px dot, a gap of 8 and the label in `body` `textPrimary`, then the value in `bodyStrong`:
     - "Aprobar" `'< ${formatDecimal(review)}'`
     - "Revisar" `'${formatDecimal(review)} – ${formatDecimal(block)}'` (en dash with spaces)
     - "Bloquear" `'≥ ${formatDecimal(block)}'`

     These rows are a private widget, because `LegendItem` uses different text styles and has no value.
9. **Versions card** (left, row 2): `AppCard`, gap 16.
   - **Header row:** an `Expanded` column with "Versiones" (`heading`) over "Reentrenamiento automático cada noche a las 02:00" (`caption`). Next to it, a primary `AppButton(label: 'Reentrenar ahora', onPressed: onRetrain)`, rendered only when `onRetrain != null`.
   - **Table header:** `TableHeaderRow` at height 30, horizontal padding 12 and radius `AppRadius.sm`, with columns "Versión" 148, "Entrenado" 130, "Origen" 150, "PR-AUC" 70, "Recall" 70 and "Estado" 110.
   - **Rows:** one per model in the order given (newest first), height 57, horizontal padding 12, bottom border 1 `borderDefault`, using the same column widths and gap as the header:
     - the version in `bodyStrong` `textPrimary`
     - `'${formatDayMonth(trainedAt)} · ${formatHm(trainedAt)}'` in `body` `textSecondary`
     - the origin: "Automático" for SCHEDULED, `'Manual · {first word of fullName} {first letter of last word}.'` for MANUAL (plain "Manual" when `trainedBy` is null), in `body` `textSecondary`
     - PR-AUC and recall via `formatDecimal`, in `body` `textPrimary`
     - `StatusPill.model(status)`
10. **`TableHeaderRow` sizing.** Extend `lib/widgets/table_header.dart` with optional `height` (default 40), `horizontalPadding` (default `AppSpacing.xl`) and `radius` (default 0, i.e. no rounding) constructor parameters. Existing callers stay byte-for-byte unchanged in behaviour. Document the new parameters in the widget's doc comment and add a test for them in the existing `test/widgets/table_header_test.dart`.
11. **Feature importance card** (right, row 2): `AppCard`, gap 16, heading "Variables más influyentes" over caption "Importancia relativa en la versión activa".
    - Then one `FeatureBar` per entry of the active model's `metrics.featureImportance`, sorted by value descending, with gap 16:
      - `label: featureLabel(name)`
      - `fraction: value / max`
      - `valueLabel: '${(fraction * 100).round()} %'`
    - With no active model, it shows `EmptyState(icon: AppIcons.cpu, title: 'Sin modelo activo', hint: 'Reentrena para tener una versión en producción.')` instead of the bars.
12. **Tokens and strings.**
    - All colors, spacing, radii and text styles come from `lib/theme/`. Numbers that have no token (28, 20, 6, 10, 5, 3, 30, 57, 360 and the column widths) are allowed as named `static const double` fields in the page, as the existing widgets do. No hex colors or font sizes.
    - Every on-screen string matches the issue exactly, including accents, `·`, `–`, `≥` and `%` preceded by a space.
13. **Tests.** Add `test/screens/models_test.dart` covering the acceptance criteria below. Use `pumpApp(..., initialRoute: AppRoutes.models)` for the full-app tests, and `harness()` + `setDesktopView()` for the page-alone tests.
14. **Docs.** No AGENTS.md change is needed, because the screen follows the documented structure. The `TableHeaderRow` doc comment must describe the new parameters.

## Acceptance criteria
All tests below are in `test/screens/models_test.dart` unless stated otherwise, and pass under `flutter test`.

1. Signed in as `laura.cardenas@monedasegura.co` at `/models`, the screen shows each of these texts:
   - "Modelos" and "Modelo de scoring · LightGBM"
   - "Modelo en producción", "Activo" and "v5"
   - "Entrenado hoy a las 02:00 · automático · 182.400 transacciones"
   - "PR-AUC", "0,81", "Recall", "0,74", "Precisión", "0,62", "Fraudes vistos" and "1.940"
   - "+0,02 vs. anterior" (found twice), "+0,01 vs. anterior" and "+120 vs. anterior"
2. On the same screen, "Umbrales de decisión", "Según el puntaje de riesgo del modelo", "Aprobar", "< 0,60", "Revisar", "0,60 – 0,90", "Bloquear" and "≥ 0,90" are shown, and the ticks "0", "0,60", "0,90" and "1" are found.
3. The versions table and the feature card show:
   - "v5", "v4", "v3", "v2" and "v1", with v5's row above v1's (compare `tester.getTopLeft` dy)
   - "25 oct · 02:00", "Manual · Laura C." and "Candidato"
   - "Retirado" exactly three times
   - the six labels "Monto vs. promedio 30 días", "Dispositivo nuevo", "Transacciones última hora", "Velocidad entre ubicaciones", "Horario nocturno" and "Inicios de sesión fallidos"
   - "100 %", "78 %" and "27 %"
4. As Laura Cárdenas, tapping "Reentrenar ahora" and settling gives:
   - "v6" shown in the table above "v5"
   - "Activo" found twice (the production card pill and v6's row)
   - "Retirado" found four times (v5 now retired)
   - the production card shows "v6" in the display text and no longer "v5" there
   - the snackbar "v6 entrenado y activado." is visible

   The Dashboard cross-check is not part of this criterion.
5. Signed in as `camilo.torres@monedasegura.co` at `/models`, the screen shows "Modelos" and `find.text('Reentrenar ahora')` finds nothing.
6. A test builds a seeded store (`AppStore.seeded(clock: () => kTestNow)`) and approves a new `SCORE_REVIEW` version whose condition is `score >= 0.5`:
   1. Laura Méndez creates a version, updates the draft to `Condition('score', ConditionOp.gte, 0.5)` with action REVIEW, starts shadow, runs the backtest and submits it.
   2. Diego Salazar approves it.
   3. The test calls `pumpApp(store: store, signInAs: laura.cardenas, initialRoute: AppRoutes.models)`.

   The legend shows "< 0,50" and "0,50 – 0,90", and the ticks show "0,50".
7. `grep -rn "AppScope\|AppStore" lib/screens/` matches only files ending in `_screen.dart`, and `lib/screens/models/models_page.dart` does not match.
8. A page-alone test pumps `ModelsPage` through `harness()` with no `AppScope`, plain fake `ModelVersion` data, thresholds 0.6 / 0.9 and an `onRetrain` callback that records taps. Tapping "Reentrenar ahora" calls the callback exactly once.
9. A page-alone test with `onRetrain: null` shows no "Reentrenar ahora".
10. A page-alone test with `activeModel: null` and only RETIRED / CANDIDATE models shows:
    - "Sin modelo activo" (in both the production card and the `EmptyState`)
    - the hint "Reentrena para tener una versión en producción."
    - no "vs. anterior" note and no `FeatureBar`
11. A page-alone test whose active model has no earlier RETIRED version shows the note "—" on all four metric tiles (`find.text('—')` finds 4).
12. `test/widgets/table_header_test.dart` gains a test showing that `TableHeaderRow(height: 30, horizontalPadding: 12, radius: AppRadius.sm, …)` renders 30 px high. The existing `TableHeaderRow` tests and the case queue tests still pass unchanged.
13. In `lib/screens/models/`, `grep -rn "Color(0x\|fontSize" lib/screens/models/` returns nothing.

## Out of scope
- The Dashboard assertion of the issue's criterion 4 (intake cut it). Do not change `lib/screens/dashboard/`.
- Manually activating a CANDIDATE version, a quality-gate details panel, metric charts over time, and retraining schedule settings. The "02:00" caption is static text.
- Changing `AppStore` (`retrainNow`, `scoreThresholds`, `models`), the seed data, routes or nav destinations.
- Changing any shared widget other than adding the optional sizing parameters to `TableHeaderRow`. Do not restyle `LegendItem`, `MetricTile`, `FeatureBar` or `StatusPill`.
- Hover states, sorting or pagination on the versions table. Loading states and real API calls.
- Showing English `DomainError` messages to the user.
- Editing `factory/checks.sh` or `factory/config.json`.

## Assumptions
- **`TableHeaderRow` gets optional `height`, `horizontalPadding` and `radius` parameters.** The issue's header (30 px, padding 12, radius 6) differs from the shared widget's fixed 40 px / 24 / square look. The issue also forbids re-creating gallery components inline, so a backward-compatible parameter is the smallest way to honor both.
- **The threshold legend rows are a private widget in the page.** `LegendItem` uses caption / secondary text and a 4 px gap and has no value column, so it does not match the issue's legend.
- **The retraining error SnackBar reads "No se pudo reentrenar: no hay un modelo activo."** It does not show `DomainError.message`. Intake asked for "its message", but that message is English, and AGENTS.md requires user-facing text in Spanish. `case_detail_screen.dart` already shows a fixed Spanish message on `DomainError`.
- **"—" alone is the note when there is no baseline version.** The issue says `"—" when none` literally.
- **Negative deltas use `'-'`, positive and zero deltas use `'+'`.** This matches the dashboard's delta convention.
- **The no-active-model production card hides the pill, the training line and the tiles.** The issue only states the "Sin modelo activo" text, and a status pill or metrics without a model would be meaningless.
- **"Reentrenar ahora" is shown whenever the user has `MODEL_TRAIN`, even with no active model.** The issue gates it only on the permission, and the error SnackBar covers that case.
- **Origin "Manual" alone when a MANUAL version has no `trainedBy`.** The model allows a null `trainedBy`, and the issue doesn't define that case.
