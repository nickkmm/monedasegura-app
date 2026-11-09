DECISION: ACCEPT
RISK: low
SURFACES: ui, security
RESCOPED: no

## Summary
- Accepted as written: the "Reglas" screen is on the MVP screen list and fits in one pull request.
- The seed data in the local checkout matches the eight rows and the tab counts this issue expects.
- No contract, data model or feature catalog change is needed, because the screen runs on mock data.
- One thing to confirm at build start: I could not check from intake that #16 is merged, and this screen needs its shared widgets.

## Scope
Build the "Reglas" screen as the issue specifies, replacing the `RulesScreen` stub and keeping `RulesScreen()` as its constructor.

- **Host and page:** `RulesScreen` owns the selected tab and is the only part that reads the store or navigates. `RulesPage` receives plain data and callbacks through the constructor given in the issue.
- **Top bar:** title "Reglas" and the subtitle from the issue.
- **Tabs:** "Todas", "Activas", "En shadow", "Pendientes" and "Borradores", each with a live count based on the status of the rule's **latest** version. "Todas" includes retired rules. A rule like NIGHT_TRANSFER, whose latest version is pending while v1 is still active, counts only under "Pendientes".
- **"Nueva regla":** shown only with `RULE_WRITE`, and opens `/rules/new`.
- **Table:** the columns and widths from the issue, with one row per rule of the selected tab, in store order. Tapping a row opens `/rules/<id>`. An empty tab shows the issue's empty state.
- **Row values:** the eight rows must match the issue's expected values, including "hoy · Laura Méndez" for NIGHT_TRANSFER, which comes from `submittedAt` rather than `createdAt` (see #33).
- **Lifecycle legend:** "Ciclo de vida:" and the five status badges, separated by "→".
- **Updates:** a rule created through the store appears in the list and the counts without a restart.
- **Tests:** `test/screens/rules_test.dart` covers all eight acceptance criteria, including pumping the page alone with fake data and callbacks.

Left out, as the issue says: the editor itself, sorting or searching rules, and bulk actions.

## Why
`docs/MVP_PLAN.md` §6 lists the rule list, and the seed in `lib/data/mock/mock_seed.dart` already holds the expected rules, versions, 7-day matches and precision values (for example, SCORE_REVIEW has 2.410 matches and 41 of 100 true positives). The permissions also fit: Valentina (ADMIN) has `RULE_WRITE` and Camilo Torres (ANALYST) has only `RULE_READ` (`docs/model.md` §4), and #17 specifies the guarded routes this screen links to.

My local checkout is behind `origin/develop`, so I took `store.rules`, `createRule` and the routes from the #15 and #17 job records, which show both merged, rather than from the code. I found no record of #16 in this checkout, so the build must confirm that `RuleRow`, `RuleStatusBadge`, `TableHeaderRow`, `AppTabBar` and `EmptyState` are on `origin/develop`, and stop if they are not rather than re-create them here.

I rated risk low because this is one screen on in-memory data. The security surface applies only because the screen hides an action by permission; the route guard already exists.
