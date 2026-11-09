VERDICT: PASS

## Summary
- The branch adds the rule lifecycle, rule evaluation and simulator to the in-memory `AppStore`. It adds no UI, HTTP call, dependency or real persistence.
- Every rule and simulator mutation checks its permission first, by permission code and never by role. Tests cover Camilo Torres and signed-out callers on each one.
- The two-step approval check is correct as `model.md` §4 and §6 and the API define it, but the contract only compares the approver with the creator, so an editor can approve their own edit (Notes).
- Simulated customers and counterparties stay masked, and no secrets, logging or new credentials were added.
- No blocking findings. The notes are worth settling before this store is replaced by the real API.

## Findings
None.

## Notes
These come from reading the code; I did not run them as scenarios.

1. **Two-step approval can be sidestepped by editing someone else's draft.** `lib/data/app_store.dart:670` compares the approver only with `createdBy`, and `updateDraft` (`:541`) keeps `createdBy` while replacing the conditions and action.
   - So a RISK_LEAD can rewrite a draft another user created, or one they just rejected, then submit and approve their own content. `canApprove` and `approversFor` have the same gap.
   - This matches `model.md` (`approved_by_id <> created_by_id`), the API text ("the approver must not be the creator") and the issue, so it is not a defect in this branch.
   - The decision-service has the same gap if it implements the contract literally. Consider a PR against `monedasegura-infra` that also records the last editor and excludes them from approving.
2. **`evaluate` is public and unguarded, and it changes state** (`:740`). Any caller, even signed out, can raise a SHADOW version's stats, and listeners aren't notified. The spec asks for this explicitly and only `simulateOne` calls it today, so there is no impact yet. Screens should not call it directly, and it matters more if a stricter shadow requirement is added here.
3. **`submitForApproval` accepts a version with 0 shadow evaluations** (`:651`). `model.md` §6 requires real shadow hits. The code comment and the spec flag this as prototype-only, and the decision-service stays stricter, so the mock shows a weaker guarantee than production has.
4. **Read operations have no permission check.** `rules`, `ruleById`, `ruleByCode` and `approversFor` (`:432`, `:724`) work signed out, though the API requires `RULE_READ` for rule reads. `approversFor` also returns full `AppUser` objects, including emails, while the API restricts `/users` to `USER_ADMIN`. This follows the store's existing unguarded reads such as `users`, `customers` and `openCases`, so screens must gate on permissions and show only what they need.
5. **The `rules` list is unmodifiable, but the data inside it isn't.** `RuleView.versions` is a plain list (`:524`, `:1004`), and the `List<String>` value of an `in` condition is not copied (`:484`, `:544`). Code in the same process could change a version without any permission check or re-validation. Only local callers can do this and there is no server boundary, so it is a hardening item only.
6. **Pre-existing:** `MockSeed.demoPassword` is a hard-coded password that signs in as any seeded user, including ADMIN. It is documented as a prototype value and this branch doesn't change it; the new tests only reference it. It must not ship in a build that holds real data.
