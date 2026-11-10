STATUS: READY

# Build: Create, edit and discard rule drafts

## Summary
- DRAFT versions can now be edited by users with `RULE_WRITE`: editable rows, "Agregar condición", an editable action control, and "Guardar borrador" and "Descartar borrador" (with a confirmation dialog). "Iniciar shadow" is disabled while there are unsaved changes.
- `/rules/new` is now the "Nueva regla" form. The screen validates code, name and conditions before it calls `createRule`, then opens the new rule.
- The screen owns the buffer and does all store calls and navigation. The page only gets props and callbacks.
- The store's condition check and code pattern are now public (`isValidCondition`, `ruleCodePattern`) and the new `parseConditionValue` reuses them. `ConditionRow` has an `error` flag.
- "Descartar borrador" is hidden for a draft that has a `rejectionReason`, as the spec rescoped.

## Changes
- `lib/data/app_store.dart`: renames `_isValidCondition` to `isValidCondition` and `_ruleCodePattern` to `ruleCodePattern` (both now public). No change to behaviour.
- `lib/data/format.dart`: adds `parseConditionValue(feature, op, text)`, typed by `featureCatalog`. Booleans read sí/si/true/no/false. Numbers allow `.` thousands separators and a `,` decimal and come back as `int` when there is no decimal part. Strings: `in` splits on commas, otherwise the text is trimmed. Unparseable text comes back raw. Also adds `conditionValueText(value)`, the "as typed" text that was private in `ConditionRow`.
- `lib/widgets/condition_row.dart`: adds `error` (red `AppColors.statusBlock` value border) and updates the doc comment. It now uses `conditionValueText`. When the parent sends a new value, typed text that already parses to it (for example "1.000.000" for 1000000) is no longer overwritten.
- `lib/screens/rules/rule_editor_page.dart`: `view`/`version` are nullable now; `null` means the new-rule form. New props: the buffer (`draftConditions`, `draftAction`, `dirty`, `conditionErrors`, `showConditionsError`), the nine callbacks from the spec, and the new-rule controllers, errors and `onChanged` callbacks.
  - `_ConditionCard` becomes editable.
  - New `_RuleDataCard` ("Datos de la regla") and `_CreateCard` ("Crear borrador" plus caption).
  - `_ApprovalCard` adds save and discard for an editable DRAFT.
  - New `_DiscardDialog`, built like `_RejectDialog`.
  - The new-rule stepper is Borrador current, the rest pending.
- `lib/screens/rules/rule_editor_screen.dart`: holds the buffer and seeds it from the shown version whenever the shown version number changes, or after a save or discard (`_seeded` is reset). Changing the feature or op re-parses the row's current text.
  - Save checks completeness first, using `isValidCondition` and treating an empty list as incomplete.
  - Discard goes to `/rules` when the rule is gone, otherwise it selects the latest remaining version.
  - Create validates against `ruleCodePattern`, `ruleByCode` and an empty name, then calls `createRule` and `pushReplacementNamed(ruleEditor(id))`.
  - On `/rules/new` the title is "Nueva regla" and the subtitle "Borrador sin guardar". The controllers are disposed in `dispose`.
- `test/screens/rule_drafts_test.dart` (new): 14 widget tests for acceptance criteria 1 to 10.
- `test/data/format_test.dart`: `parseConditionValue` and `conditionValueText` unit tests.
- `test/widgets/condition_row_test.dart`: tests for `error: true` and for keeping typed text.
- `test/screens/rule_editor_test.dart`: the page-alone helper passes the new callbacks. The test "/rules/new is not available yet" becomes "/rules/new opens the new-rule form".
- `test/app/navigation_test.dart`: "/rules/new opens a new rule" now expects the title "Nueva regla" and still checks `RuleEditorScreen(ruleId: null)`.

## Acceptance criteria
1. [x] New-rule form and field errors: test `new rule shows the form and checks the fields` in rule_drafts_test.
   - It finds all the listed texts and no "Correr backtest".
   - Codes "night" and "SCORE_BLOCK", and a valid code with an empty name, show each error.
   - The store has 8 rules and `takeException()` is null.
2. [x] Creating NIGHT_ATM: test `creating a valid rule opens it and lists it`.
   - It picks `is_night` and `=`, types "sí", and sees the title "NIGHT_ATM · v1" with a DRAFT `RuleStatusBadge`.
   - The store has `is_night`/`eq`/`true` with action REVIEW.
   - `/rules` shows 9 `RuleRow`s and "Borradores · 2".
3. [x] An empty default condition blocks creating: test `an empty condition blocks creating`. It shows the message, the row has `error == true`, and the store still has 8 rules.
4. [x] Diego adds a condition: test `adds a condition and saves it with the action`.
   - A third editable row appears.
   - Typing "1.000.000", choosing "Revisar" and saving leaves v1 with 3 conditions, the third `amount`/`gte`/`1000000`, and REVIEW.
   - The list row shows "Revisar".
5. [x] Save state, remove and empty value:
   - Test `save follows changes and shadow waits for the save`: save is disabled before a change, shadow is disabled after a change, and shadow is enabled again after saving.
   - Test `removing a row and saving keeps one condition`: v1 is left with 1 condition.
   - Test `an empty value blocks saving`: the message shows and the store still has 2 conditions.
6. [x] Discard dialog: test `discarding asks first and then removes the rule`.
   - The heading and body show.
   - "Cancelar" keeps the rule.
   - "Descartar" goes to route `/rules` with the title "Reglas" and 7 `RuleRow`s.
7. [x] SCORE_BLOCK: test `an active version is read-only, a new one is editable`.
   - v2 has no close icon in any row, no "Agregar condición", no "Guardar borrador", and a disabled action control.
   - After "Crear nueva versión", v3 has editable rows and both buttons.
   - Discarding v3 keeps the rule and shows "SCORE_BLOCK · v2".
8. [x] Camilo: test `without RULE_WRITE a draft is read-only`. All rows have `editable == false`, and the four buttons are absent.
9. [x] Rejected draft: test `a rejected draft can be saved but not discarded`. It sets up the rejection through store calls (Diego: shadow, backtest, submit; Laura: reject). "Guardar borrador" is present and "Descartar borrador" is absent.
10. [x] Structure:
    - `grep -rn "AppScope\|AppStore" lib/screens/ | grep -v "_screen.dart"` prints nothing.
    - Page-alone tests `an editable draft reports save and add` and `the new-rule form reports create` pump `RuleEditorPage` through `harness()` with fakes and record the callbacks `saveDraft`, `addCondition` and `createRule`.
11. [x] The `parseConditionValue` group in `test/data/format_test.dart` passes (boolean, "1.000.000", "0,6", `in` list, empty is incomplete). So do `error turns the value border red` in `test/widgets/condition_row_test.dart`, the updated rule_editor and navigation tests, and `grep -rn "Disponible pronto" lib test`, which prints nothing.

## Validation
- `flutter test test/screens/rule_drafts_test.dart`: passed (14 tests).
- `flutter test test/data/format_test.dart test/widgets/condition_row_test.dart`: passed.
- `flutter test test/screens/rule_editor_test.dart test/app test/widgets/condition_row_test.dart test/screens/rules_test.dart`: passed.
- `bash factory/checks.sh` from the worktree: exit 0 (pub get, `dart format --set-exit-if-changed`, `flutter analyze` with no issues, `flutter test` with 442 tests passing, `flutter build web --release`).
- Both greps from criteria 10 and 11 printed nothing.

## Log
### Round 1
- Implemented the spec from scratch in three commits: data layer (parser and public store checks), the `ConditionRow` error state, and the editor screen, page and tests. Pushed and opened draft PR #54.
- Design notes:
  - Changing the op also re-parses the value text, because parsing depends on the op (`in`).
  - An empty conditions list counts as incomplete, so the user sees the message instead of a store `invalid` SnackBar.
  - `ConditionRow` keeps typed text that already parses to the new value, so typing "1.000.000" isn't rewritten to "1000000" on every keystroke.
  - The create card has no title, as "only" in requirement 8 suggests.
  - `isValidCondition` still accepts an empty string for `=` on a string feature, and I left it that way (the spec says not to duplicate or change it).
