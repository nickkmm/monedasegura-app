ESCALATE

## Summary
- The pure Dart data layer for issue #11 is built: enums, models, labels, formatters, `MockSeed` and tests. Gate and both reviews pass, and I re-ran `flutter test test/data` at `fa5d30a`: 105 tests pass.
- Recommendation is don't merge yet, because the project rules require a person's check: the change adds the permission map and differs from `model.md` and `decision-api.yaml`.
- Merging as it stands sets up a known failure: `NIGHT_TRANSFER` v2 reads `hace 3 d`, but open issues #16 and #21 require `hoy · Laura Méndez`.
- Case `#09F35B` has a REVIEW verdict that no rule produces, which breaks `model.md` §5. Intake asked for a person to confirm it, and nobody has yet.

## Why
All 16 spec criteria and the issue's criteria are met, and the code matches the issue's values where I checked it. The checks still require a human: the change touches permissions, it differs from the contract and the data model, and it rests on two spec assumptions marked as product decisions. The code review's Note says those two decisions are still open, and the one-line `AGENTS.md` change is outside the intake's Scope, so the approval conditions don't all hold either.

## Acceptance criteria
1. Formatters: met. `format_test.dart` passes, and I read `format.dart` against the issue's examples.
2. Formatter edges: met. Covered by `format_test.dart`. `formatPercent` takes a ratio, as intake ruled, so the issue's `0.0296` example gives `2,96 %`.
3. RBAC: met. Spot-checked: `rolePermissions` in `enums.dart` matches `model.md` §4 role by role, and the tests pass.
4. User: met. I read `app_user.dart`, which has no password field; `initials` and `can` are tested.
5. Enums: met. The 15 enums and `ConditionOp` match `decision-api.yaml`, and the round-trip and unknown-code tests pass.
6. Model getters: met. Covered by the `models_test.dart` "model getters" group, which passes.
7. Feature catalog: met. Spot-checked: the 19 names, order and types match `features.md`, followed by `score`.
8. Labels: met. Spot-checked: I read the strings in `labels.dart` against the issue, and `labels_test.dart` passes.
9. Seed cases: met. Spot-checked: the case rows in `mock_seed.dart` match the issue's tables, and the tests pass.
10. Seed personal data: met. Documents are masked and customer values are within the issue's ranges.
11. Seed verdicts: met as the spec words it, with `#09F35B` exempted by name. See item 2 below.
12. Seed rules: met. Rule rows, conditions and backtest counts match the issue, except the `NIGHT_TRANSFER` v2 age in item 1 below.
13. Seed models and metrics: met. Spot-checked: the `hourly` values, verdict totals and `featureImportance` sum against the issue.
14. No future times: met. The `time` tests pass, and `lib/data` has no `DateTime.now` or `Random`.
15. Pure Dart: met. My grep found no Flutter imports in `lib/data`, and `pubspec.yaml`, `pubspec.lock` and `analysis_options.yaml` are unchanged.
16. Docs: met. The `AGENTS.md` bullet is there, but see item 5 below.

## For the human
Recommendation: don't merge yet

The code does what the spec asks. These checks and decisions need a person first, and the first two change what later issues build on.

1. **`NIGHT_TRANSFER` v2 age: decide which side changes.** The seed has `createdAt` 3 d ago, which gives the `22 oct` that #22 expects. #16 (criterion 2) and #21 expect `hoy · Laura Méndez` from the same field, so they will fail against this seed. Either update #16 and #21 to `hace 3 d · Laura Méndez`, or have `RuleRow` show another date such as `submittedAt`. Also, the shadow start (5 d ago) comes before the version's creation, which the `model.md` §6 lifecycle doesn't allow. Intake kept it as written.
2. **Case `#09F35B`: accept the exception or change the row.** It is degraded with a null score at 2.180.000, and no active rule matches, so `model.md` §5 gives APPROVE, not REVIEW. `AGENTS.md` says the documents win, so either change the row so a rule matches, or explicitly accept it as a demo-only exception.
3. **Permissions: confirm the local derivation is fine for the prototype.** The map matches `model.md` §4. However, `AppUser.permissions` is computed on the client from roles, while `AGENTS.md` and the API's `User` schema have the permissions come from `POST /auth/login` / `GET /me`. The issue asks for this design. It should be replaced when the app connects to the real API.
4. **Contract and data model differences: accept them for the prototype, or change the docs first.** The new fields are commented as prototype-only, but the differences marked (no comment) below are not flagged in the code:
   - `RuleVersion.conditions` is a list, where the API has `condition: {all: [...]}` (no comment).
   - `DashboardMetrics` has flat `latencyP50/95/99`, where the API nests `latencyMs`, and it omits the required `activeModel` (no comment).
   - `CaseView` omits the required `recentTransactions` and `recentSessionEvents` (no comment), and adds `device` and `FraudCase.decisionId`.
   - `Rule.createdAt` isn't in the API schemas.
   - `#B204E7` has four rule hits, where `model.md` §2 and §5 store one per evaluated rule, so `SCORE_BLOCK` and `NIGHT_TRANSFER` are missing. The issue asks for exactly these four.
5. **`AGENTS.md` bullet: keep it or move it.** It is outside the intake's Scope, which lists only the issue's build; spec requirement 5 added it. It also sits inside the `factory:start` block, marked as managed by `monedasegura-infra` `factory/bin/install`, "edit it there". A reinstall could overwrite it. I couldn't find that script in the local `monedasegura-infra`, so I haven't confirmed this.

For later, not blocking this PR: `MockSeed.demoPassword` is a plaintext constant that will ship in the web bundle once #12 uses it. Remove it when sign-in moves to the real API, as the security review notes.

Files to look at:
- `lib/data/mock/mock_seed.dart`: the `NIGHT_TRANSFER` v2 version, and the `#09F35B` and `#B204E7` case rows
- `lib/data/models/enums.dart`: `rolePermissions`
- `lib/data/models/app_user.dart`: `permissions`
- `lib/data/models/rule.dart`, `lib/data/models/dashboard_metrics.dart`, `lib/data/models/fraud_case.dart`: the contract differences
- `AGENTS.md`: the "Data layer" bullet
- `test/data/mock_seed_test.dart`: the `hace 3 d` expectation and the `#09F35B` exemption
