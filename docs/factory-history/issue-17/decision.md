ESCALATE

## Summary
- PR #42 is already merged: @Jujoroco06 merged it at 07:31 UTC, before this gate finished, and issue #17 is closed. This decision can no longer hold it back.
- The build meets all 19 acceptance criteria, the final gate passed and all four reviews passed.
- It adds the permission guards and the simulator's access rule, and this project's rules require a person to check those.
- Nobody has recorded a browser walkthrough. Widget tests don't cover the URL bar or the browser's back button.
- Follow-ups: a post-merge check, the missing job record for #17, and keyboard access to the sidebar.

## Why
The code is sound on everything I could verify: the guards use `AppUser.can` only, and the permissions match `model.md` §4. I still recommend against merging until a person has checked it, because the change touches permissions and the simulator's access rule. The merge has already happened and its approvals have empty bodies, so I can't tell whether that check was done.

## Acceptance criteria
Criteria 1 to 14 are backed by the four named test files. I ran them on commit 2e95e37 and all 31 tests passed. The full suite (284 tests), `flutter analyze` and the web build passed in `round-1/checks.md`.

1. Start screen: met. `test/widget_test.dart` passes.
2. Login errors: met. `test/screens/login_test.dart` passes.
3. Login success, by button and by Enter: met. `test/screens/login_test.dart` passes.
4. Login layout: met. `test/screens/login_test.dart` passes, and I read `guilloche_painter.dart` against the issue's values.
5. Sidebar by permission: met. `test/app/navigation_test.dart` passes, and I read this test: Camilo gets four items and no "Simulador".
6. Guards: met. `test/app/navigation_test.dart` passes. I read the `/simulator` and `/rules/new` cases and `lib/app/routes.dart`.
7. Start route: met. `test/app/navigation_test.dart` passes.
8. Navigating: met. `test/app/navigation_test.dart` passes.
9. Logout: met. `test/app/navigation_test.dart` passes.
10. `firstAllowedRoute`: met. `test/app/navigation_test.dart` passes.
11. Shell width: met. `test/app/navigation_test.dart` passes.
12. `NavItem`: met. `test/widgets/shell_widgets_test.dart` passes.
13. `TopBar`: met. `test/widgets/shell_widgets_test.dart` passes.
14. `AppSidebar` alone: met. `test/widgets/shell_widgets_test.dart` passes.
15. Old file gone: met. I ran `test ! -e lib/login_screen.dart`, and `lib/main.dart` has no widget class.
16. Store isolation: met. I ran the grep and it prints only `lib/widgets/app_shell.dart`.
17. Tokens only: met. I ran the grep and it prints nothing.
18. Barrel: met. I checked the four exports in `lib/widgets/widgets.dart`.
19. Docs: met. I read the `README.md` and `AGENTS.md` diffs.

## For the human
Recommendation: don't merge yet

PR #42 is already merged (84ee98f on `develop`), so treat this as a post-merge check. If a check fails, fix it with a new PR against `develop` or revert. Please reply on the PR if you already did the walkthrough.

**Why a person must check it**
- It touches permissions and the simulator's access rule: `lib/app/routes.dart` and `lib/app/nav_destination.dart` (`/simulator` needs `SIMULATOR_RUN`), and `lib/widgets/app_shell.dart` (which destinations the sidebar shows).
- The sign-in is simulated and client-side, so these guards only control what the app displays. The security review notes that the real access check belongs to the decision-service once the API is connected.

**Checks I need from you**, with `flutter run -d chrome` and the accounts in `README.md`:
1. Sign in as Valentina Ríos: "Simulador" shows and opens.
2. Sign in as Camilo Torres: "Simulador" is hidden, and typing `/simulator` in the URL lands on the Dashboard.
3. Sign in as Laura Cárdenas: typing `/rules/new` in the URL lands on the Dashboard.
4. Log out, then press the browser's back button: the console must not come back.
5. Confirm a reload signing the user out is acceptable. It is a spec assumption, because the issue rules out storing a token.

The tests push routes in-process, so checks 2 to 4 are not covered in a real browser.

**Decisions and follow-ups**
- **`AGENTS.md`:** this edit is outside intake's Scope; the spec added it. It writes `AppShell` into the project rules as the one exception to "never `AppScope`", which matches the issue, and adds a Routing bullet. The `README.md` status line was added the same way. Please confirm you're happy with both.
- **Rule editor:** `/rules/<id>` needs only `RULE_READ`, as the issue says, so analysts, auditors and data scientists can open the editor route. It is an empty stub today. The rule editor task must make it read-only for them.
- **Sidebar keyboard access:** `lib/widgets/nav_item.dart` uses a `GestureDetector`, so keyboard users can't focus or activate sidebar items. The UI and UX reviews left this as a note. It's a real gap, though not a blocker for a mouse-first prototype, so it deserves a follow-up issue. The UX note says the spec rules this out, but the spec only limits the state the widget keeps.
- **Job record:** `docs/factory-history/issue-17/` is not on `develop`, because the merge came before the record was added. It needs a follow-up like the one #39 did for #15.
- **`develop` CI:** the run for the merge commit was still in progress when I checked. CI on the PR passed, but I didn't run the tests on the merged result, which also includes #41. Please confirm that run goes green.

**Smaller review notes, no action needed now**
- The demo password in `README.md` and `lib/data/mock/mock_seed.dart` only opens synthetic data. Remove it when `POST /auth/login` arrives.
- Route ids reach the screens undecoded and unvalidated, so the screen tasks must treat them as untrusted.
- `/login` stays reachable with an active session, as the spec says. Revisit this with real auth.

No database migration, environment variable, `docker-compose.yml`, CI, dependency or JWT change. I found no difference from `model.md` §4.

**Files to look at:** `lib/app/routes.dart`, `lib/app/nav_destination.dart`, `lib/widgets/app_shell.dart`, `lib/widgets/nav_item.dart`, `test/app/navigation_test.dart`, `AGENTS.md`.
