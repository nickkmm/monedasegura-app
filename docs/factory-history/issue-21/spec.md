# Rules list screen

> Issue #21: Build the rules list screen

## Summary
- Spec for the "Reglas" screen: lifecycle tabs with live counts, the rules table, the lifecycle legend and "Nueva regla" for users with `RULE_WRITE`.
- Intake's open question is settled: #16 is closed and `RuleRow`, `RuleStatusBadge`, `TableHeaderRow`, `AppTabBar` and `EmptyState` are all on `origin/develop`, so nothing needs re-creating.
- The seed and the existing `RuleRow` already produce the eight expected rows, so no data layer or shared widget change is needed.
- Only three files are in play: the `rules_screen.dart` stub is replaced, and `rules_page.dart` and `test/screens/rules_test.dart` are new.
- Where the archived PR #29 code differs from the issue (empty-state copy, legend gap, `onOpenRule` argument), the issue wins; each difference is listed below.

## Context

**Today.** `lib/screens/rules/rules_screen.dart` is a stub: a `StatelessWidget` with a `const RulesScreen()` constructor that returns `AppShell(active: NavDestination.rules, title: 'Reglas', subtitle: '', child: SizedBox.shrink())`. `lib/app/routes.dart` builds it as `const RulesScreen()` for `/rules`, so the constructor must stay const with no required arguments. `lib/screens/rules/rule_editor_screen.dart` is still a stub and belongs to another issue.

**Pattern to follow.** `lib/screens/login/login_screen.dart` and `login_page.dart` are the Screen and Page pair: the Screen is a `StatefulWidget` that reads `AppScope` and navigates, and the Page takes constructor parameters and callbacks.

**Store (`lib/data/app_store.dart`).** Widgets reach it through `AppScope.of` (`lib/app/app_scope.dart`).
- `rules` returns an unmodifiable `List<RuleView>` in store order.
- `now` is the store clock.
- `can(PermissionCode)` checks the signed-in user.
- `createRule({code, name, description, conditions, action})` appends a DRAFT rule and requires `RULE_WRITE`.
- `RuleView.latest` (`lib/data/models/rule.dart`) is the newest version, and `RuleView.rule.id` is the id used in the route.

**Routes (`lib/app/routes.dart`).** `AppRoutes.newRule` is `/rules/new` and needs `RULE_WRITE`. `AppRoutes.ruleEditor(id)` is `/rules/<id>` and needs `RULE_READ`. Both guards already exist.

**Shared widgets (`lib/widgets/`, exported by `widgets.dart`).**
- `AppShell` gives the sidebar, the `TopBar` and the scrolling content with padding 32/0/32/32. It reads `AppScope`, so it must wrap the Page in the Screen and must not be built inside the Page.
- `AppTabBar({labels, selectedIndex, onSelected})` is in `app_tab.dart`.
- `AppButton({label, onPressed, icon})` is primary by default.
- `TableHeaderRow({cells})` with `TableHeaderCell({label, width, flex, align})` is in `table_header.dart`. It uses the same horizontal padding (24) and gap (16) as `RuleRow`.
- `RuleRow({rule, now, onTap})` renders every value in a row, including the "—" dashes and `submittedAt ?? createdAt` for the last change, and draws its own bottom border.
- `RuleStatusBadge({status})` and `EmptyState({icon, title, hint})` are ready to use.
- `LegendItem` is a colored-dot chart legend, not the lifecycle legend. Do not use it here.
- There is no shared card widget. `lib/widgets/kpi_card.dart` draws its card with theme tokens.

**Theme.** `AppColors.textTertiary` is `#8B919D`. `AppSpacing.sm` is 8, `lg` is 16 and `xl` is 24. `AppRadius.lg` is 14. `AppIcons.size` is 20, which matches the last header cell. `AppIcons.plus` and `AppIcons.sliders` exist.

**Tests.** `test/helpers/pump_app.dart` has `pumpApp` and `kTestNow`. `test/helpers/harness.dart` has `harness` and `setDesktopView`. `test/app/navigation_test.dart` shows how to read `ModalRoute...settings.name` and `RuleEditorScreen.ruleId`. `test/widgets/rule_row_test.dart` loads Inter in `setUpAll`, because the default test font makes the "Pendiente" badge overflow its 130 px cell. These new tests need the same setup.

**Reference code.** `git show archive/pr-29-flutter-prototype:lib/screens/rules_page.dart` is a usable layout reference, but it differs from this issue. The issue wins on these points:
- The empty-state title here is "No hay reglas en este estado".
- The gap above the legend is 24 here, not 16.
- `onOpenRule` receives a `RuleView` here, not a code string.
- Tab labels and rows are computed by the Screen here, not by the Page.
- That file's `MinWidthScroll` and `PageFrame` do not exist on this base. `AppShell` already handles narrow widths.

## Requirements

1. `lib/screens/rules/rules_screen.dart`: `RulesScreen` becomes a `StatefulWidget`, still `const RulesScreen({super.key})`, and owns `int tab`, starting at 0.
2. `RulesScreen` reads `AppScope.of(context)` so that store changes rebuild it. It builds `AppShell(active: NavDestination.rules, title: 'Reglas', subtitle: 'Deciden qué transacciones se revisan y cuáles se bloquean', child: RulesPage(...))`.
3. `RulesScreen` computes from `store.rules`:
   - `tabLabels`, exactly "Todas · {all}", "Activas · {n}", "En shadow · {n}", "Pendientes · {n}", "Borradores · {n}". Counts use `latest.status` (ACTIVE, SHADOW, PENDING_APPROVAL, DRAFT), and "Todas" counts every rule, including RETIRED.
   - `rows`, the rules of the selected tab in store order.
4. `RulesScreen` passes `now: store.now` and `canCreate: store.can(PermissionCode.RULE_WRITE)`. It handles the callbacks with `Navigator.of(context).pushNamed`: `onNewRule` goes to `AppRoutes.newRule` and `onOpenRule` goes to `AppRoutes.ruleEditor(view.rule.id)`. `onTabSelected` calls `setState`.
5. New `lib/screens/rules/rules_page.dart`: `RulesPage` is a `StatelessWidget` with exactly this constructor:
   `RulesPage({super.key, required List<String> tabLabels, required int tab, required List<RuleView> rows, required DateTime now, required bool canCreate, required ValueChanged<int> onTabSelected, required VoidCallback onNewRule, required ValueChanged<RuleView> onOpenRule})`.
   It never references `AppScope`, `AppStore`, `Navigator` or `AppShell`, and neither does any section widget it builds. It lays out a column with a gap of 24 (`AppSpacing.xl`) holding the three blocks below.
6. **Toolbar**: a row with a gap of 16 (`AppSpacing.lg`).
   - An expanded `AppTabBar` using `tabLabels` and `tab`.
   - A primary `AppButton` "Nueva regla" with `AppIcons.plus`, built only when `canCreate`. The 16 px gap is also omitted when the button is absent.
7. **Table card**: background `AppColors.bgSurface`, 1 px `AppColors.borderDefault` border, radius `AppRadius.lg`, clipped, no padding. It holds:
   - A `TableHeaderRow` with cells "Regla" width 300, "Versión" 56, "Acción" 96, "Estado" 130, "Coinc. 7 d" 90 right, "Precisión" 80 right, "Actualizada" `flex: true` right, and an empty cell of width 20.
   - One `RuleRow(rule:, now:, onTap:)` per entry in `rows`, with `onTap` calling `onOpenRule`.
   - When `rows` is empty, `EmptyState(icon: AppIcons.sliders, title: 'No hay reglas en este estado', hint: 'Cambia de pestaña o crea una regla nueva.')` below the header, centered.
8. **Lifecycle legend**: a row with a gap of 8 (`AppSpacing.sm`), centered vertically. It shows "Ciclo de vida:" in `AppTextStyles.caption` with `AppColors.textTertiary`, then `RuleStatusBadge`s for DRAFT, SHADOW, PENDING_APPROVAL, ACTIVE and RETIRED in that order, separated by "→" in the same style.
9. Colors, spacing, radii, text styles and icons come only from `lib/theme/`. Status and action labels come from the widgets and `lib/data/labels.dart`, and numbers and dates from `RuleRow`; none are re-translated or re-formatted in the screen.
10. Add `test/screens/rules_test.dart` covering every acceptance criterion below that can be tested with widgets, loading Inter in `setUpAll` the way `test/widgets/rule_row_test.dart` does.

No doc changes are needed: `AGENTS.md` already describes this structure, and this adds no new convention.

## Acceptance criteria

Criteria 1 to 9 are widget tests in `test/screens/rules_test.dart`, run with `flutter test test/screens/rules_test.dart`. Unless stated otherwise they use `pumpApp(tester, signInAs: 'valentina.rios@monedasegura.co', initialRoute: '/rules')`.

Some text appears more than once on the page, so tests must scope their finders:
- "Reglas" is also a sidebar item, so scope it to `TopBar`.
- The status labels also appear in the legend, so scope them to the `RuleRow` of the code being checked, or to the legend.

1. The top bar shows "Reglas" and "Deciden qué transacciones se revisan y cuáles se bloquean". The tabs "Todas · 8", "Activas · 4", "En shadow · 1", "Pendientes · 1" and "Borradores · 1" are shown. So are the seven headers "Regla", "Versión", "Acción", "Estado", "Coinc. 7 d", "Precisión", "Actualizada". There are eight `RuleRow`s, in this top-to-bottom order: SCORE_BLOCK, SCORE_REVIEW, HIGH_AMOUNT_NEW_DEVICE, VELOCITY_1H, FAR_FROM_HOME, NIGHT_TRANSFER, ATO_PASSWORD_RESET, VELOCITY_5M.
2. A table-driven test checks that each row contains these values:
   - SCORE_BLOCK: v2, Bloquear, Activa, 312, 0,88, "hace 9 d · Laura Méndez"
   - SCORE_REVIEW: v4, Revisar, Activa, 2.410, 0,41, "hace 3 d · Laura Méndez"
   - HIGH_AMOUNT_NEW_DEVICE: v3, Revisar, Activa, 486, 0,57, "hace 12 d · Diego Salazar"
   - VELOCITY_1H: v1, Bloquear, Activa, 97, 0,74, "hace 20 d · Diego Salazar"
   - FAR_FROM_HOME: v1, Revisar, Shadow, 1.102, 0,33, "ayer · Laura Méndez"
   - NIGHT_TRANSFER: v2, Revisar, Pendiente, 61, 0,52, "hoy · Laura Méndez"
   - ATO_PASSWORD_RESET: v1, Bloquear, Borrador, two "—", "hoy · Diego Salazar"
   - VELOCITY_5M: v5, Bloquear, Retirada, two "—", "hace 2 meses · Laura Méndez"
3. Tapping "Activas · 4" leaves 4 `RuleRow`s. NIGHT_TRANSFER is not among them, because its latest version is pending. Tapping "Borradores · 1" leaves only ATO_PASSWORD_RESET.
4. The legend shows "Ciclo de vida:", the five `RuleStatusBadge`s in the order Borrador, Shadow, Pendiente, Activa, Retirada, and four "→".
5. Tapping "Nueva regla" opens the route named `/rules/new`, with a `RuleEditorScreen` whose `ruleId` is null. Tapping the NIGHT_TRANSFER row opens the route named `/rules/<id>`, with `ruleId` equal to `store.ruleByCode('NIGHT_TRANSFER')!.rule.id`. The tests assert the route name and `ruleId`, not the editor's content.
6. Signed in as `camilo.torres@monedasegura.co`, there is no "Nueva regla", and tapping a row still opens the editor route.
7. Signed in as `laura.mendez@monedasegura.co`, calling `store.createRule(...)` and then `tester.pump()` shows 9 `RuleRow`s, "Todas · 9" and "Borradores · 2", with no re-pump of the app.
8. Pumped alone with `harness(RulesPage(...))`, with no `AppScope` and with fake rows and callbacks:
   - Tapping "Nueva regla" calls `onNewRule` once.
   - Tapping a row calls `onOpenRule` with that `RuleView`.
   - Tapping the second tab calls `onTabSelected(1)`.
   - `canCreate: false` shows no "Nueva regla".
9. Pumped alone with `rows: []`, the page shows the headers, "No hay reglas en este estado", "Cambia de pestaña o crea una regla nueva." and no `RuleRow`.
10. `grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files.
11. `grep -n "AppShell\|Navigator" lib/screens/rules/rules_page.dart` matches nothing.
12. `grep -nE "Color\(0x|fontSize" lib/screens/rules/rules_page.dart lib/screens/rules/rules_screen.dart` matches nothing.
13. `git diff --stat origin/develop -- lib/widgets lib/data lib/app` shows no changes.

## Out of scope

- The rule editor, including anything in `rule_editor_screen.dart`.
- Sorting or searching rules, and bulk actions.
- Any change to the seed, the store, the routes or the shared widgets. `RuleRow` already shows every expected value.
- A new shared card widget or other refactors of existing widgets.
- Re-creating anything from the PR #29 tag, such as `MsCard`, `PageFrame` or `MinWidthScroll`, or using its `lib/data/models.dart`, `mock_data.dart` or `prototype_labels.dart`.
- Persisting the selected tab outside `RulesScreen`.
- Layout changes for narrow windows beyond what `AppShell` already does.

## Assumptions

- **The table card is drawn inline in `rules_page.dart` with theme tokens, not added as a shared widget.** The gallery has no card component and `kpi_card.dart` does the same, so a shared card would be an unrequested refactor.
- **The "flexible space, Actualizada right" header is one `TableHeaderCell(flex: true, align: TextAlign.right)`.** This matches `RuleRow`'s `Expanded` right-aligned cell, so the column lines up with the rows.
- **Opening the editor uses `pushNamed`, not `pushReplacementNamed`.** The editor is a detail of the list, so going back returns to the list with the selected tab intact.
- **The selected tab resets to "Todas" when the user leaves through the sidebar.** The sidebar replaces the route, and the issue keeps the tab as Screen state only.
- **The toolbar row uses `CrossAxisAlignment.end`.** The issue gives no alignment, and the reference code uses this so the button lines up with the tab bar's bottom border.
- **The empty state gets 48 px (`AppSpacing.xxxl`) of vertical padding inside the card.** The issue gives no value, and this leaves it clear of the header using an existing token.
- **At the 1280 minimum width, "Actualizada" and its values get about 44 px and truncate with an ellipsis.** The issue fixes the other column widths, and at the 1440 reference width the column has about 200 px, which fits the text.
