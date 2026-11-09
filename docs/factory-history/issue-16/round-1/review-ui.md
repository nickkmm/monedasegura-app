VERDICT: CHANGES

## Summary
- The branch adds four presentation-only shared widgets (`CaseRow`, `RuleRow`, `ConditionRow`, `TableHeaderRow`) and exports them from `widgets.dart`. No screen uses them yet, so nothing shows on a page.
- Colours, type styles, spacing, radii and icons all come from `lib/theme/` and match the neighbouring badges and score bar. No hex colour, font size or AppScope/AppStore use.
- One visible gap: in editable mode the feature and operator boxes are dropdowns with no indicator, so they look like read-only text.
- The rows are fixed-width and overflow a phone-width viewport. This is a note for the screen that places them, not a defect of the widgets.
- Checked by reading the code, the theme and the spec. No dev server or screenshot, because AGENTS.md says there is no browser check here and the widgets are not on a page.

## Findings
1. `lib/widgets/condition_row.dart:114` The editable feature and operator boxes are `DropdownButton`s with `icon: const SizedBox.shrink()`, so nothing marks them as menus. They look identical to the read-only boxes next to them. Show a small chevron-down in `AppIcons.size` and `AppColors.textTertiary` at the right of the feature and operator boxes. The app has no `chevronDown` yet, so add `AppIcons.chevronDown` (Lucide `chevronDown`) in `lib/theme/app_icons.dart`, and keep the rest of the layout as it is.

## Notes
- Not blocking. `CaseRow` and `RuleRow` are fixed-width rows, about 1120 px and 930 px wide. The queue and rules screens must put them in a horizontal scroll view at phone width, or the rows overflow. The widgets should not hard-code a scroll.
- Not blocking. `AppColors.textTertiary` (`#8B919D`) on `#FFFFFF` is about 3.2:1. That is below the 4.5:1 AA target for the 11 to 12 px text it carries here: the table header labels, the age in `CaseRow`, and the "hoy · nombre" caption in `RuleRow`. The spec requires this token, so this is a token-level decision for the design owners, not a fix for this branch.
- Not blocking. The `ConditionRow` remove icon is a bare 20 px `GestureDetector` with no padding or tooltip. The tap target is small, and it has no accessible label. Consider a 24 px or larger hit area with a `Tooltip` when the screen wires it.
- Not blocking. `CaseRow` and `RuleRow` are mouse-only (`MouseRegion` and `GestureDetector`). They have no focus or keyboard activation, so a screen that uses them for navigation should wrap them with the keyboard handling it needs.
- Hover, border and padding values match the spec: 60 px and 64 px heights, `bgHover` on hover, `borderDefault` bottom border, and the chevron turns `textPrimary` on hover.
- The COP and decimal formatting in `ConditionRow` (`300` to "300", `0.6` to "0,6", `amount` to "$ 2.000.000") matches the spec. The trailing-zero regex was checked on `0`, `10`, `100`, `1000`, `0.6`, `1.5` and `300`.
