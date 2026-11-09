DECISION: ACCEPT
RISK: medium
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: a small layout fix for the "Actualizada" column of the rules table, plus removing one duplicate test setup.
- The issue's owner already made the product decision, so there is nothing to ask: only the date at reduced widths, date and author at wider ones.
- No contract, data model or feature catalog change is needed.
- Commit `8acc0da` may be reused, but it has never been reviewed, so it gets the full gate and reviews here.
- Risk is medium because the change touches the shared `RuleRow` widget and the column layout, not because the behaviour is sensitive.

## Scope
Build:
- **Reduced widths, including the 1280 px minimum:** each row of the rules table shows only the date in "Actualizada", such as "hace 2 meses", in full. The "Actualizada" header is not truncated either, and header and values stay right-aligned with each other.
- **Wider widths, including 1440 px:** date and author show together as they do today, such as "hace 2 meses · Laura Méndez", in full for the seed data.
- **Switching:** the header and all rows change mode together, based on the width available to the table. The issue proposes 1418 px of window width as the switch point. Keep it unless the spec writer finds a better value that still meets the criteria.
- **"Regla" column:** below the switch point it may give up its fixed 300 px, down to about 258 px at 1280, to make room. Seed rule codes and descriptions must still fit without truncation at 1280.
- **`RuleRow`:** its default output stays the same, so any other use of it is unaffected unless it opts in. Its existing tests and the rules list behaviour keep passing.
- **Test cleanup:** remove the duplicate Inter font setup in `test/app/navigation_test.dart`, leaving one.
- **Tests:** widget tests at 1280 and 1440, plus both sides of the switch point, and a test of the new `RuleRow` mode.

Points for the spec writer:
- **Check the longest value at the switch point.** The earlier build estimated that the longest possible value, "hace 11 meses · Laura Cárdenas", needs about 181 px, against 180 px available at exactly 1418. It could lose a character there, so measure it, and adjust the switch point if needed.
- **Check `develop` first.** Confirm on the current `origin/develop` that the rules list uses `RuleRow` as described and whether anything else now uses it.
- **Reuse only the change itself.** If `8acc0da` is reused, bring over only that fix from `factory/004-build-the-rules-list`, not the rest of the branch or its job record.

Left out:
- **Author on the rule detail screen.** That belongs to #22. Until it ships, the author appears nowhere below the switch point, which the issue accepts as a known limit.
- **Other table or column changes,** and any wider rework of the rules screen.

## Why
The problem is confirmed by the job record for #21: `factory/jobs/004-build-the-rules-list/build.md` and its UI review put the column at about 42 to 44 px at 1280, and the build log shows PR #47 merged 22 seconds before the fix was pushed. In `lib/widgets/rule_row.dart`, "Regla" has a fixed 300 px and "Actualizada" only gets the leftover space, which matches that report. It is one small PR in the rules table, within the rules screen of the MVP.

I read `rule_row.dart` from the worktrees of factory jobs 005 and 006, because this job's worktree doesn't exist yet and those copies predate #47. In them, nothing in `lib/` uses `RuleRow` yet. I couldn't read `origin/develop` or commit `8acc0da` directly, so what they contain comes from the build log, and the spec writer should verify it.
