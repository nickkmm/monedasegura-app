STATUS: READY

# Build: Rules list screen

## Summary
- "Reglas" now shows lifecycle tabs with live counts, the rules table, the lifecycle legend and "Nueva regla" for users with `RULE_WRITE`.
- `RulesScreen` owns the tab, reads the store and navigates; `RulesPage` only takes constructor data and callbacks.
- No shared widget, data layer or route changed.
- One file beyond the spec's three: `test/app/navigation_test.dart` now loads Inter, because its sidebar test would otherwise fail on the real screen.
- Draft PR: https://github.com/nickkmm/monedasegura-app/pull/47

## Changes
- `lib/screens/rules/rules_screen.dart`: replaces the stub with a `StatefulWidget` that computes the tab labels and the rows of the selected tab from `store.rules`, passes `now` and `canCreate`, and handles the navigation callbacks with `pushNamed`.
- `lib/screens/rules/rules_page.dart`: new `RulesPage` with three private sections: the toolbar, the table card (header, rows or empty state) and the lifecycle legend.
- `test/screens/rules_test.dart`: new widget tests for criteria 1 to 9, plus checks of the 16 px toolbar gap, the omitted gap without the button, the card tokens and the selected tab surviving a return from the editor.
- `test/app/navigation_test.dart`: loads Inter in `setUpAll`. The test "tapping each sidebar item opens its screen and marks it" now opens the real rules screen, and the default test font makes the "Pendiente" badge overflow its 130 px cell. The spec did not list this file; the change is test-only and the same setup as `rule_row_test.dart`.

## Acceptance criteria
Criteria 1 to 9 are checked by `flutter test test/screens/rules_test.dart`: 13 tests, all passed. UI was checked with widget tests and by reading the code against the issue, as `AGENTS.md` prescribes; nobody has walked through the screen in a browser.

1. [x] Top bar, tabs, seven headers and eight rows in order: test "shows the frame, the tabs, the headers and the rows in order" passed. It checks tree order and top-to-bottom position.
2. [x] Row values: table-driven test "each row shows the values of its latest version" passed for all eight rows, including the two "—" in ATO_PASSWORD_RESET and VELOCITY_5M.
3. [x] Tab filtering: test "the tabs filter by the status of the latest version" passed. "Activas · 4" leaves 4 rows without NIGHT_TRANSFER; "Borradores · 1" leaves only ATO_PASSWORD_RESET.
4. [x] Legend: test "the legend shows the lifecycle in order" passed. It finds "Ciclo de vida:", five badges in the order Borrador, Shadow, Pendiente, Activa, Retirada, and four "→".
5. [x] Navigation: tests "'Nueva regla' opens the new rule route" and "tapping a row opens its editor and back keeps the tab" passed. They assert `/rules/new` with a null `ruleId`, and `/rules/<id>` with the id from `store.ruleByCode('NIGHT_TRANSFER')`.
6. [x] Camilo: test "without RULE_WRITE there is no button, rows still open" passed.
7. [x] Live update: test "a rule created in the store shows up without a re-pump" passed as Laura Méndez, with 9 rows, "Todas · 9" and "Borradores · 2" after `tester.pump()`.
8. [x] Page alone: tests "reports the user actions through its callbacks" and "canCreate false hides the button and its gap" passed with fake rows and no `AppScope`.
9. [x] Empty page: test "no rows shows the headers and the empty state" passed.
10. [x] `grep -rn "AppScope\|AppStore" lib/screens/` matches only `login_screen.dart` and `rules_screen.dart`.
11. [x] `grep -n "AppShell\|Navigator" lib/screens/rules/rules_page.dart` matches nothing.
12. [x] `grep -nE "Color\(0x|fontSize" lib/screens/rules/rules_page.dart lib/screens/rules/rules_screen.dart` matches nothing.
13. [x] `git diff --stat origin/develop -- lib/widgets lib/data lib/app` prints nothing.

## Validation
- `bash <main checkout>/factory/checks.sh` from the worktree: passed (exit 0). `dart format` changed nothing, `flutter analyze` found no issues, `flutter test` passed all 311 tests and `flutter build web --release` built.
- `flutter test test/screens/rules_test.dart`: passed, 13 tests.
- The four grep and diff commands in criteria 10 to 13: results as listed above.
- `git status --porcelain` in the worktree: prints nothing.
- GitHub CI on the PR: not checked; the PR checklist leaves "CI passes" unticked.

## Log
### Round 1
Implemented the spec from scratch. Running the suite after replacing the stub showed that `navigation_test.dart` failed on the badge overflow described above, so I added the Inter setup to that test rather than change `RuleRow`, which is out of scope. Opened draft PR #47.
