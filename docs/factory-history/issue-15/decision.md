ESCALATE

## Summary
- `AppStore` now has the rule lifecycle, rule evaluation and the simulator, in memory, with 54 new tests.
- All 18 acceptance criteria are met, `GATE: PASS` on the current commit, and both reviews are `VERDICT: PASS`.
- Recommendation is not to merge yet: the change adds the permission checks and the simulator's access rule, and it differs from `model.md` and `decision-api.yaml`.
- The security review also notes a real gap: a user can get their own rule content approved by themselves by editing someone else's draft.
- None of this is a build defect. A person needs to accept or change these points.

## Why
The code does what the issue and spec ask, and it stays inside intake's Scope. But it enforces `RULE_WRITE`, `RULE_APPROVE` and `SIMULATOR_RUN`, and it differs from the shared docs in several places, so this project's checks require a person to look before merging. One review note also describes a real weakness in two-step approval, which comes from the contract rather than from this branch.

## Acceptance criteria
I ran `flutter test test/data/app_store_rules_test.dart` on commit 3ccab32 and got `+54: All tests passed!`. The gate's full run on the same commit passed with `+236`.

1. `createRule` gives a 9th rule with v1 DRAFT, and refuses bad codes, taken codes and unknown features: met, group `createRule`.
2. Condition validation: met, group `condition validation`.
3. `updateDraft` changes conditions, clears the backtest and refuses ACTIVE: met, group `updateDraft`.
4. `deleteDraft` removes the rule or only the version, and refuses ACTIVE: met, group `deleteDraft`.
5. `createVersion` on SCORE_REVIEW creates v5 DRAFT at the front, and a second call conflicts: met, group `createVersion`.
6. Full lifecycle with two people, v4 RETIRED: met, group `lifecycle`.
7. Backtest numbers: met. I worked them out by hand: `score>=0.6` gives h = 811, so TP 26, FP 45, FN 37, TN 1812, and recall 0.74 + (26 - 41) / 1300 rounds to 0.73. The test asserts the same values.
8. `reject` gives DRAFT with the reason, and limits the reason length: met, group `reject`.
9. A rejected draft can't be deleted but can be edited and resubmitted: met, group `reject`.
10. `forbidden` for Camilo Torres and signed out on every listed operation, `not_found` for an unknown id: met. I read this test and it covers each listed operation with an unknown id.
11. Listener called once on success and never on failure, and a failed `createRule` leaves `rules` unchanged: met, group `notifications`.
12. `approversFor` and `scoreThresholds`: met, group `approvers and thresholds`.
13. `evaluate` verdicts, 6 hits and shadow stats: met. The test expects FAR_FROM_HOME before NIGHT_TRANSFER, the reverse of the criterion's list. It is the same 6 hits, in the list order requirement 14 fixes, and the criterion doesn't state an order.
14. `startRun` and the origination customer: met, group `runs and origination customers`.
15. 20 ATO events open exactly 7 cases, metrics grow, and a re-run gives the same verdicts with new ids: met, group `simulateOne`. The store has no public decision list, so "20 decisions" is tested through the returned events. I read the code and each decision is stored.
16. `forbidden`, `not_found` and `invalid` from `simulateOne`: met, group `simulateOne`.
17. FAR_FROM_HOME v1 `evaluated` grows by 20: met, group `simulateOne`.
18. The four profiles over indices 0..29: met, group `profiles`. The feature defaults in the code match `features.md`.

## For the human
Recommendation: don't merge yet

The code matches the issue and the spec, so this is a review of decisions, not a request for fixes. Merge once you have accepted or changed each point below.

**1. Check the permissions and the simulator's access rule.**
Confirm that `RULE_WRITE`, `RULE_APPROVE` and `SIMULATOR_RUN` guard the right operations, matching `model.md` §4. I found them correct, but this project requires a person's check.
- `lib/data/app_store.dart`: the rule operations from line 497, `approve` at 665, `canApprove` at 716, the simulator at 800-825.
- `test/data/app_store_rules_test.dart`: group `permissions`, line 487.

**2. Decide whether to accept the self-approval gap.**
From the security review, note 1. `approve` compares the approver only with `createdBy`, and `updateDraft` keeps `createdBy` while replacing the conditions and action. So a RISK_LEAD can rewrite a draft that someone else created, or one they just rejected, then submit and approve it. It matches `model.md` (`approved_by_id <> created_by_id`) and the API, so the decision-service would have the same gap if it follows the contract literally.
- Decide: accept it for the prototype, or open a PR against `monedasegura-infra` that also records the last editor and excludes them from approving.
- Look at: `lib/data/app_store.dart:529` and `:665`, and `model.md` §4 and §6.

**3. Accept or reject each difference from the shared docs.**
AGENTS.md says the documents win, and that they change first through a PR against `monedasegura-infra`. The issue asks for items a to d, but no docs PR exists for them. Item e is the spec's own narrowing.

| | Store behaviour | Docs | Where |
|---|---|---|---|
| a | `submitForApproval` accepts a version with 0 shadow evaluations | `model.md` §6 requires `decision_rule_hit` rows with `shadow = true`; the API requires shadow results | `app_store.dart:644` |
| b | `deleteDraft` exists | No delete operation anywhere in `decision-api.yaml`; `model.md` defines no delete. `docs/deliveries/flutter-prototype.md` asks for one chosen delete action, and intake's rescope also refuses rejected drafts | `app_store.dart:553` |
| c | `createVersion` takes no conditions or action, and throws `conflict` if a version is in progress | `POST /rules/{ruleId}/versions` requires a `RuleVersionInput` body and declares no `409`. No review or earlier stage raised this | `app_store.dart:497` |
| d | The simulator works one event at a time. It creates no session events, and the origination customer is a separate call | `POST /simulator/runs` takes `scenario`, `customerId` and `count`, and returns `sessionEvents` and `results` | `app_store.dart:807`, `:825` |
| e | `in` accepts only a `List<String>`, and an empty rejection reason is `invalid` | The `Condition` schema also allows numbers in the `in` array, and `reason` has no minimum length | `app_store.dart:55` and `reject` |

- Decide: accept each as prototype-only, or ask for a change. Items a to c matter most, because the screens will be built on them and they will have to change when the real API arrives.
- Only a and b carry a "Prototype-only" comment in the code. If you accept c, d or e, consider a follow-up to mark them too.

**4. Note for the screens that follow (no action needed on this PR).**
From the security review, notes 2 and 4. `evaluate` is public, has no permission check and changes shadow stats, and read operations such as `rules` and `approversFor` have no permission check. This follows the spec and the store's existing pattern. Screens must not call `evaluate` directly and must gate reads on permissions.
