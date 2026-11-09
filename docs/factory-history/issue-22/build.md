STATUS: READY

# Build: Rule editor: view a version and move it through its lifecycle

## Summary
- `/rules/<id>` now shows the stepper, condition, backtest, two-step approval and versions for the selected version.
- The screen performs every lifecycle action (shadow, backtest, submit, approve, return to draft, new version); the page only shows data and reports callbacks.
- `/rules/new` and an unknown rule show empty states and keep the `Regla` title.
- The NIGHT_TRANSFER v2 seed recall changed to 0.742 and 0.773, and the condition value formatter moved to `lib/data/format.dart`.
- The `/rules` list check in criterion 4 is still to do: #21 is not on the base, so the test asserts the store instead, and the PR body says so.

## Changes
- `lib/screens/rules/rule_editor_screen.dart`: now a stateful host. It owns the selected version, derives `canWrite`, `canApprove`, `approver` and `creator`, performs the store calls and navigation, and turns a `DomainError` into a `SnackBar`.
- `lib/screens/rules/rule_editor_page.dart` (new): `RuleEditorPage` with the actions row and the condition, backtest, approval and versions cards, plus the private return-to-draft dialog. It takes constructor data and callbacks only.
- `lib/data/format.dart`: new public `formatConditionValue(feature, value)` holding the COP feature set.
- `lib/widgets/condition_row.dart`: calls the helper instead of its private `_displayValue`. Behaviour is unchanged.
- `lib/data/mock/mock_seed.dart`, `test/data/mock_seed_test.dart`: NIGHT_TRANSFER v2 recall is 0.742 and 0.773.
- `test/screens/rule_editor_test.dart` (new): 26 widget tests for the criteria below.
- `test/data/format_test.dart`: cases for the moved helper.

Choices the spec leaves open:
- Version rows have 8 px of horizontal padding, so the selected background doesn't touch the text.
- The four metric tiles share one height (`IntrinsicHeight`), because the notes wrap to different line counts.
- The dialog is 420 wide.

## Acceptance criteria
Unless noted, the evidence is a passing widget test in `test/screens/rule_editor_test.dart` (`flutter test`: 26 of 26 in that file). The test names are quoted.

1. [x] Header and condition: "shows the header, stepper and condition" asserts the title, subtitle, back button, stepper labels and states (done, done, current, pending), condition rows and read-only action control.
2. [x] Backtest: "shows the backtest and the shadow banner" asserts every listed value, including "+3,1 pp", "0,74 → 0,77" and the banner, and that "Volver a correr" has a null `onPressed`.
3. [x] Approval and versions: "shows the approval timeline and the versions" asserts the timeline, the approver box, both buttons, and v2 above v1 with their summaries and badges.
4. [x] Approve: "approving activates v2 and keeps it selected" asserts v2 "Activa", v1 "Retirada", all steps done and the title still on v2. `RulesScreen` is still the stub on this base (PR #47 is open), so the test asserts the store has v2 ACTIVE and v1 RETIRED, and the PR body says the list check is still to do.
5. [x] Return to draft: "returning to draft asks for a reason" covers the dialog, "Devolver" disabled when empty and with only spaces, and the result with "Falta evidencia". "cancelling the dialog leaves v2 pending" covers "Cancelar".
6. [x] Four eyes: "the creator cannot approve and sees who can" (Laura sees no buttons and the box shows Valentina Ríos) and "another risk lead can approve" (Diego).
7. [x] Backtest gate: "ATO_PASSWORD_RESET needs a backtest before submitting" and "FAR_FROM_HOME can be submitted right away", the second including the banner "1 día en shadow: 1.102 coincidencias, 14 decisiones cambiarían."
8. [x] New version: "creating a new version selects it" asserts v3 "Borrador" and the title "SCORE_BLOCK · v3".
9. [x] Read-only user: "a read-only user has no lifecycle actions" checks all four rules as Camilo: none of the seven actions, while the back button and version rows remain.
10. [x] Selection: "selecting an old version hides the new version button".
11. [x] Without data: "a version without a backtest says so", "a backtest without recall shows a dash" and "a version worse than the active one reads as such".
12. [x] Empty states: "/rules/new is not available yet" and "an unknown rule offers the way back". `test/app/navigation_test.dart` passes unchanged (`git diff --stat HEAD` on it printed nothing).
13. [x] Page isolation: `grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files. "reports approve, reject and version selection" pumps the page through `harness` with no `AppScope` and asserts `onApprove`, `onReject('Falta evidencia')` and `onSelectVersion(1)`.
14. [x] Seed: `test/data/mock_seed_test.dart` expects 0.742 and 0.773 and passes.
15. [x] Formatter: `grep -n "_displayValue" lib/widgets/condition_row.dart` matches nothing, `lib/data/format.dart` holds `formatConditionValue`, and `test/widgets/condition_row_test.dart` passes unchanged.

## Validation
- `bash factory/checks.sh` from the worktree: passed (exit 0). That covers `flutter pub get`; `dart format --output=none --set-exit-if-changed lib test` (123 files, 0 changed); `flutter analyze` (no issues); `flutter test` (377 passed); `flutter build web --release`.
- The checks ran on the same code that was committed; nothing changed afterwards.
- Layout check: a throwaway golden test rendered the NIGHT_TRANSFER page and the dialog with the Inter font at 1440 wide, and I read both images. There was no overflow, and the columns and cards matched the spec. The test isn't committed. The golden test environment draws icons as placeholder squares, so icons weren't checked visually.
- The app wasn't walked through in a browser: per `AGENTS.md`, a person does that with `flutter run -d chrome`.

## Log
### Round 1
Built the spec from scratch: the host screen, the page and dialog, the formatter move, the seed fix and the tests. Opened draft PR #51. The rules list (#21, PR #47) isn't merged, so criterion 4 uses the store assertion the spec allows.
