ESCALATE

## Summary
- Rule editor: users with `RULE_WRITE` can now edit, save and discard a DRAFT version's conditions and action. `/rules/new` is now the "Nueva regla" form, which creates a v1 draft.
- The screen owns the editing buffer, the validation, the store calls and the navigation. The page and its sections only get props and callbacks.
- Gate PASS (442 tests, analyze and web build clean). All four reviews PASS, and none of their Notes describes a real problem.
- I ran `test/screens/rule_drafts_test.dart` myself: 14 of 14 pass.
- ESCALATE because this project always has a person merge. Recommendation: merge.

## Why
Every spec acceptance criterion has a named test, and I checked the code behind several of them. The change stays inside intake's Scope, including the one rescope (no "Descartar borrador" on a rejected draft). It doesn't change the contract, the data model, the feature catalog, migrations, environment variables, `docker-compose.yml`, dependencies, CI, JWT, the scoring token or the simulator's access rule.

## Acceptance criteria
1. New-rule form and field errors: met. Test `new rule shows the form and checks the fields`. `_createRule` checks `ruleCodePattern`, then `ruleByCode`, then the empty name, before it calls the store.
2. Creating NIGHT_ATM opens "NIGHT_ATM · v1" as a draft, and the list shows 9 rules and "Borradores · 2": met. Test `creating a valid rule opens it and lists it`, which passed in my run.
3. An empty default condition blocks creating: met. Test `an empty condition blocks creating`. `_complete` uses the store's own `isValidCondition`.
4. Adding a condition with "1.000.000", choosing "Revisar" and saving stores 3 conditions and REVIEW: met. The test passed. `parseConditionValue` turns "1.000.000" into `1000000`, and the format unit tests cover this.
5. Save state, removing a row, empty value: met. I checked the code: "Iniciar shadow" is wired `dirty ? null : onStartShadow` and "Guardar borrador" `dirty ? onSaveDraft : null` (`rule_editor_page.dart:740,752`). An incomplete save sets `_attempted` and doesn't call the store.
6. The discard dialog, then Cancelar or Descartar, goes to `/rules` with 7 rules: met. Test `discarding asks first and then removes the rule`. `_discardDraft` goes to `/rules` when the rule is gone and otherwise selects the latest remaining version.
7. On SCORE_BLOCK v2 (ACTIVE) nothing is editable; v3 is editable; discarding v3 shows v2: met. Test `an active version is read-only, a new one is editable`. `editing = canWrite && status == DRAFT`.
8. Camilo (no `RULE_WRITE`) gets read-only rows and no draft buttons: met. Test `without RULE_WRITE a draft is read-only`.
9. A rejected draft can be saved but not discarded: met. Test `a rejected draft can be saved but not discarded`, and the code checks `if (version.rejectionReason == null)` at `rule_editor_page.dart:754`.
10. Structure: met. I ran `grep -rn "AppScope\|AppStore" lib/screens/ | grep -v _screen.dart` and it printed nothing. The two page-alone tests pass.
11. Parser and `ConditionRow(error)` tests, updated old tests, no "Disponible pronto": met. I ran the grep and it printed nothing, and checks.sh passed the full suite.

## For the human
Recommendation: merge

- None of the project's hold-for-review triggers apply. There's no change to `monedasegura-infra/docs/`, no migration, no environment variable, no `docker-compose.yml` change, no new dependency, and nothing in JWT, the scoring token or the simulator rule.
- Permissions are not changed. The new edit controls are only shown or hidden with the existing `store.can(PermissionCode.RULE_WRITE)` (no role names). The store still enforces `RULE_WRITE` and DRAFT status inside `createRule`, `updateDraft` and `deleteDraft`. Please read the `editing` line in `lib/screens/rules/rule_editor_screen.dart` (inside `build`) to confirm the gating is what you expect.
- The copy is fixed by the issue as a prototype decision, because Figma has no create or draft-editing state. Walk through it with `flutter run -d chrome`: `/rules/new` as Laura, ATO_PASSWORD_RESET as Diego, and the same rule as Camilo.
- Two small UX notes from the reviews, neither blocking:
  - Nothing on screen explains why "Iniciar shadow" is disabled while there are unsaved changes.
  - On `/rules/new` the incomplete-conditions message sits in the left column, far from "Crear borrador".
- Files to look at:
  - `lib/screens/rules/rule_editor_screen.dart`
  - `lib/screens/rules/rule_editor_page.dart`
  - `lib/data/format.dart` (`parseConditionValue`)
  - `lib/widgets/condition_row.dart`
  - `lib/data/app_store.dart` (two helpers made public, behaviour unchanged)
  - `test/screens/rule_drafts_test.dart`
