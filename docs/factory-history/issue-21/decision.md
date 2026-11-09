ESCALATE

## Summary
- The "Reglas" screen is built: lifecycle tabs with live counts, the rules table, the legend and "Nueva regla" for users with `RULE_WRITE`.
- All 13 spec criteria are met; the gate passed, all four reviews passed and GitHub CI is green on `9a530d3`.
- Recommendation is don't merge yet: at the 1280 minimum width the "Actualizada" column has about 42 px, so its header and values are cut to a few characters.
- A person needs to accept or fix that column and do the browser walkthrough, which nobody has done yet.
- Two smaller flags: one test file is outside intake's Scope, and the screen adds a new permission check, with permissions and guards unchanged.

## Why
The code matches the spec and I found no functional defect, but the UI review's Note about the truncated column describes a real problem, so the check that no Note does fails. The spec lists it as an accepted Assumption, which makes it known but doesn't make the column readable on common laptop widths. The change also adds a test file outside intake's Scope and a new permission check, so a person should look at those too.

## Acceptance criteria
1. Top bar, tabs, seven headers, eight rows in order: met. `test/screens/rules_test.dart` asserts it; I re-ran this file and `test/app/navigation_test.dart`, and all 29 tests passed.
2. Values of all eight rows: met. A table-driven test covers each row, including the two "—".
3. Tabs filter by the latest version's status: met. The test passes, and `_withStatus` in `rules_screen.dart` reads `latest.status`, so NIGHT_TRANSFER is only under "Pendientes".
4. Lifecycle legend in order, with four "→": met. The test checks labels and left-to-right order, and the order matches `model.md` §6.
5. "Nueva regla" and row tap open the right routes: met. The tests assert the route name and `ruleId`.
6. Camilo Torres sees no "Nueva regla", and rows still open: met. The test passes, and `model.md` §4 gives `ANALYST` `RULE_READ` without `RULE_WRITE`.
7. A rule created in the store appears without a re-pump: met. The test shows 9 rows, "Todas · 9" and "Borradores · 2".
8. Page alone reports actions through callbacks: met. It is pumped with no `AppScope`, using fake rows.
9. Page alone with no rows shows the headers and the empty state: met. The test asserts the exact copy.
10. `grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart`: met. I ran it and it matched `login_screen.dart` and `rules_screen.dart`.
11. No `AppShell` or `Navigator` in `rules_page.dart`: met. I ran the grep and it matched nothing.
12. No hex colors or font sizes in the two screen files: met. I ran the grep and it matched nothing.
13. No changes in `lib/widgets`, `lib/data` or `lib/app`: met. I ran the diff and it was empty, and `pubspec.yaml`, `pubspec.lock`, `docker-compose.yml`, `Dockerfile` and `.github` are also unchanged.

## For the human
Recommendation: don't merge yet

The code is ready apart from these checks. Once they are done, nothing else I found blocks a merge.

**1. Decide on the "Actualizada" column at narrow widths (the blocker).**
- At the 1280 minimum, the fixed columns leave about 42 px: 1280 minus the 240 sidebar, 64 content padding, 2 border, 48 row padding, 112 gaps and 772 fixed cells.
- "Actualizada" and values such as "hace 2 meses · Laura Méndez" truncate with an ellipsis, so the date and author can't be read in that window.
- At 1440 the column has about 200 px, which the spec says fits. At 1366 it has about 128 px, and I estimate that still truncates, though I didn't measure it.
- The issue fixes the other column widths, so the choice is yours: accept this for now, or ask for a follow-up. The UI review suggests dropping the author from the cell or giving the column priority at narrow widths.
- Files: `lib/screens/rules/rules_page.dart` (header widths), `lib/widgets/rule_row.dart` (row cells, shared and unchanged here).

**2. Walk through the screen with `flutter run -d chrome`.**
- No browser run has happened; agents can only use widget tests here.
- Check it at 1440 and 1280. Also check that the "Nueva regla" button lines up with the tab bar's bottom border, because the UI review could not measure that.

**3. Confirm you're fine with the test file outside intake's Scope.**
- `test/app/navigation_test.dart` gained Inter font setup. Its sidebar test now opens the real rules screen, where the default test font makes the "Pendiente" badge overflow.
- This is test setup only and no assertion changed, so I see no harm in it.

**4. Check the new permission check.**
- `store.can(PermissionCode.RULE_WRITE)` in `lib/screens/rules/rules_screen.dart` decides whether "Nueva regla" shows.
- It uses a permission rather than a role, as `AGENTS.md` requires. `lib/app/routes.dart` is unchanged and still guards `/rules/new` with `RULE_WRITE`. No permission, role or guard changed.
- It matches `model.md` §4, so a quick read should be enough.

**Not blocking: contrast of the grey text token.** `AppColors.textTertiary` measures about 3.2:1 on white and 2.7:1 on the table header band, per the UI review. That is below 4.5:1, but the issue sets these colors and shared `TableHeaderRow` uses the token, so it isn't for this PR to fix. It is worth raising with the design owner before more screens reuse it.

No contract, data model or feature catalog difference, migration, environment variable, `docker-compose.yml` change or new dependency is involved. The screen runs on mock data only.
