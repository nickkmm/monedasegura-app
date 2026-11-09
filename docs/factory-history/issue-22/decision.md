ESCALATE

## Summary
- The rule editor is built and works against the in-memory store. The gate and all four reviews passed, and CI on PR #51 is green.
- I recommend not merging yet. The screen shows backtest data that `decision-api.yaml` doesn't have, and it gates the approval actions by permission and four-eyes, so a person has to check both.
- Intake rewrote three of the issue's acceptance criteria. The approver shown to Laura is "Valentina Ríos", not the issue's "Diego Salazar", and that needs confirming.
- #21 is now on `develop`, so the branch's test for criterion 4 is out of date. I ran the missing list check on a temporary merged copy and it passes.

## Why
The build meets its spec, and the code keeps the page free of store access with every action going through the store. Two project checks still apply: the "Recall total" tile and the "últimos 30 días" heading differ from the contract, and the change touches permission and four-eyes gating. Intake said no contract change was needed, and no review raised the difference, so a person should decide it.

## Acceptance criteria
Numbering follows the spec, which replaces the issue's wording for criteria 2, 6 and 7. Build evidence is the named tests. I re-ran `rule_editor_test.dart`, `mock_seed_test.dart` and `navigation_test.dart` on the branch, and all passed. I also read the page and screen against the spec.

1. Header and condition: met, by the widget test.
2. Backtest: met, by the widget test, through a seed change to 0.742 and 0.773 so that "+3,1 pp" and "0,74 → 0,77" both read correctly. The recall values aren't in the contract (see below).
3. Approval and versions: met, by the widget test.
4. Approve: met under the spec's conditional, but out of date. The branch test asserts the store because `RulesScreen` was a stub at build time, and its comment still says so. PR #47 has since merged. On a temporary copy of the branch merged with `origin/develop`, a throwaway test approved v2, tapped "Reglas", and the NIGHT_TRANSFER row showed "Activa" and not "Pendiente". That test isn't in the PR.
5. Return to draft: met, by the widget tests.
6. Four eyes: met as rewritten by intake. Laura has no approve or return buttons and sees "Valentina Ríos"; Diego can approve. The issue says "Diego Salazar", so this differs from the issue's text.
7. Backtest gate: met as rewritten by intake, on ATO_PASSWORD_RESET and FAR_FROM_HOME.
8. New version: met, by the widget test.
9. Read-only user: met, by the widget test on all four rules.
10. Selection: met, by the widget test.
11. Without data: met, by the widget tests.
12. Empty states: met. `navigation_test.dart` is unchanged and passes.
13. Page isolation: met. I ran the grep myself, and `lib/screens/` matches only `*_screen.dart` files. The page-alone test passes.
14. Seed: met. I re-ran `mock_seed_test.dart`.
15. Formatter: met. I ran the grep on `condition_row.dart` and it finds nothing. `formatConditionValue` is in `format.dart`.

Other results:
- The final round says `GATE: PASS`, and all four reviews are `VERDICT: PASS`.
- The change stays inside intake's Scope. No dependency, CI, deploy, Docker, migration or environment variable changes.
- The branch merges cleanly with `origin/develop`. On that merged copy, `rules_test.dart`, `rule_editor_test.dart` and `mock_seed_test.dart` pass. I didn't run the full suite there.

## For the human
Recommendation: don't merge yet

**Reasons, from the project's checks**

1. **The screen differs from the contract.** The issue asks for both of these, but `monedasegura-infra/docs/` doesn't support them, and `AGENTS.md` says the documents win.
   - "Recall total" reads `systemRecallBefore` and `systemRecallAfter`. The `Backtest` schema in `decision-api.yaml` has neither field, and `lib/data/models/rule.dart` marks them "Prototype-only". Once the real API is connected, this tile can only show "—".
   - "Backtest · últimos 30 días" names a window, but the contract's `runBacktest` evaluates "every resolved `fraud_case`".
2. **It touches permissions.** The change doesn't alter the store's rules, but this is the first screen that exposes the approval flow, using `store.can(RULE_WRITE)` and `store.canApprove`. Please confirm the gating matches `model.md` §4 and §6.

**Decisions I need from you**

1. **Contract:** either add the recall fields and the 30-day window to `decision-api.yaml` with a PR against `monedasegura-infra`, or change the tile and the heading here.
2. **Approver:** is "Valentina Ríos" right for criterion 6? She is an ADMIN with `RULE_APPROVE`, and first in `approversFor`, so the code follows the rule and `model.md`. The timeline above her name still says "Esperando a otro líder de riesgo", and she isn't one.
3. **Criterion 7:** do you accept that the disabled "Enviar a aprobación" is tested on ATO_PASSWORD_RESET, because FAR_FROM_HOME already has a seeded backtest?
4. **Criterion 4:** should the test assert the `/rules` list before merging, now that #21 is on `develop`? It's a small change, and it would remove the out-of-date comment and the PR body's "Still to do".

**Please check by hand**

- Run `flutter run -d chrome` and walk through approve, return to draft and new version as Valentina, Laura, Diego and Camilo. No agent has seen this running in a browser.
- At 1280 px, check the metric tiles, whose notes may wrap to three or four lines (from the UI review).

**Smaller gaps, not blocking on their own**

- Version rows use `GestureDetector`, with no keyboard focus or button semantics. The UI and UX reviews note the same gap elsewhere in the console.
- The "Motivo" field has no 1000-character limit. A longer reason shows the generic error and the typed text is lost.
- "Aprobar y activar" activates at once, with no confirmation, as specified.
- "Sin fraudes nuevos frente a la versión activa" and "No se pudo completar la acción." are new copy, not from the issue.

**Files to look at**

- `lib/screens/rules/rule_editor_page.dart`: `_recallTile`, the backtest card heading, and `_ApprovalCard`
- `lib/screens/rules/rule_editor_screen.dart`: permission flags and approver selection
- `lib/data/models/rule.dart`: the prototype-only recall fields
- `lib/data/mock/mock_seed.dart`: NIGHT_TRANSFER v2 recall
- `test/screens/rule_editor_test.dart`: "approving activates v2 and keeps it selected"
- `monedasegura-infra/docs/api/decision-api.yaml`: the `Backtest` schema and `runBacktest`
