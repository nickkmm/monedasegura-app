DECISION: ACCEPT
RISK: medium
SURFACES: ui, security
RESCOPED: yes

## Summary
- Accepted: the rule editor is on the MVP screen list, and the store operations it needs already exist from #15.
- Three acceptance criteria can't pass as written, because they contradict the issue's own rules or the seed data (criteria 2, 6 and 7).
- I chose a reading for each one instead of holding the job. They are listed under Scope, so please correct any of them here or on the PR.
- Criterion 4 also needs the rules list (#21), which isn't a listed dependency and whose PR #47 was still open in the local job record.
- No change is needed to the contract, data model or feature catalog.

## Scope
Build the rule editor as the issue specifies: `RuleEditorScreen` as host, `RuleEditorPage` with plain data and callbacks, the top bar, actions row and stepper, the condition, backtest, approval and versions cards, and the lifecycle actions. All values and copy come from the issue, except for these changes.

**Criteria changed from the issue:**

1. **Criterion 2, recall.** "0,74 → 0,77" and the required formula give +3,0 pp, but the criterion expects "+3,1 pp". To keep all the on-screen text, change the NIGHT_TRANSFER v2 seed to `systemRecallBefore` 0.742 and `systemRecallAfter` 0.773, and update the two matching expectations in `test/data/mock_seed_test.dart`. These still display as "0,74 → 0,77", and the difference is +3,1 pp.
2. **Criterion 6, approver.** The issue says to show the first of `store.approversFor(version)`, but for Laura's version that is Valentina Ríos, not Diego Salazar. Valentina is an ADMIN with `RULE_APPROVE`, and `test/data/app_store_rules_test.dart` pins that order. Follow the rule: as Laura Méndez there is no "Aprobar y activar", and the approver box shows "Valentina Ríos". Don't filter by role or reorder the seed users to reach Diego.
3. **Criterion 7, backtest gate.** FAR_FROM_HOME v1 already has a seeded backtest, which `mock_seed_test.dart` pins and the rules list needs for its "0,33". So "Enviar a aprobación" is never disabled on that route. Test the behaviour in two parts, both as Laura Méndez:
   - ATO_PASSWORD_RESET (DRAFT, no backtest): "Iniciar shadow", then "Enviar a aprobación" is disabled with its caption, then "Correr backtest" enables it, and submitting makes the version "Pendiente".
   - FAR_FROM_HOME: "Volver a correr" shows, "Enviar a aprobación" is enabled, and submitting makes the version "Pendiente".

**Readings where the issue is silent:**

- **Criterion 4, rules list.** If #21 is on the base branch when the build starts, assert NIGHT_TRANSFER as "Activa" on the list. If not, assert that the store shows v2 as ACTIVE, and say in the PR that the list check is still to do.
- **Criterion 9, "no action buttons".** This means lifecycle actions. The ghost "Reglas" back button stays, because it is navigation.
- **Backtests without recall.** Only NIGHT_TRANSFER v2 has recall values in the seed, and only it has `active` counts. When recall is missing, the "Recall total" tile shows "—" with no note.
- **Empty backtest.** With no backtest, leave out the "Sobre … casos etiquetados" caption.
- **Number and grammar in the shadow text.** Format `matched` with `formatInt` ("1.102 coincidencias"), and use the singular for one day ("1 día en shadow", "1 día"), since FAR_FROM_HOME is at one day.

**Left out, as the issue says:** creating a rule, editing conditions, discarding drafts, shadow statistics charts and comparing versions. `ruleId == null` keeps the "Nueva regla" empty state until the next task.

## Why
`docs/MVP_PLAN.md` §6 lists this screen, and `model.md` §6 and `decision-api.yaml` already cover the lifecycle, including return to draft. `AppStore` already has the operations, `canApprove` and `approversFor`, and the four-eyes rule is enforced there, so this PR is presentation and wiring. The conflicts come from `lib/data/mock/mock_seed.dart` (the recall values, the user order and the FAR_FROM_HOME backtest), and each has a small fix that a reviewer can easily change.

I rated risk medium because the screen drives the approval flow across many states and users. The security surface is the permission and four-eyes gating of its actions.

My local checkout is behind `origin/develop` and this job's worktree doesn't exist yet, so I read the shared widgets, store and seed in the #21 job's worktree. The build should confirm that `AppStepper`, `TimelineEvent`, `ConditionRow`, `MetricTile` and the other widgets from #16 are on the base branch, and stop if they aren't rather than re-create them.
