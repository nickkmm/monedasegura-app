DECISION: ACCEPT
RISK: medium
SURFACES: ui, security
RESCOPED: yes

## Summary
- Accepted: creating, editing and discarding rule drafts in the rule editor, as the issue specifies.
- Both dependencies are merged: #22 (rule editor, PR #51) and #15 (store rule operations, PR #37). `createRule`, `updateDraft`, `deleteDraft` and `createVersion` already enforce the domain rules.
- I checked the acceptance criteria against the seed: 8 rules with one DRAFT (ATO_PASSWORD_RESET v1, 2 conditions, BLOCK, created by Diego), so the "9 rules / Borradores · 2", "3 conditions" and "7 rules" counts all hold.
- One small rescope: "Descartar borrador" is hidden for a draft that came back from a rejection, because `deleteDraft` refuses those (decided in #15).
- No change is needed to the contract, data model or feature catalog.

## Scope
Build what the issue specifies, with its copy, values and acceptance criteria (`test/screens/rule_drafts_test.dart`):

- **Editing buffer in `RuleEditorScreen`.** While the selected version is DRAFT and `store.can(RULE_WRITE)`, the screen holds the conditions, the action, a dirty flag and, on `/rules/new`, the code, name and description fields with their per-field errors. The page shows the buffer and reports each change through the callbacks the issue lists. Text values are parsed by the feature's type from `featureCatalog`, as the issue says. For `in`, a comma-separated text becomes a list of strings.
- **Editing an existing DRAFT.** Editable condition rows with a remove icon, "Agregar condición" (adds `amount` `>=` with an empty value), an editable "Acción" control, and "Guardar borrador" / "Descartar borrador" in the approval card. "Iniciar shadow" is disabled while there are unsaved changes. An incomplete condition shows the input error style and, after a save attempt, the caption "Completa todas las condiciones antes de guardar.". Discarding asks for confirmation first. After a discard the screen goes to `/rules` if the rule is gone, or otherwise selects the latest remaining version.
- **New rule (`/rules/new`).** This replaces the "Nueva regla" empty state that #22 left. It has the "Datos de la regla" card with three fields, a condition card in edit mode with one empty condition, action "Revisar", no backtest card, and an approval card with only "Crear borrador" and its caption. The screen checks the input itself before calling `store.createRule` (code pattern, taken code, empty name, incomplete conditions), so the field errors appear without exceptions. On success it goes to `/rules/<new id>`.
- **Read-only cases.** SHADOW, PENDING_APPROVAL, ACTIVE and RETIRED versions, and any user without `RULE_WRITE`, see no editing controls and no draft buttons.
- **The rescope.** A DRAFT with a `rejectionReason` (one that came back from approval) can still be edited and saved, but "Descartar borrador" is not shown for it. `deleteDraft` throws `conflict` for such drafts, as decided in #15.
- **Structure.** Only the screen reads the store or navigates. The page and its sections get data and callbacks through their constructors. Any missing reusable piece goes once into `lib/widgets/`, which covers criterion 8.

**Left out, as the issue says:** multi-value `in` lists beyond comma-separated text, editing the code or name of an existing rule, deleting versions that aren't drafts, and rule templates.

## Why
`docs/MVP_PLAN.md` §6 lists the rule editor, and this is the editing half that #22 deliberately left out. The store operations from #15 already enforce permissions and the lifecycle of `model.md` §6, so this PR is presentation, an input buffer and wiring. I checked the criteria against the rules in `lib/data/mock/mock_seed.dart` and the #15 spec (the code pattern, the `conflict` for a taken code, and `deleteDraft` removing the whole rule when it has only one version). I rated risk medium because the change spans the screen, the page and the shared widgets, and the security surface is gating by `RULE_WRITE` plus user input reaching the store.

My local checkout is behind `origin/develop` and the job worktree didn't exist yet, so I couldn't read #22's editor code directly. The build should confirm that `RuleEditorScreen`, `RuleEditorPage`, `ConditionRow` (with an editable mode), `AppSegmentedControl`, `AppTextField` and `AppButton` are on the base branch. If the editable form of `ConditionRow` is missing, add it to that shared widget rather than creating a new one inline.
