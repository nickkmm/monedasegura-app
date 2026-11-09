DECISION: ACCEPT
RISK: medium
SURFACES: security
RESCOPED: yes

## Summary
- Accepted: the rule lifecycle, rule evaluation and simulator operations on the in-memory `AppStore`, with the tests in the issue.
- Dependency #12 is merged, so `AppStore`, `DomainError` and the seed this builds on are on `develop`.
- I checked all nine acceptance criteria by hand against the seed and the permission table; they are consistent.
- One small rescope: `deleteDraft` also refuses a draft that came back from approval, because that draft has already run in shadow and the issue limits deleting to never-evaluated drafts.
- No contract change is needed because this PR calls no API, but two behaviours are prototype-only, and they are listed below so you can overrule them.

## Scope
Build what the issue specifies, on `develop`'s `AppStore`:

- **Rules**: the lists and lookups, `createRule`, `createVersion`, `updateDraft`, `deleteDraft`, `startShadow`, `runBacktest`, `submitForApproval`, `approve`, `reject`, `canApprove`, `approversFor`, `scoreThresholds` and condition validation, with the formulas and limits in the issue.
- **Evaluation**: `evaluate`, with verdict and shadow counters as in `model.md` §5.
- **Simulator**: `nextRunNumber`, `startRun`, `createOriginationCustomer`, `simulateOne`, the four profiles, and `SimulationEvent`.
- **Tests**: `test/data/app_store_rules_test.dart` covers the nine criteria with the fixed clock. The existing tests keep passing.

**The rescope.** `deleteDraft` throws `conflict` for any version that isn't DRAFT, and also for a DRAFT with a `rejectionReason`. Rejecting is the only way back to DRAFT after shadow, so that field identifies these drafts. They can still be edited and resubmitted. Without this, deleting one would leave decisions pointing at a version that no longer exists, which the issue's own note rules out.

Where the issue leaves a detail open, the spec should use these readings:

- **Order of checks**: permission, then unknown id (`not_found`, as in the existing store), then state, then input. So a taken `code` gives `conflict` before any other input is checked. In `approve`, the check that the approver isn't the creator comes after the state check.
- **Failures and notifications**: a failed operation changes nothing and does not notify. A successful one notifies once.
- **`evaluate`**: it has no permission check or notification of its own. `simulateOne` guards it and notifies once.
- **`verdictChanges`**: it counts a matched SHADOW version whose action is more severe than the verdict from the ACTIVE versions alone.
- **New versions**: they go at the front of `versions`, which is newest first, and are numbered from the highest existing version. `createdBy` is the current user. Backtest, shadow stats and `hits7d` are not copied.
- **Condition values**: `in` takes a `List<String>` and `=`/`!=` on a string take a `String`, as the API says ("an array for `in`").
- **Simulator ids**: they come from a running counter, not from the seeded `Random`. Re-running a run number gives the same verdicts but must still create new records with unique ids.
- **Features with no default in `features.md`**: `amount` comes from the transaction, `hour_of_day` and `is_night` from `occurredAt` unless the profile sets them, and `account_age_days` from the customer unless the profile sets it. `is_new_device` defaults to `true`, so CARD_FRAUD events get `true`.
- **Device**: each simulated transaction gets a new `Device`, because a transaction and a case both need one.
- **Dashboard**: the "current hour's bucket" is `hourly[now.hour]`. `metrics.openCases` stays as it is, as in #12.
- **`createOriginationCustomer`**: N is the current run count, which is the number the last `startRun` returned. The document is that number padded to four digits, for example `****0018`.

**Prototype-only behaviours, built as the issue says:**

- **Submitting without shadow traffic**: `submitForApproval` only needs `shadowStats != null`, so a version with 0 evaluated events can be submitted, and criterion 5 relies on this. `model.md` §6 asks for real shadow hits, so the decision-service stays stricter.
- **`deleteDraft`**: it has no endpoint in `decision-api.yaml`. It is the delete action `docs/deliveries/flutter-prototype.md` asks the plan to choose, and it should carry the usual "Prototype-only" comment.

Left out, as the issue says: widgets and screens, user administration, activating a CANDIDATE model, re-evaluating degraded decisions, and persistence. The on-screen text and theme conventions in the issue mostly don't apply, because this adds no UI. The exceptions are the seeded-style strings such as `Cliente nuevo N.` and `Bogotá`.

## Why
This is the planned follow-up to #12: `lib/data/app_store.dart` has no rule state yet, and its `addCaseRecord` and `updateMetrics` helpers were left for this task. The seed in `lib/data/mock/mock_seed.dart` has the 8 rules, version numbers, creators and run count of 17 that the criteria expect, and the endpoints, code pattern and limits match `decision-api.yaml`. I rated it medium because it is shared code that every rule and simulator screen will rely on, and it enforces permissions and two-step approval. It isn't high because all of it is simulated, in memory, and can be verified with unit tests. It is large for one PR, but it stays within the store and one new model, and the simulator depends directly on the rule evaluation, so I kept it together.
