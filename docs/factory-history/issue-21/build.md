STATUS: BLOCKED

# Build: Rules list screen

## Blocked
**The feedback is done on the branch, but nothing can carry it to `develop`: PR #47 was merged while this round was running.**

- @Jujoroco06 merged PR #47 at 03:24:21 (-05:00), with head `689556c`, their own merge of `develop` into this branch. Merge commit: `f55ff7f`.
- This round's push came 22 seconds later, so `develop` has the rules screen from round 1 but not the narrow-width fix. Issue #21 is closed.
- Commits pushed to the branch no longer reach a PR, because #47 is merged. `gh pr list --head factory/004-build-the-rules-list --state all` shows only #47.
- I did not open a second PR. The job record points at #47, and the build instructions only cover opening a PR when the branch has none, so that decision is yours.

**Decision needed:** should the narrow-width fix go in as a follow-up PR?
- **Recommended: yes.** Without it, the "Actualizada" column on `develop` is still cut to about 42 px at the 1280 minimum, which was the blocker in `decision.md`. The branch is already up to date with `develop` (`f0116e4`, 4 ahead and 0 behind), so this needs only:
  `gh pr create --draft --base develop --head factory/004-build-the-rules-list --title "Show only the date in the rules table at narrow widths" --body-file <file>`
  The job record would also need to point at the new PR, or the job would need re-filing, so the gate and reviews run against it.
- **Otherwise:** close the job and leave the column as merged. Round 2's code then stays only on the branch.

## Summary
- Feedback item 1 is overtaken: the conflict is resolved on the branch, but #47 merged with @Jujoroco06's resolution.
- Feedback item 2 is built and passes all checks, but only on the branch: below a 1418 px window, "Actualizada" shows only the date, in full.
- That fix also needed room, so "Regla" gives up its fixed 300 px below 1418 px, which the issue didn't foresee.
- `develop` has a harmless leftover: `navigation_test.dart` sets up Inter twice. The branch removes the duplicate.
- Nobody has run the screen in a browser yet, including the `decision.md` check of the "Nueva regla" alignment.

## Changes
Compared with `origin/develop` (the code that hasn't reached it):
- `lib/widgets/rule_row.dart`: new `compact` parameter and `RuleRow.compactDateWidth` (84). When compact, the last change shows only the date in that column and the rule column takes the remaining space. The default output is unchanged.
- `lib/screens/rules/rules_page.dart`: `_RulesTable` uses a `LayoutBuilder` and turns compact below a card width of 1114 px (a 1418 px window), so every row and the header switch together.
- `test/screens/rules_test.dart`: six tests of the column at window widths 1000, 1280, 1366, 1417, 1418 and 1440, and it now uses the shared `loadInterFont` helper.
- `test/widgets/rule_row_test.dart`: one test of compact mode.
- `test/app/navigation_test.dart`: the two Inter setups become one `setUpAll(loadInterFont)`, keeping both sides' intent.

Already on `develop` through #47: `lib/screens/rules/rules_screen.dart`, `lib/screens/rules/rules_page.dart`, `test/screens/rules_test.dart` and the Inter setup in `test/app/navigation_test.dart`.

## Acceptance criteria
### Feedback
1. [x] Conflict in `test/app/navigation_test.dart` resolved and branch up to date: `git rev-list --count HEAD..origin/develop` prints 0. The same conflict came up a second time against @Jujoroco06's merge, and I resolved it the same way.
2. [x] Only the date at reduced widths, readable at 1280: tests at 1000, 1280, 1366 and 1417 passed. They check that each row shows only its date, no date or "Actualizada" header is truncated, and the header and values share a right edge. Rule codes and descriptions are also not truncated.
3. [x] Date and author together at wider widths: tests at 1418 and 1440 passed. They check all eight full values, untruncated and aligned with the header.
4. [ ] "The author remains available in the rule's detail": **not true yet.** `rule_editor_screen.dart` is still an empty stub, so below 1418 px the author isn't visible anywhere until the editor issue ships.

### Spec
Criteria 1 to 12 still pass on the branch. `flutter test test/screens/rules_test.dart` passed all 19 tests, covering criteria 1 to 9 at 1440 as in round 1.

1. [x] Top bar, tabs, headers and eight rows in order: test passed.
2. [x] Row values: table-driven test passed at 1440.
3. [x] Tab filtering: test passed.
4. [x] Legend: test passed.
5. [x] Navigation: tests passed.
6. [x] Camilo: test passed.
7. [x] Live update: test passed.
8. [x] Page alone: tests passed.
9. [x] Empty page: test passed.
10. [x] `grep -rln "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files.
11. [x] `grep -n "AppShell\|Navigator" lib/screens/rules/rules_page.dart` matches nothing.
12. [x] `grep -nE "Color\(0x|fontSize" lib/screens/rules/rules_page.dart lib/screens/rules/rules_screen.dart` matches nothing.
13. [ ] `git diff --stat origin/develop -- lib/widgets lib/data lib/app` now shows `lib/widgets/rule_row.dart`. This is deliberate: the feedback changes what `RuleRow` shows, and feedback wins over the spec.

## Validation
- `bash <main checkout>/factory/checks.sh` from the worktree: passed (exit 0) on `8acc0da`. `flutter analyze` found no issues, `flutter test` passed all 367 tests and `flutter build web --release` built.
- The pushed head `f0116e4` has the same tree as `8acc0da` (`git diff 8acc0da HEAD --name-only` prints nothing), so I did not re-run the checks on it.
- `flutter test test/screens/rules_test.dart`: passed, 19 tests.
- `git status --porcelain` in the worktree: prints nothing.
- GitHub CI: no check run is reported for `f0116e4`, which has no open PR. The "ci" success shown on #47 is not evidence for this code.
- Widths were checked with widget tests using Inter, not in a browser.

## Log
### Round 1
Implemented the spec from scratch. Running the suite after replacing the stub showed that `navigation_test.dart` failed on the badge overflow described above, so I added the Inter setup to that test rather than change `RuleRow`, which is out of scope. Opened draft PR #47.

### Round 2
Feedback in `feedback-1.md`:
- **Merge conflict with `develop`:** merged `origin/develop` and kept `setUpAll(loadInterFont)`, with a comment covering both the models and rules screens.
- **"Actualizada" at narrow widths:** added the compact mode. Dropping the author wasn't enough on its own: "hace 2 meses" measures about 79 px in Inter and the column has about 42 px at 1280. So in compact mode the date gets 84 px and "Regla" takes what remains, about 258 px at 1280, which still fits the longest seed description (233 px). The 1418 px threshold gives the full value 180 px. The longest seed value I measured is 171 px; the longest possible name and date combination, "hace 11 meses · Laura Cárdenas", is an estimated 181 px, so it could lose a character at exactly that width.

Review Notes from round 1: all four verdicts were PASS, so these were optional. I took the code review's suggestion to reuse the shared font helper, in the files this round touched. `rule_row_test.dart` still has its own copy.

While pushing:
- The first push was rejected because @Jujoroco06 had pushed `689556c` to this branch. I did not force-push. I merged their commit and pushed.
- Then `develop` showed PR #47 as merged. I merged `develop` into the branch and pushed `f0116e4`.
- **My mistake, corrected:** before seeing the merge, I edited PR #47's description to describe the compact mode, which that PR doesn't contain. I restored the original text. The PR's edit history still shows both changes.
