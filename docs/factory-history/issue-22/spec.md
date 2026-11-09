# Rule editor: view a version and move it through its lifecycle

> Issue #22: Build the rule editor: view a version, shadow, backtest and two-step approval

## Summary
- This spec turns the stub `RuleEditorScreen` into a host that reads the store, and adds a callback-only `RuleEditorPage` for the stepper, condition, backtest, approval and versions blocks.
- The store and shared widgets it needs are already on `develop`, so the work is mainly presentation and wiring. The exceptions are a small seed fix and one formatter moved out of `ConditionRow`.
- Intake's rewrites of criteria 2, 6 and 7 are binding and replace the issue's wording: a seed change for "+3,1 pp", "Valentina Ríos" as Laura's approver, and a two-route backtest gate.
- The rules list (#21, PR #47) was not merged when this was written, so criterion 4 has a conditional check.
- A few gaps the issue doesn't cover are decided under Assumptions, including a negative "Fraudes atrapados" difference and how store errors are shown.

## Context

**Files to change**
- `lib/screens/rules/rule_editor_screen.dart`: a stub today. Routes are already wired in `lib/app/routes.dart`: `/rules/new` builds `RuleEditorScreen(ruleId: null)` and needs `RULE_WRITE`; `/rules/<id>` needs `RULE_READ`.
- `test/app/navigation_test.dart`: pins the top bar title `Regla` for `/rules/abc` (unknown id) and `/rules/new`, so both empty states keep that title.

**Patterns to follow**
- Host and page: `lib/screens/models/models_screen.dart` with `models_page.dart`, and `lib/screens/cases/case_detail_screen.dart` with `case_detail_page.dart`. That includes the not-found shape (`AppShell` around a column with `EmptyState` and a ghost back button), `pushReplacementNamed` for going back, and catching `DomainError` into a `SnackBar`.
- Test pattern: `test/screens/models_test.dart` uses `pumpApp`, `harness` and `setUpAll(loadInterFont)`.

**Store (`lib/data/app_store.dart`)**
- Reads: `ruleById`, `can`, `canApprove`, `approversFor`, `userById`, `currentUser`, `now`.
- Actions: `startShadow`, `runBacktest`, `submitForApproval`, `approve`, `reject`, `createVersion`. They enforce the permission and four-eyes rules of `model.md` §6 and throw `DomainError`.
- `reject` clears `shadowStats` and `submittedAt` but keeps the backtest.
- `reject` also refuses an empty reason or one over 1000 characters.

**Models and helpers**
- `lib/data/models/rule.dart`: `RuleView` (`versions` newest first, `latest`, `active`, `version(n)`), `RuleVersion`, `Backtest`, `BacktestCounts` (`matches`, `precision`), `ShadowStats`, and `ConditionOp.symbol`. `createdBy` and `approvedBy` are `UserRef`s, which have no role.
- `lib/data/format.dart`: `formatInt`, `formatDecimal`, `formatPercent`, `formatDayMonth`, `formatDayAgo`, `formatHm`.
- `lib/data/labels.dart`: `RuleStatus.label`, `RuleAction.label`, `RoleCode.label`.
- `AppUser.initials` exists in `lib/data/models/app_user.dart`.

**Shared widgets (`lib/widgets/`), all exported by `widgets.dart`**
- `AppShell`, `AppCard` (default padding 24), `AppButton` (`null` `onPressed` disables it; `expand`, `icon`, `variant`).
- `AppStepper` with `StepperStepState`, read-only `ConditionRow`, `AppSegmentedControl` (`onChanged: null` is read-only).
- `MetricTile` (`note` is a required string), `AppBanner(leading:)`, `RuleStatusBadge`, `TimelineEvent`, `AppAvatar`, `AppTextField`, `EmptyState`.

**Seed (`lib/data/mock/mock_seed.dart`)**
- Users, in order: Valentina Ríos (ADMIN), Laura Méndez, Diego Salazar (RISK_LEAD), Camilo Torres (ANALYST).
- The routes used in the tests:

| Rule | State in the seed |
|---|---|
| `NIGHT_TRANSFER` | v2 PENDING_APPROVAL, v1 ACTIVE |
| `FAR_FROM_HOME` | v1 SHADOW, with a backtest |
| `ATO_PASSWORD_RESET` | v1 DRAFT by Diego, no backtest |
| `SCORE_BLOCK` | v2 ACTIVE, v1 RETIRED |

**Reference code.** The tag `archive/pr-29-flutter-prototype:lib/screens/rule_editor_page.dart` is a reference only. This spec and the issue win over it, and its data layer must not be used. It has no rejection dialog, and the repo has no dialog yet.

## Requirements

### Screen (`lib/screens/rules/rule_editor_screen.dart`)
1. Keep `RuleEditorScreen({String? ruleId})`, as a `StatefulWidget` that reads the store with `AppScope.of` and `AppScope.read`. It owns the selected version number, defaulting to `latest`, and falls back to `latest` if the number is not in the view.
2. `ruleId == null`: `AppShell(active: NavDestination.rules, title: 'Regla', subtitle: '')` around `EmptyState(icon: AppIcons.plus, title: 'Nueva regla', hint: 'Disponible pronto.')`.
3. Unknown id: the same shell around `EmptyState(icon: AppIcons.sliders, title: 'No encontramos esta regla', hint: 'Puede que se haya descartado.')` and a ghost `AppButton(icon: AppIcons.back, label: 'Reglas')` that goes to `/rules`.
4. Found: `AppShell` with title `'{code} · v{selected}'` ("NIGHT_TRANSFER · v2") and subtitle `rule.name`.
5. The screen performs every store call and the navigation:
   - Every action keeps the same version selected, except "Crear nueva versión", which selects the new one.
   - `onBack` uses `pushReplacementNamed(AppRoutes.rules)`.
   - A `DomainError` from a store call shows `SnackBar('No se pudo completar la acción.')` and leaves the state as it was.
6. The screen derives these and passes them down:
   - `canWrite = store.can(PermissionCode.RULE_WRITE)`
   - `canApprove = store.canApprove(version)`
   - `approver`: the current user when `canApprove`, otherwise the first of `store.approversFor(version)`, or null if there is none. Never filter by role or reorder.
   - `creator = store.userById(version.createdBy.id)`, used for the role label.

### Page (`lib/screens/rules/rule_editor_page.dart`, new)
7. `RuleEditorPage` is a `StatelessWidget` taking only constructor parameters:
   - Data: the `RuleView`, the selected `RuleVersion`, `now`, `AppUser? creator`, `AppUser? approver`, `canWrite`, `canApprove`.
   - Callbacks: `onBack`, `onSelectVersion(int)`, `onStartShadow`, `onRunBacktest`, `onSubmit`, `onApprove`, `onReject(String reason)`, `onNewVersion`.
8. The page, its section widgets and its dialog never reference `AppScope` or `AppStore`. Sections may be private in the page file or live in `lib/screens/rules/widgets/`, under the same rule.
9. Layout: a column with gap 24 holding the actions row and the columns row. The columns row has gap 16 and is top aligned, with left expanded and right 360 wide. Each side is a column with gap 16. Cards use `AppCard`, headings `AppTextStyles.heading`, and captions `AppTextStyles.caption` with `AppColors.textSecondary`, 2 px below the title. Only `lib/theme/` tokens are used.

### Actions row
10. Ghost `AppButton(icon: AppIcons.back, label: 'Reglas')` calling `onBack`, then a spacer, then `AppStepper` with steps "Borrador", "Shadow" (or "Shadow · {n} d" when the version has `shadowStats`), "Aprobación", "Activa".
11. Step states by status (D = done, C = current, P = pending):

| Status | Borrador | Shadow | Aprobación | Activa |
|---|---|---|---|---|
| DRAFT | C | P | P | P |
| SHADOW | D | C | P | P |
| PENDING_APPROVAL | D | D | C | P |
| ACTIVE, RETIRED | D | D | D | D |

### Condition card
12. "Condición" heading over "Se cumple cuando se cumplen todas" caption, then one read-only `ConditionRow` per condition (gap 16). Below that, a row with gap 12: "Acción" in `bodyStrong` and `AppSegmentedControl` with ("Revisar", "Bloquear") showing the version action, with `onChanged: null`. No editing controls.

### Backtest card
13. Header row:
    - "Backtest · últimos 30 días" heading, over "Sobre {formatInt(casesEvaluated)} casos etiquetados" caption when there is a backtest (no caption when there isn't).
    - Secondary `AppButton`, "Volver a correr" with a backtest and "Correr backtest" without. It shows only when `canWrite` and is enabled only for DRAFT or SHADOW.
14. With a backtest: four equal-width `MetricTile`s in a row, gap 16:
    - "Coincidencias": `formatInt(matches)`, note "{formatPercent(matches / casesEvaluated, digits: 1)} de los casos".
    - "Fraudes atrapados": `formatInt(TP)`, where the note depends on `backtest.active`:
      - null: "Sin versión activa para comparar"
      - `TP - active.TP` above 0: "+{difference} que hoy se escapan"
      - otherwise: "Sin fraudes nuevos frente a la versión activa"
    - "Precisión": `formatDecimal(precision)`, note "objetivo ≥ 0,40".
    - "Recall total": `"{sign}{difference in points, 1 decimal} pp"`, note "{formatDecimal(before)} → {formatDecimal(after)}". Round the difference to one decimal before choosing the sign: `+` at zero or above, `-` below, so zero reads "+0,0 pp". When either recall value is null, the value is "—" and the note is `''`.
15. Without a backtest: the caption "Todavía no hay backtest para esta versión." in `textSecondary`.
16. With `shadowStats`: `AppBanner(leading: RuleStatusBadge(status: RuleStatus.SHADOW), message: ...)`, whether or not there is a backtest. The message is "{days} días en shadow: {formatInt(matched)} coincidencias, " followed by "ninguna decisión cambiada todavía." when `verdictChanges` is 0, or "{k} decisiones cambiarían." otherwise. Use the singular for 1: "1 día en shadow", "1 coincidencia", "1 decisión cambiaría."
17. Days are `now.difference(since).inDays` everywhere (stepper, banner, timeline).

### Approval card
18. "Aprobación en dos pasos" heading, then a column of `TimelineEvent`s with gap 16, in this order:

| When | Title | Meta |
|---|---|---|
| always | "Creada por {createdBy.fullName}" | "{first role label of creator} · {formatDayMonth(createdAt)}" (just the date if `creator` is null) |
| `shadowStats` | "Shadow iniciado" | "{formatDayMonth(since)} · {days} días" ("1 día" in the singular) |
| `submittedAt` | "Enviada a aprobación" | "{formatDayAgo(submittedAt, now)}, {formatHm(submittedAt)}" ("hoy, 08:10") |
| PENDING_APPROVAL | "Esperando a otro líder de riesgo" | "Quien la creó no puede aprobarla" |
| ACTIVE or RETIRED with `approvedBy` | "Aprobada por {approvedBy.fullName}" | `formatDayMonth(approvedAt)` |
| DRAFT with `rejectionReason` | "Devuelta a borrador" | the reason |

19. PENDING_APPROVAL only, when `approver` is not null: the approver box. Background `AppColors.bgCanvas`, radius `AppRadius.md` (10), padding 12 x 8, gap 8, `AppAvatar(initials: approver.initials)`, then the name in `bodyStrong` over "Puede aprobar" caption in `textSecondary`.
20. Only when `canApprove`: primary "Aprobar y activar" and secondary "Devolver a borrador", both full width, gap 8.
21. "Devolver a borrador" opens a dialog titled "Devolver a borrador", with `AppTextField(label: 'Motivo')`, ghost "Cancelar" and primary "Devolver".
    - "Devolver" is enabled only when the trimmed text is not empty. It closes the dialog and calls `onReject` with the trimmed text.
    - The typed text lives in the dialog's own transient state, not the page.
22. Below the timeline, full width, only when `canWrite`:
    - SHADOW: primary "Enviar a aprobación". Without a backtest it is disabled and the caption "Corre el backtest antes de enviar." shows below it.
    - DRAFT: primary "Iniciar shadow".
    - Selected version is `latest`, its status is ACTIVE or RETIRED, and no version of the rule is DRAFT, SHADOW or PENDING_APPROVAL: primary "Crear nueva versión".
    - Otherwise nothing.

### Versions card
23. "Versiones" heading, then, with gap 12, one tappable row per version, newest first, calling `onSelectVersion`. Each row is 40 high: "v{n}" in `bodyStrong` `textPrimary`, gap 12, expanded summary caption in `textSecondary`, then `RuleStatusBadge`. The selected row has background `AppColors.bgCanvas` and radius `AppRadius.sm` (6).
24. The summary uses the `amount` condition if there is one, otherwise the first condition: "{op.symbol} {value} · {action.label}" ("≥ $ 2.000.000 · Revisar").
25. Value formatting must not be duplicated. Move `_displayValue` and its COP feature set out of `ConditionRow` into a public helper in `lib/data/format.dart`, for example `formatConditionValue(String feature, Object value)`. Both `ConditionRow` and the summary call it. `ConditionRow`'s behaviour doesn't change.

### Seed
26. In `lib/data/mock/mock_seed.dart`, set NIGHT_TRANSFER v2 to `systemRecallBefore: 0.742` and `systemRecallAfter: 0.773`. Update lines 526 and 527 of `test/data/mock_seed_test.dart` to match. Don't change `_systemRecallBefore` in the store, the user order, or the FAR_FROM_HOME backtest.

### Tests and docs
27. Add `test/screens/rule_editor_test.dart`, covering every acceptance criterion below, using `pumpApp` and `setUpAll(loadInterFont)`. Add a `format_test.dart` case for the moved helper.
28. All on-screen text is Spanish and matches the strings above exactly. Code, comments and tests are English. No changes to `AGENTS.md` or the shared docs are needed.

## Acceptance criteria

Unless stated otherwise, each is a widget test in `test/screens/rule_editor_test.dart` at route `/rules/<rule id>`, signed in as the named user. Text that also appears in the sidebar or in more than one block ("Reglas", "Activa", "Valentina Ríos") is scoped with `find.descendant` or asserted with `findsWidgets`.

1. **Header and condition.** NIGHT_TRANSFER as Valentina shows "NIGHT_TRANSFER · v2", "Transferencia nocturna de monto alto", "Reglas", the stepper "Borrador", "Shadow · 5 d", "Aprobación", "Activa" (the `StepperStep` states are done, done, current, pending), "Condición", "Se cumple cuando se cumplen todas", "is_night", "Sí", "amount", "≥", "$ 2.000.000", "Acción", "Revisar", "Bloquear".
2. **Backtest.** On the same route: "Backtest · últimos 30 días", "Sobre 1.920 casos etiquetados", "79", "4,1 % de los casos", "41", "+9 que hoy se escapan", "0,52", "objetivo ≥ 0,40", "+3,1 pp", "0,74 → 0,77", and the banner "5 días en shadow: 61 coincidencias, ninguna decisión cambiada todavía." The `AppButton` "Volver a correr" has a null `onPressed`.
3. **Approval and versions.** On the same route: "Aprobación en dos pasos", "Creada por Laura Méndez", "Líder de riesgo · 19 oct", "Shadow iniciado", "Enviada a aprobación", "hoy, 08:10", "Esperando a otro líder de riesgo", "Quien la creó no puede aprobarla", "Valentina Ríos" with "Puede aprobar", "Aprobar y activar", "Devolver a borrador". "Versiones" shows "v2", "≥ $ 2.000.000 · Revisar", "Pendiente", then "v1", "≥ $ 5.000.000 · Revisar", "Activa".
4. **Approve.** Tapping "Aprobar y activar" as Valentina makes v2 "Activa" and v1 "Retirada" in the versions card, every `StepperStep` done, and v2 stays selected.
   - If `RulesScreen` on the branch's base shows the rules list (#21 merged), the test also opens `/rules` and asserts NIGHT_TRANSFER shows "Activa".
   - If it is still the stub, the test asserts `store.ruleByCode('NIGHT_TRANSFER')` has v2 ACTIVE, and the PR body says the list check is still to do.
5. **Return to draft.** Tapping "Devolver a borrador" opens the dialog with "Motivo", and "Devolver" has a null `onPressed` until text is typed, including when only spaces are typed. With "Falta evidencia", v2 becomes "Borrador", and "Devuelta a borrador" and "Falta evidencia" are shown. "Cancelar" closes the dialog and leaves v2 "Pendiente".
6. **Four eyes.** NIGHT_TRANSFER as Laura Méndez, the creator: no "Aprobar y activar" or "Devolver a borrador", and the approver box shows "Valentina Ríos" with "Puede aprobar". As Diego Salazar: "Aprobar y activar" is shown.
7. **Backtest gate.** Both as Laura Méndez:
   - ATO_PASSWORD_RESET: "Iniciar shadow" makes it Shadow; "Enviar a aprobación" has a null `onPressed` and "Corre el backtest antes de enviar." shows; tapping "Correr backtest" enables it and removes the caption; tapping it makes the version "Pendiente".
   - FAR_FROM_HOME: "Volver a correr" shows, "Enviar a aprobación" is enabled, the banner reads "1 día en shadow: 1.102 coincidencias, 14 decisiones cambiarían.", and submitting makes the version "Pendiente".
8. **New version.** SCORE_BLOCK as Laura Méndez: "Crear nueva versión" creates v3 "Borrador", selects it, and the title is "SCORE_BLOCK · v3".
9. **Read-only user.** As Camilo Torres, on NIGHT_TRANSFER, FAR_FROM_HOME, ATO_PASSWORD_RESET and SCORE_BLOCK: none of "Volver a correr", "Correr backtest", "Aprobar y activar", "Devolver a borrador", "Enviar a aprobación", "Iniciar shadow", "Crear nueva versión" exists. The ghost "Reglas" back button and the version rows remain.
10. **Selection.** On SCORE_BLOCK as Laura Méndez, tapping the "v1" row changes the title to "SCORE_BLOCK · v1", and "Crear nueva versión" no longer shows because v1 isn't the latest.
11. **Without data.**
    - ATO_PASSWORD_RESET as Laura Méndez shows "Todavía no hay backtest para esta versión.", no "casos etiquetados" caption, and "Correr backtest".
    - After a backtest, it shows "Sin versión activa para comparar".
    - FAR_FROM_HOME shows "—" for "Recall total".
    - On SCORE_BLOCK as Laura Méndez, after "Crear nueva versión" then "Correr backtest", the "Fraudes atrapados" note is "Sin fraudes nuevos frente a la versión activa" and the "Recall total" value starts with "-".
12. **Empty states.** `/rules/new` as Laura Méndez shows "Nueva regla" and "Disponible pronto." `/rules/abc` shows "No encontramos esta regla", "Puede que se haya descartado.", and tapping the ghost "Reglas" goes to `/rules`. `test/app/navigation_test.dart` still passes unchanged.
13. **Page isolation.** `cd <repo> && grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files. A widget test pumps `RuleEditorPage` through `harness` in a scroll view, with no `AppScope`, plain fake data and recording callbacks. It asserts that tapping "Aprobar y activar" calls `onApprove`, that the dialog passes the reason to `onReject`, and that tapping a version row calls `onSelectVersion` with its number.
14. **Seed.** `test/data/mock_seed_test.dart` expects 0.742 and 0.773 for NIGHT_TRANSFER v2 and passes.
15. **Formatter.** `grep -n "_displayValue" lib/widgets/condition_row.dart` matches nothing, `lib/data/format.dart` holds the helper, and `test/widgets/condition_row_test.dart` passes unchanged.

## Out of scope
- Creating a rule, editing conditions or action, saving or discarding drafts, the editable `ConditionRow` controls and "+ Agregar condición" (all next task). `ruleId == null` stays an empty state.
- Shadow statistics charts and comparing versions side by side.
- Building or changing the rules list (`lib/screens/rules/rules_screen.dart`, #21).
- Changing store logic, `canApprove`, `approversFor`, the seed user order or the seeded FAR_FROM_HOME backtest, or filtering approvers by role to reach Diego.
- Changing `decision-api.yaml`, `model.md` or any other repo. Calling a real API.
- Re-creating a gallery widget inline, or adding a shared dialog widget or new theme tokens unless a missing one blocks the build.

## Assumptions
- **Intake's readings stand** (criteria 2, 4, 6, 7, 9; "—" for missing recall; no caption without a backtest; `formatInt` and singular in the shadow text). Intake already decided them and asked for corrections on the PR. Showing "Valentina Ríos" in criterion 6 rather than "Diego Salazar" is the one most worth a human look.
- **A difference of zero or below in "Fraudes atrapados" reads "Sin fraudes nuevos frente a la versión activa".** The store's mock backtest makes this reachable (a SCORE_BLOCK v3 run gets at most 54 true positives against 88), and "+-34 que hoy se escapan" would be wrong. The copy is new.
- **Store errors show "No se pudo completar la acción."** in a `SnackBar`. The UI gating should prevent these, and the case detail screen handles `DomainError` the same way. The copy is new.
- **"Devolver" trims the reason and rejects spaces only.** The store only refuses a literally empty string, and a blank reason is meaningless on the timeline.
- **The singular also applies to "1 coincidencia" and "1 decisión cambiaría."** This extends intake's singular for days, for the same reason.
- **The page opens its own dialog.** The issue's page contract is `onReject(String reason)`, so the page has to collect the reason. A dialog is local interaction, not app navigation, and the screen still performs the store call.
- **The not-found "← Reglas" is `AppButton(icon: AppIcons.back, label: 'Reglas')`.** This matches the actions row, and the app has no literal arrow button text.
- **Both empty states keep the title `Regla` with an empty subtitle.** `test/app/navigation_test.dart` pins it.
- **The approver box is hidden when `approversFor` is empty.** The issue doesn't cover this and the seed never reaches it, so there is no name to show.
- **"Crear nueva versión" shows only when the selected version is the latest.** This is the issue's "latest version with no open draft", read to include all open statuses because `createVersion` refuses any DRAFT, SHADOW or PENDING_APPROVAL version.
- **"Fraudes atrapados" uses `backtest.active`, not `RuleView.active`.** Seeded backtests other than NIGHT_TRANSFER v2 therefore read "Sin versión activa para comparar", even on a rule with an active version. The issue's formula names `active` beside the backtest counts, and the seed test pins those values.
