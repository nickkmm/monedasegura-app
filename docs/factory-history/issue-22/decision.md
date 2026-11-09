ESCALATE

## Summary
- Round 2 made the four changes from feedback 1, and all of them are in the code. The gate, all four reviews and CI on `cee1ad2` pass.
- The recall tile, the "últimos 30 días" heading, the approver and criterion 7 were settled by @Gomaxd11 in feedback 1, so they are no longer open questions.
- I still recommend not merging yet. This screen exposes the approval flow, and no person has confirmed the permission gating. Feedback 1 didn't cover it.
- No one has walked through the screen in a browser yet. That walk-through can also confirm the gating.

## Why
The build meets its spec as amended by feedback 1, and the change stays inside intake's Scope. The project's check for anything touching permissions still applies, and only a person can clear it. The contract difference also remains in the code, but a person has accepted it for the prototype.

## Acceptance criteria
Numbering follows the spec, which replaces the issue's wording for criteria 2, 6 and 7. Unless noted, the evidence is the named widget test in build.md. I re-ran `rule_editor_test.dart`, `mock_seed_test.dart` and `navigation_test.dart` at `cee1ad2`, and all 82 tests passed. The gate and CI ran the full suite.

1. Header and condition: met, by the widget test.
2. Backtest: met, by the widget test, using the seed values 0.742 and 0.773 so that "+3,1 pp" and "0,74 → 0,77" both read correctly. The tile and the heading differ from the contract, as accepted in feedback 1.
3. Approval and versions: met, by the widget test. The pending event reads "Esperando a otra persona con permiso para aprobar" instead of the spec's text, as feedback 1 asked (`rule_editor_page.dart:438`).
4. Approve: met. I read the test: after approving, it taps "Reglas" and asserts that the NIGHT_TRANSFER `RuleRow` shows "Activa" and not "Pendiente". The conditional from round 1 no longer applies.
5. Return to draft: met, by the widget tests.
6. Four eyes: met as rewritten by intake and confirmed in feedback 1. Laura has no approve or return buttons and sees "Valentina Ríos"; Diego can approve. I also read `canApprove` and `approversFor`, and both exclude the creator.
7. Backtest gate: met as rewritten by intake and accepted in feedback 1, on ATO_PASSWORD_RESET and FAR_FROM_HOME.
8. New version: met, by the widget test.
9. Read-only user: met, by the widget test on all four rules.
10. Selection: met, by the widget test.
11. Without data: met, by the widget tests.
12. Empty states: met. `navigation_test.dart` isn't in the branch's diff and passes.
13. Page isolation: met. I ran the grep, and in `lib/screens/` it matches only `*_screen.dart` files. The page-alone test passes.
14. Seed: met. I re-ran `mock_seed_test.dart`.
15. Formatter: met. I ran the grep on `condition_row.dart` and it finds nothing. `formatConditionValue` is in `format.dart`.

Other results:
- Round 2 `checks.md` says `GATE: PASS` at `cee1ad2`, which is the branch head. All four round 2 reviews are `VERDICT: PASS`.
- The code review's one note, about the PR body's "Still to do", is resolved: that section is gone. The other notes describe no blocking problem, and the ones worth a person's time are listed below.
- CI's `ci` check succeeded on `cee1ad2`. The PR is mergeable and the branch has no commits missing from `origin/develop`.
- Outside the factory record, the diff touches only the screen and page, the formatter move, the seed fix and their tests. The formatter move comes from the spec, not intake's Scope, and doesn't change `ConditionRow`'s behaviour.
- There are no dependency, CI, deploy, Docker, migration or environment variable changes.

## For the human
Recommendation: don't merge yet

**Reason: the change touches permissions, and a person hasn't checked them yet.** It doesn't change the store's rules, the route guards or `model.md`. It is the first screen to expose the approval flow, using `store.can(RULE_WRITE)` and `store.canApprove`.

**What I need from you**

1. **Confirm the gating matches `model.md` §4 and §6.** The automated evidence is good: the widget tests cover Valentina, Laura, Diego and Camilo, and the store checks permissions again on each action. This check is the one thing blocking my recommendation.
2. **Decide who may return a version to draft.** `reject` requires `RULE_APPROVE` but, unlike `approve`, doesn't refuse the version's creator. The UI hides the button from the creator, so this branch doesn't expose the gap, and the store code isn't changed here. The `model.md` §6 table has no `PENDING_APPROVAL` to `DRAFT` step, although `decision-api.yaml` has `rejectRuleVersion`. This doesn't have to block the merge, but it should be settled in `monedasegura-infra` before the real API work.
3. **Walk through the screen.** Run `flutter run -d chrome` and try approve, return to draft and new version as Valentina, Laura, Diego and Camilo. No agent has seen this screen running in a browser. Also check:
   - The new pending event text at 1440 px. It wraps to two lines and wasn't rendered in round 2.
   - The metric tiles at 1280 px, where the notes may wrap to three or four lines.

**Already decided, for the record**

Feedback 1 kept the recall tile and the "últimos 30 días" heading for the prototype, with no PR against `monedasegura-infra`. `AGENTS.md` says the documents win, so this is a deliberate exception:
- `Backtest` in `decision-api.yaml` has no recall fields, so once the real API is connected this tile can only show "—".
- `runBacktest` evaluates "every resolved `fraud_case`", not a 30-day window.

**Smaller gaps, not blocking on their own**

- Version rows use `GestureDetector`, with no keyboard focus or button semantics. The UI and UX reviews note this, and the UI review says the rest of the console has the same gap.
- The "Motivo" field has no 1000-character limit. A longer reason shows the generic error and the typed text is lost.
- "Aprobar y activar" activates at once, with no confirmation, as specified.
- "Sin fraudes nuevos frente a la versión activa" and "No se pudo completar la acción." are new copy, not from the issue.
- The PR body's "CI passes" box is still unticked, although CI is green.

**Files to look at**

- `lib/screens/rules/rule_editor_screen.dart`: permission flags and approver selection
- `lib/screens/rules/rule_editor_page.dart`: `_ApprovalCard` and `_writeAction`
- `lib/data/app_store.dart`: `approve`, `reject`, `canApprove` and `approversFor` (not changed by this branch)
- `test/screens/rule_editor_test.dart`: the four-eyes and read-only user tests
- `monedasegura-infra/docs/model.md` §4 and §6, and `monedasegura-infra/docs/api/decision-api.yaml`: `rejectRuleVersion`
