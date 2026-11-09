DECISION: ACCEPT
RISK: medium
SURFACES: ui
RESCOPED: yes

## Summary
- Accepted: the "Modelos" screen as specified in the issue (production model, thresholds, versions table, feature importance, "Reentrenar ahora").
- Everything it needs is already on `develop`: `AppStore` has `models`, `activeModel`, `scoreThresholds`, `retrainNow()` and `approve()`, and the shared widgets exist.
- One small cut: the Dashboard is still a stub, so the check in criterion 4 that "the Dashboard's model card then shows v6" is left out.
- Medium risk because retraining changes shared store state, and that state is also read by other screens and the threshold logic.

## Scope
Build the screen exactly as the issue describes:
- Replace the stub `ModelsScreen` (the class name stays) with a stateful host. It reads `store.models`, `store.activeModel`, `store.scoreThresholds`, `store.now` and `store.can(PermissionCode.MODEL_TRAIN)`, and passes them to a stateless `ModelsPage`. The top bar shows "Modelos" / "Modelo de scoring · LightGBM".
- Row 1 has two cards. The dark production-model card shows the version, the "Entrenado …" line and four inverse `MetricTile`s. Their "vs. anterior" deltas compare against the most recent RETIRED version trained before the active one, and show "—" when there is none. Next to it, the thresholds card shows the three-segment scale, the ticks and the legend, all derived from `store.scoreThresholds`.
- Row 2 has two cards. The versions table lists versions newest first, with origin "Automático" or "Manual · {first name} {last initial}.", and shows the primary "Reentrenar ahora" button only to users with `MODEL_TRAIN`. The feature-importance card shows `FeatureBar`s sorted descending, each value as a percentage of the largest.
- With no active model, the production card reads "Sin modelo activo" and the feature card shows the `EmptyState` from the issue.
- `onRetrain` calls `store.retrainNow()` and shows the SnackBar from the issue: "{version} entrenado y activado." when the new version is ACTIVE, otherwise the "quedó como candidato" message. `retrainNow()` throws a `DomainError` when there is no active model. The screen must catch it and show its message in a SnackBar instead of crashing.
- Build the screen from the existing `lib/widgets/` components (`MetricTile`, `StatusPill.model`, `FeatureBar`, `EmptyState`, `AppButton`, …). Only the screen file touches `AppScope`/`AppStore`. Strings, colors and text styles exactly as in the issue, through `lib/theme/`, `labels.dart` and `format.dart`.
- Tests in `test/screens/models_test.dart` cover acceptance criteria 1–3 and 5–7, and criterion 4 without the Dashboard step: v6 appears at the top as "Activo", v5 becomes "Retirado", the production card shows "v6", and the snackbar appears.

Left out:
- The Dashboard assertion in criterion 4. The Dashboard screen is still a stub, so its model card belongs to the Dashboard task.
- Everything the issue lists as out of scope: manually activating a CANDIDATE, a quality-gate details panel, metric charts, retraining schedule settings.

## Why
The store already provides everything this screen needs: the version list, the active model, retraining and the thresholds (`lib/data/app_store.dart`, around lines 368–420 and 733). The shared widgets it composes are all in `lib/widgets/`, and the issue spells out every value, so the screen fits in one PR. Only the Dashboard cross-check can't be built yet: `lib/screens/dashboard/dashboard_screen.dart` still renders `SizedBox.shrink()`.

## Questions
