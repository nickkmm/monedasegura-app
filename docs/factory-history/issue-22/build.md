STATUS: READY

# Build: Rule editor: view a version and move it through its lifecycle

## Summary
- `/rules/<id>` shows the stepper, condition, backtest, two-step approval and versions for the selected version.
- The screen performs every lifecycle action (shadow, backtest, submit, approve, return to draft, new version); the page only shows data and reports callbacks.
- Round 2 merges `origin/develop`, which brings in the rules list (#21).
- The approve test now checks that NIGHT_TRANSFER reads "Activa" on `/rules`, so nothing is left to do on criterion 4.
- The pending event now reads "Esperando a otra persona con permiso para aprobar". Valentina Ríos stays as the approver shown to Laura.

## Changes
- `lib/screens/rules/rule_editor_screen.dart`: now a stateful host. It owns the selected version, derives `canWrite`, `canApprove`, `approver` and `creator`, performs the store calls and navigation, and turns a `DomainError` into a `SnackBar`.
- `lib/screens/rules/rule_editor_page.dart` (new): `RuleEditorPage` with the actions row and the condition, backtest, approval and versions cards, plus the private return-to-draft dialog. It takes constructor data and callbacks only. Round 2 changed the pending timeline title.
- `lib/data/format.dart`: new public `formatConditionValue(feature, value)` holding the COP feature set.
- `lib/widgets/condition_row.dart`: calls the helper instead of its private `_displayValue`. Behaviour is unchanged.
- `lib/data/mock/mock_seed.dart`, `test/data/mock_seed_test.dart`: NIGHT_TRANSFER v2 recall is 0.742 and 0.773.
- `test/screens/rule_editor_test.dart` (new): 26 widget tests for the criteria below. Round 2 updated the pending title and replaced the approve test's store assertions and stale comment with a check of the `/rules` list.
- `test/data/format_test.dart`: cases for the moved helper.

Choices the spec leaves open:
- Version rows have 8 px of horizontal padding, so the selected background doesn't touch the text.
- The four metric tiles share one height (`IntrinsicHeight`), because the notes wrap to different line counts.
- The dialog is 420 wide.

## Acceptance criteria
Unless noted, the evidence is a passing widget test in `test/screens/rule_editor_test.dart`, re-run in round 2 through `factory/checks.sh`. The test names are quoted.

1. [x] Header and condition: "shows the header, stepper and condition" asserts the title, subtitle, back button, stepper labels and states (done, done, current, pending), condition rows and read-only action control.
2. [x] Backtest: "shows the backtest and the shadow banner" asserts every listed value, including "+3,1 pp", "0,74 → 0,77" and the banner, and that "Volver a correr" has a null `onPressed`.
3. [x] Approval and versions: "shows the approval timeline and the versions" asserts the timeline, the approver box, both buttons, and v2 above v1 with their summaries and badges. Per feedback 1, the pending event reads "Esperando a otra persona con permiso para aprobar" instead of the spec's "Esperando a otro líder de riesgo".
4. [x] Approve: "approving activates v2 and keeps it selected" asserts v2 "Activa", v1 "Retirada", all steps done and the title still on v2. It then taps "Reglas" and asserts the NIGHT_TRANSFER `RuleRow` on `/rules` shows "Activa" and not "Pendiente".
5. [x] Return to draft: "returning to draft asks for a reason" covers the dialog, "Devolver" disabled when empty and with only spaces, and the result with "Falta evidencia". "cancelling the dialog leaves v2 pending" covers "Cancelar".
6. [x] Four eyes: "the creator cannot approve and sees who can" (Laura sees no buttons and the box shows Valentina Ríos) and "another risk lead can approve" (Diego).
7. [x] Backtest gate: "ATO_PASSWORD_RESET needs a backtest before submitting" and "FAR_FROM_HOME can be submitted right away", the second including the banner "1 día en shadow: 1.102 coincidencias, 14 decisiones cambiarían."
8. [x] New version: "creating a new version selects it" asserts v3 "Borrador" and the title "SCORE_BLOCK · v3".
9. [x] Read-only user: "a read-only user has no lifecycle actions" checks all four rules as Camilo: none of the seven actions, while the back button and version rows remain.
10. [x] Selection: "selecting an old version hides the new version button".
11. [x] Without data: "a version without a backtest says so", "a backtest without recall shows a dash" and "a version worse than the active one reads as such".
12. [x] Empty states: "/rules/new is not available yet" and "an unknown rule offers the way back". `test/app/navigation_test.dart` passes and the branch doesn't change it (`git diff --stat origin/develop` on it printed nothing).
13. [x] Page isolation: `grep -rln "AppScope\|AppStore" lib/screens/` lists only `*_screen.dart` files, including after the merge. "reports approve, reject and version selection" pumps the page through `harness` with no `AppScope` and asserts `onApprove`, `onReject('Falta evidencia')` and `onSelectVersion(1)`.
14. [x] Seed: `test/data/mock_seed_test.dart` expects 0.742 and 0.773 and passes.
15. [x] Formatter: `lib/data/format.dart` holds `formatConditionValue`, and `test/widgets/condition_row_test.dart` passes and the branch doesn't change it. The grep for `_displayValue` in `lib/widgets/condition_row.dart` matched nothing in round 1, and round 2 didn't touch that file.

## Validation
- Round 2, `bash factory/checks.sh` from the worktree on the merged code: passed (exit 0). That covers `flutter pub get`; `dart format --output=none --set-exit-if-changed lib test` (125 files, 0 changed); `flutter analyze` (no issues); `flutter test` (390 passed); `flutter build web --release`.
- The checks ran on the same code that was committed; nothing changed afterwards.
- PR #51 was checked before pushing: it was open and not merged. The pushed head is `cee1ad2`, and GitHub reports it as mergeable.
- CI on `cee1ad2` hadn't been looked at when this was written.
- Layout check (round 1 only): a throwaway golden test rendered the NIGHT_TRANSFER page and the dialog with the Inter font at 1440 wide, and I read both images. It wasn't repeated for the new timeline text, which is longer and may wrap to two lines. The test isn't committed. The golden test environment draws icons as placeholder squares, so icons weren't checked visually.
- The app wasn't walked through in a browser: per `AGENTS.md`, a person does that with `flutter run -d chrome`.

## Log
### Round 1
Built the spec from scratch: the host screen, the page and dialog, the formatter move, the seed fix and the tests. Opened draft PR #51. The rules list (#21, PR #47) wasn't merged, so criterion 4 used the store assertion the spec allows.

### Round 2
Addressed `feedback-1.md`:

1. **Contract differences:** no change, as asked. The recall tile, the "últimos 30 días" heading and `monedasegura-infra` stay as they were.
2. **Approver:** Valentina Ríos stays. Changed the timeline text to "Esperando a otra persona con permiso para aprobar" and updated its test.
3. **Criterion 7:** no change, accepted as tested on ATO_PASSWORD_RESET.
4. **Criterion 4:** merged `origin/develop` (no conflicts). The test now asserts the `/rules` list, and the out-of-date comment and the PR body's "Still to do" are gone.

Also changed in the PR body:
- Added the approver and contract decisions under "Worth a human look".
- Unticked the contract checklist item, because the recall tile and the heading do differ from `decision-api.yaml`. The note beside it explains why, so a reviewer doesn't read this as an oversight.

PR #51 was already out of draft when this round started. This round didn't change that.
