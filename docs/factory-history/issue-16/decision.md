ESCALATE

## Summary
- Adds four presentation-only shared widgets (`CaseRow`, `RuleRow`, `ConditionRow`, `TableHeaderRow`/`TableHeaderCell`), exported from `widgets.dart`, plus widget tests for each.
- Round 2 gate passed on HEAD f03e1f6. All three reviews say `VERDICT: PASS`. Round 1's only UI finding (the dropdowns had no indicator) is fixed.
- One small step outside the spec: a 2-line `AppIcons.chevronDown` token was added in `lib/theme/app_icons.dart`, which the reviewer asked for. The spec had listed theme changes as out of scope.
- It touches no money, auth, permissions, CI, deploy, migration, environment variable, dependency or infra docs.
- Escalated because a person always merges in this project. Recommendation: merge.

## Why
All 12 acceptance criteria are met. I re-ran the four new test files (14 tests, all pass) and the criteria 11 and 12 greps (no output) myself. The final checks are on HEAD f03e1f6 and every review passes. The review notes that remain are non-blocking. They belong to the future host screens: horizontal scroll at phone width, keyboard access, a tooltip and tap target for the remove icon. The `textTertiary` contrast is a question for the design owners. The only scope deviation is one additive icon token, made at a reviewer's request.

## Acceptance criteria
1. CaseRow b204e7 cells: met. The test "shows the cells of a review case" passes; I re-ran it.
2. 7f0b6a "Transferencia"/"Bloqueada", 09f35b "—": met. The case_row test passes.
3. Tap calls onTap once, and hover sets `bgHover`: met. The case_row tap and hover tests pass.
4. RuleRow NIGHT_TRANSFER cells including "0,52" and "hoy · Laura Méndez": met. rule_row_test passes. I also read `rule_row.dart`: precision and hits follow the spec, including "—" for DRAFT and RETIRED.
5. ATO_PASSWORD_RESET shows "Borrador" and two "—": met. rule_row_test passes.
6. Read-only amount condition shows "amount", "≥", "$ 2.000.000" and no close icon: met. condition_row_test passes.
7. is_night true shows "Sí": met. condition_row_test passes.
8. Editable mode: close calls onRemove, and typing calls onValueChanged: met. condition_row_test passes.
9. TableHeaderRow labels are `textTertiary`: met. table_header_test passes.
10. All four files exist and are exported: met. I checked the `widgets.dart` diff.
11. No AppScope/AppStore in the four files: met. I re-ran the grep and it printed nothing.
12. No `Color(0x` or `fontSize` in the four files: met. I re-ran the grep and it printed nothing.

## For the human
Recommendation: merge

- None of the project's "check before merging" triggers apply. There is no contract, data model or feature catalog change, no migration, no environment variable, no `docker-compose.yml`, and no JWT, permission, scoring token or simulator access change.
- One decision for you: are you OK with the new theme token `AppIcons.chevronDown` in `lib/theme/app_icons.dart`? The spec said not to change the theme. The round 1 UI reviewer asked for the token so the editable dropdowns no longer look like plain text. It is additive and kept out of `AppIcons.all`, so the 20-icon gallery test still holds. It may differ from the Figma prototype, where the dropdown arrow is hidden. If you'd rather match Figma exactly, drop commit f03e1f6's icon part.
- Files to look at: `lib/widgets/condition_row.dart` (the editable mode, the dropdowns and `_displayValue`/`_rawValue`), `lib/widgets/case_row.dart`, `lib/widgets/rule_row.dart`, `lib/widgets/table_header.dart`, `lib/theme/app_icons.dart`.
- Walk through the app with `flutter run -d chrome` once a screen hosts these rows. For now no page uses them, so only the widget tests cover them.
- Carry these review notes into the screens that will host these widgets: horizontal scroll at phone width, a keyboard path for the rows, and a tooltip "Quitar condición" with a larger hit area for the remove icon. Separately, the `textTertiary` contrast (about 3.2:1) is a design-token question.
