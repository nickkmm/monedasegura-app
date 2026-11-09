VERDICT: PASS

## Summary
- The branch replaces the rules stub with a real list screen backed by the in-memory store, and adds tests.
- "Nueva regla" is gated by the `RULE_WRITE` permission, not by a role name, and the route guards still enforce access.
- There are no network calls, storage, logging, secrets or new dependencies in this change.
- Rule text is drawn with Flutter `Text`, so there is no raw HTML or URL injection path.

## Findings
None.

## Notes
- **Access control.** `canCreate` comes from `store.can(PermissionCode.RULE_WRITE)` (`lib/screens/rules/rules_screen.dart:53`). Hiding the button is backed by the unchanged guards in `lib/app/routes.dart`: `/rules` and `/rules/<id>` need `RULE_READ`, `/rules/new` needs `RULE_WRITE`, and `AppStore.createRule` checks `RULE_WRITE` again.
- **Route ids.** `AppRoutes.ruleEditor(view.rule.id)` puts the id in the path without encoding. The ids are store-generated (`MockSeed.uuid`), not user input, so this is not a problem today. It is worth a second look if ids ever come from elsewhere.
- **Personal data.** The rows show only rule data and the display name of the staff member who last changed the rule. No customer data is involved.
- **Pre-existing, not made worse.** Route guards run when a route is generated, so an open screen is not re-checked by the guard if the session changes. `RulesScreen` does re-read the store on change, so `canCreate` stays current.
- **Backend.** Everything here is client-side mock state. Server-side enforcement of `RULE_READ` and `RULE_WRITE` belongs to the decision-service and is not exercised by this change.
- **Test data.** The tests contain only the seeded demo emails. `pumpApp` uses the demo password from the existing helper, and this branch adds no credentials.
