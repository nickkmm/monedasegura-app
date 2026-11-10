# Create, edit and discard rule drafts

> Issue #25: Create, edit and discard rule drafts in the rule editor

## Summary
- Turns the rule editor's DRAFT versions into an editable form (conditions, action, save, discard) for users with `RULE_WRITE`; every other status and user stays read-only.
- Replaces the "Disponible pronto." placeholder on `/rules/new` with a "Nueva regla" form that calls `store.createRule` and opens the new rule.
- `RuleEditorScreen` owns the editing buffer and does every store call and navigation; `RuleEditorPage` and its sections only get props and report callbacks.
- Intake's one rescope: "Descartar borrador" is hidden for a draft that has a `rejectionReason`, because `deleteDraft` refuses those.
- New tests go in `test/screens/rule_drafts_test.dart`; two existing tests that pin the old `/rules/new` placeholder get updated.

## Context
- **Host screen.** `lib/screens/rules/rule_editor_screen.dart`: `RuleEditorScreen(ruleId)` is a `StatefulWidget`. It reads `AppScope.of(context)`, keeps `_selected` (version number), wraps store calls in `_act` (a `DomainError` shows a SnackBar) and renders `RuleEditorPage` inside `AppShell(title: '<code> · v<n>', subtitle: rule.name)`. When `ruleId == null` (`/rules/new`) it currently shows an `EmptyState` "Nueva regla" / "Disponible pronto." in a shell titled "Regla". `onNewVersion` already calls `createVersion` and selects the new version.
- **Page.** `lib/screens/rules/rule_editor_page.dart`: `RuleEditorPage` (stateless, props plus callbacks) with private sections `_ConditionCard` (read-only `ConditionRow`s plus a disabled `AppSegmentedControl<RuleAction>` "Acción"), `_BacktestCard`, `_ApprovalCard` (`_writeAction()` returns "Iniciar shadow" for DRAFT, "Enviar a aprobación" for SHADOW, "Crear nueva versión" for the latest ACTIVE/RETIRED), `_VersionsCard`, plus helpers `_CardTitle`, `_Caption` and the `_RejectDialog` (a `Dialog` with `AppTextField` plus ghost/primary `AppButton`s). This dialog is the pattern to follow for the discard confirmation.
- **Shared widgets** (`lib/widgets/`, exported by `widgets.dart`):
  - `ConditionRow` (`condition_row.dart`) already has `editable`, `featureNames`, `onFeatureChanged`, `onOpChanged`, `onValueChanged` and `onRemove` (`AppIcons.close`). In editable mode it shows feature/op dropdowns, a value `TextField` that keeps its own controller (synced in `didUpdateWidget`) and the remove icon. It has **no error state** yet.
  - `AppTextField` has `label`, `controller`, `hintText` and `errorText` (red border `AppColors.statusBlock` plus a message).
  - `AppButton` has variants `primary | secondary | ghost | danger`, `icon` and `expand`.
  - Also `AppSegmentedControl`, `AppStepper`, `AppCard`, `RuleStatusBadge` and `AppShell`.
- **Store** (`lib/data/app_store.dart`):
  - `createRule({code, name, description, conditions, action})` returns a `RuleView`. It throws `conflict` for a taken code (checked first), `invalid` for a code that doesn't match `_ruleCodePattern` `^[A-Z][A-Z0-9_]{2,39}$`, `invalid` for an empty name or one over `_maxRuleNameLength`, and `invalid` for empty or invalid conditions.
  - `updateDraft(ruleId, version, {conditions, action})` (DRAFT only, clears the backtest).
  - `deleteDraft(ruleId, version)` (DRAFT only; `conflict` when `rejectionReason != null`; removes the whole rule when that was its only version).
  - `createVersion(ruleId)`, `ruleById` and `ruleByCode`.
  - Condition validity is the private top-level `_isValidCondition`: boolean takes `=`/`!=` with a `bool`; string takes `in` with a `List<String>` or `=`/`!=` with a `String`; number/integer takes any op but `in`, with a `num`.
  - `can(PermissionCode.RULE_WRITE)`.
- **Models.** `lib/data/models/rule.dart`: `Condition(feature, op, value)` with a non-null `Object value`; `ConditionOp` (`gte` symbol "≥", `eq` "=", `inList` "en"…); `RuleAction` with `.label` from `lib/data/labels.dart` ("Revisar", "Bloquear"). `lib/data/models/feature_definition.dart`: `featureCatalog` (name, type `number|integer|boolean|string`), which includes `amount` and `is_night`.
- **Formatting.** `lib/data/format.dart` has formatters only (`formatConditionValue`, `formatInt`…), no parser.
- **Routing.** `lib/app/routes.dart`: `AppRoutes.newRule = '/rules/new'` (guarded by `RULE_WRITE`) maps to `RuleEditorScreen(ruleId: null)`; `AppRoutes.ruleEditor(id)` and `AppRoutes.rules`.
- **Rules list.** `lib/screens/rules/rules_screen.dart` shows tab labels `Todas · n` … `Borradores · n` and `RuleRow`s, computed from `store.rules`, so it updates through `notifyListeners`.
- **Seed** (`lib/data/mock/mock_seed.dart`): 8 rules. ATO_PASSWORD_RESET v1 is the only DRAFT (2 conditions `password_changed_24h = true`, `is_new_device = true`, BLOCK, created by Diego). SCORE_BLOCK has v2 ACTIVE. Users: Laura Méndez and Diego Salazar (RISK_LEAD, have `RULE_WRITE`), Camilo Torres (ANALYST, no `RULE_WRITE`).
- **Tests.** `test/helpers/pump_app.dart` `pumpApp(tester, signInAs:, initialRoute:)` and `test/helpers/harness.dart` `harness()`/`setDesktopView()`.
  - `test/screens/rule_editor_test.dart:554` ("/rules/new is not available yet") asserts "Disponible pronto.".
  - `test/app/navigation_test.dart:111` ("/rules/new opens a new rule") asserts the shell title is "Regla".
  - Both pin the old placeholder.
- **Reference.** Tag `archive/pr-29-flutter-prototype`, `lib/screens/rule_editor_page.dart` (draft-editing parts). Reuse only its ideas, on top of the current data layer.

## Requirements
1. **Editing buffer in the screen.** `RuleEditorScreen` holds, while the shown version is DRAFT and `store.can(PermissionCode.RULE_WRITE)`:
   - a `List<Condition>` buffer
   - a `RuleAction` buffer
   - a `bool dirty`
   - a flag that a save was attempted (to show the incomplete message)

   The buffer is seeded from the shown version and re-seeded whenever the shown rule/version changes: a version switch, `createVersion`, a save, or a discard that selects another version. After a successful save `dirty` is false. On `/rules/new` the screen also owns `TextEditingController`s for code, name and description (disposed in `dispose`) and a `String?` error for code and for name.
2. **Value parsing.** Add a pure top-level `Object parseConditionValue(String feature, ConditionOp op, String text)` to `lib/data/format.dart` (or a new `lib/data/` file next to it), using the feature's type from `featureCatalog`:
   - **boolean:** "sí"/"si"/"true" → `true`, "no"/"false" → `false`, matched case-insensitively after trimming.
   - **number/integer:** digits with optional `.` thousands separators and an optional `,` decimal part become a `num` (`int` when there is no decimal part), so "1.000.000" → `1000000`.
   - **string:** with `in`, comma-separated → `List<String>` of trimmed, non-empty items; otherwise the trimmed text.
   - Anything unparseable (including empty) returns the raw text, which makes the condition incomplete.

   Completeness uses the store's own rule: make `_isValidCondition` in `app_store.dart` public (`isValidCondition`) and call it from the screen. Don't duplicate it.
3. **Callbacks.** `RuleEditorPage` gains the buffer as plain props and these callbacks, all reported up to the screen:
   - `onFeatureChanged(int index, String name)`
   - `onOpChanged(int index, ConditionOp op)`
   - `onValueChanged(int index, String text)`
   - `onRemoveCondition(int index)`
   - `onAddCondition()`
   - `onActionChanged(RuleAction action)`
   - `onSaveDraft()`
   - `onDiscardDraft()`
   - `onCreateRule()`

   The page also needs plain props for the new-rule mode: the three controllers and two error strings, or equivalent values plus `onChanged` callbacks. Each buffer change sets `dirty = true`. When the feature changes, the screen re-parses the row's current value text for the new feature.
4. **Editable DRAFT (existing rule), when `canWrite` and the version is DRAFT.**
   - The Condition card renders `ConditionRow(editable: true, featureNames: featureCatalog names, …)` for each buffered condition, with `onRemove` wired.
   - Below the rows goes a ghost `AppButton` "Agregar condición" with `icon: AppIcons.plus` that appends `Condition('amount', ConditionOp.gte, '')`.
   - The "Acción" `AppSegmentedControl` gets a non-null `onChanged`.
5. **Approval card in editable DRAFT.**
   - "Iniciar shadow" (primary, full width) is disabled (`onPressed: null`) while `dirty`.
   - Below it comes secondary "Guardar borrador" (full width), enabled only when `dirty`. Tapping it with any incomplete condition sets the save-attempted flag and doesn't call the store. Otherwise it calls `store.updateDraft(ruleId, version, conditions:, action:)`.
   - Below that comes danger "Descartar borrador" (full width), shown only when `version.rejectionReason == null`.
6. **Incomplete conditions.** Add an `error` (bool, default `false`) parameter to the shared `ConditionRow`. When true, the value box border uses `AppColors.statusBlock` (the `AppTextField` error style); update its doc comment. In edit mode the row's value box gets `error: true` when the condition is incomplete and a save or create was attempted. Under the condition rows (above "Agregar condición" or directly below the rows) show the caption "Completa todas las condiciones antes de guardar." in `AppTextStyles.caption` with `AppColors.statusBlock`, only after a save or create attempt while some condition is incomplete.
7. **Discard.**
   - "Descartar borrador" opens a dialog built like `_RejectDialog`: heading "¿Descartar este borrador?", body "Esta versión se elimina y no se puede recuperar." (caption/secondary text), and buttons ghost "Cancelar" (pops, nothing happens) and danger "Descartar" (pops and calls `onDiscardDraft`).
   - The screen then calls `store.deleteDraft(ruleId, version)`. If `store.ruleById(ruleId)` is then null it does `pushReplacementNamed(AppRoutes.rules)`. Otherwise it sets `_selected` to the latest remaining version and re-seeds the buffer.
8. **New rule (`/rules/new`).**
   - The shell title is "Nueva regla" and the subtitle "Borrador sin guardar".
   - Actions row: ghost "Reglas" back button (`AppIcons.back`), and an `AppStepper` with "Borrador" current and "Shadow", "Aprobación", "Activa" pending.
   - Left column:
     - an `AppCard` with `_CardTitle` "Datos de la regla" and three `AppTextField`s with a 16 px gap (`AppSpacing.lg`): "Código" (hint "VELOCITY_5M"), "Nombre" (hint "Transferencia nocturna de monto alto") and "Descripción" (hint "Transferencia de noche ≥ $ 2.000.000"), with `errorText` from the screen for code and name;
     - then the Condition card in edit mode, starting with one empty condition `Condition('amount', ConditionOp.gte, '')` and action REVIEW ("Revisar") selected.
     - No backtest card.
   - Right column: an approval card with only primary "Crear borrador" (`expand: true`) and the caption "La regla se crea como borrador v1. Después podrás correr el backtest e iniciar shadow." in `AppColors.textSecondary`. No versions card.
   - The page renders this mode from a plain prop (for example a nullable `view`/`version` or an `isNew` flag) without reading the store.
9. **Create.** On "Crear borrador" the screen validates before calling the store, so no `DomainError` is thrown on bad input:
   - a code (trimmed) not matching `^[A-Z][A-Z0-9_]{2,39}$` → code error "Usa mayúsculas, números y _ (3 a 40 caracteres).";
   - else `store.ruleByCode(code) != null` → code error "Ya existe una regla con ese código.";
   - an empty trimmed name → name error "Escribe un nombre.";
   - any incomplete condition → the conditions message from requirement 6.

   Errors clear when that field next changes or on the next attempt. When everything is valid the screen calls `store.createRule(code:, name:, description:, conditions:, action:)` and then `Navigator.pushReplacementNamed(AppRoutes.ruleEditor(view.rule.id))`. Reuse one code-pattern source: expose the store's pattern (for example make `_ruleCodePattern` public) rather than writing a second regex.
10. **Read-only cases.**
    - A SHADOW, PENDING_APPROVAL, ACTIVE or RETIRED version renders exactly as today: read-only rows, no remove icon, no "Agregar condición", disabled action control, no "Guardar borrador"/"Descartar borrador".
    - A user without `RULE_WRITE` sees a DRAFT the same way, with no draft buttons.
    - All gating uses `store.can(PermissionCode.RULE_WRITE)` passed down as `canWrite`, never role names.
11. **Structure.** Only `*_screen.dart` files under `lib/screens/` reference `AppScope` or `AppStore`. The page, its private sections (in the page file, in an optional `lib/screens/rules/rule_draft_form.dart` for the "Datos de la regla" card, or in `lib/screens/rules/widgets/`) and the shared widgets get everything through constructors and never navigate, except popping their own dialog as `_RejectDialog` does. No gallery component is re-created inline. Colors, spacing, text styles and icons come only from `lib/theme/`.
12. **Copy.** All strings appear exactly as written in this spec (accents, `¿`, `≥`, `·`).
13. **Existing tests.** Update `test/screens/rule_editor_test.dart` ("/rules/new is not available yet") and `test/app/navigation_test.dart` ("/rules/new opens a new rule", which should now expect the title "Nueva regla") to the new behaviour. Keep their intent: the route opens `RuleEditorScreen(ruleId: null)`.
14. **New tests.**
    - `test/screens/rule_drafts_test.dart` covers every acceptance criterion below.
    - Add unit tests for `parseConditionValue` (boolean, "1.000.000", decimal "0,6", `in` list, empty → incomplete) in a test file under `test/data/`.
    - Add a widget test for `ConditionRow(error: true)` in its existing test file under `test/widgets/`.
15. **Docs.** No change to the contract, `model.md` or the feature catalog is needed. Update the `ConditionRow` doc comment for `error`. AGENTS.md needs no change.

## Acceptance criteria
All in `test/screens/rule_drafts_test.dart` unless noted. Run with `flutter test test/screens/rule_drafts_test.dart`.
1. Signed in as Laura Méndez on `/rules/new`, the screen shows "Nueva regla", "Borrador sin guardar", "Datos de la regla", "Código", "Nombre", "Descripción", "Agregar condición" and "Crear borrador", and no "Correr backtest".
   - Entering code "night" and tapping "Crear borrador" shows "Usa mayúsculas, números y _ (3 a 40 caracteres).".
   - With code "SCORE_BLOCK" it shows "Ya existe una regla con ese código.".
   - With a valid unused code and an empty name it shows "Escribe un nombre.".
   - The store still has 8 rules and no exception is thrown.
2. As Laura on `/rules/new`: code "NIGHT_ATM", name "Retiro nocturno", the condition's feature set to `is_night`, op `=`, value "sí", then "Crear borrador". The app shows the shell title "NIGHT_ATM · v1" with a "Borrador" status badge. Navigating to `/rules` shows 9 `RuleRow`s and the tab "Borradores · 2".
3. As Laura on `/rules/new` with valid code and name but the default empty condition, "Crear borrador" shows "Completa todas las condiciones antes de guardar." and no rule is created.
4. As Diego Salazar on ATO_PASSWORD_RESET:
   - "Agregar condición" adds a third editable `ConditionRow`.
   - Typing "1.000.000" into its value (feature `amount`, op `>=`), selecting "Revisar" and tapping "Guardar borrador" leaves the store's v1 with 3 conditions, the third being `amount`/`gte`/`1000000`, and action `RuleAction.REVIEW`.
   - The `/rules` list row for ATO_PASSWORD_RESET shows "Revisar".
5. As Diego on ATO_PASSWORD_RESET:
   - "Guardar borrador" is disabled before any change, and "Iniciar shadow" is disabled after a change and enabled again after saving.
   - Tapping the remove icon on one row and saving leaves the store's v1 with 1 condition.
   - After adding a row and leaving its value empty, "Guardar borrador" shows "Completa todas las condiciones antes de guardar." and the store still has 2 conditions.
6. As Diego on ATO_PASSWORD_RESET:
   - "Descartar borrador" opens "¿Descartar este borrador?" with "Esta versión se elimina y no se puede recuperar.".
   - "Cancelar" closes it and the rule still exists.
   - Doing it again with "Descartar" removes the rule: the route is `/rules`, the title "Reglas" shows, and there are 7 `RuleRow`s.
7. As Laura on SCORE_BLOCK v2 (ACTIVE), there is no remove icon inside any `ConditionRow`, no "Agregar condición" and no "Guardar borrador". After "Crear nueva versión", v3 is shown with editable `ConditionRow`s (`editable == true`), "Agregar condición" and "Guardar borrador". Discarding v3 keeps the rule and selects v2 (title "SCORE_BLOCK · v2").
8. As Camilo Torres on ATO_PASSWORD_RESET, every `ConditionRow` has `editable == false`, and "Agregar condición", "Guardar borrador", "Descartar borrador" and "Iniciar shadow" are absent.
9. A draft with a `rejectionReason` (for example, as Diego: start shadow on ATO_PASSWORD_RESET, run the backtest and submit it, then as Laura reject it with a reason; or set it up directly through store calls) shows "Guardar borrador" but no "Descartar borrador".
10. `grep -rn "AppScope\|AppStore" lib/screens/` matches only files ending in `_screen.dart`. A widget test pumps `RuleEditorPage` alone through `harness()` (no `AppScope`, fake `RuleView`/`RuleVersion` and callbacks) in editable-DRAFT mode, and asserts that tapping "Guardar borrador" calls `onSaveDraft` and tapping "Agregar condición" calls `onAddCondition`. A second pump in new-rule mode asserts that "Crear borrador" calls `onCreateRule`.
11. The `parseConditionValue` unit tests (under `test/data/`) and the `ConditionRow(error: true)` widget test (under `test/widgets/`) pass. The updated tests in `test/screens/rule_editor_test.dart` and `test/app/navigation_test.dart` pass, and `grep -rn "Disponible pronto" lib test` returns nothing.

## Out of scope
- Multi-value `in` editing beyond comma-separated text (no chips or multi-select).
- Editing the code, name or description of an existing rule.
- Deleting versions that aren't DRAFT, or discarding a rejected draft (the button is hidden; don't change `deleteDraft`).
- Rule templates.
- A feature description, tooltip or `allowedValues` picker in the condition row.
- Validating value ranges beyond what `isValidCondition` checks.
- Changing store domain rules, the contract, `model.md`, `features.md` or the seed data.
- Adding a backtest or versions card to the new-rule form, autosave, or an "unsaved changes" prompt when leaving the screen.
- Any change to `factory/checks.sh` or `factory/config.json`.

## Assumptions
- **An incomplete value is stored as the raw text.** It is kept in the buffer's `Condition.value`, which is non-null, and completeness is decided by the store's own `isValidCondition` (made public), so the screen and store never disagree.
- **The code and name checks reuse the store's rules.** Exposing `_ruleCodePattern` keeps one source of truth for the code rule. The name rule is "not empty" as the issue says; the store's max length still guards the call.
- **"Guardar borrador" is enabled whenever `dirty`.** The issue says it is enabled when `dirty` and every condition is complete. But it also asks for the incomplete message "when saving is attempted", which needs the button to be tappable while a condition is incomplete. So the tap with incomplete conditions shows the message instead of saving.
- **The title on `/rules/new` is "Nueva regla", not "Regla".** The issue specifies that title for the top bar, so the old navigation test expectation changes.
- **Changing the feature re-parses the current value text.** For example, "sí" stays valid only for boolean features. This reuses the same parser, so there are no stale typed values.
- **Discarding a draft that isn't the only version** (for example v3 of SCORE_BLOCK) selects the latest remaining version, as the issue says, and stays on the editor.
- **Field errors clear on the next edit of that field.** This is the usual form behaviour; the issue doesn't specify when they clear.
