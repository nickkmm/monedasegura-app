# App shell, permission-guarded routes and simulated login

> Issue #17: Add the app shell, routing with permission guards and the simulated login

## Summary
- Specifies the simulated login, the console frame (sidebar, top bar, shell), the guarded routes and seven stub screens, so the app can be walked through end to end.
- Checked the dependencies intake could not read: `lib/theme/`, the widgets from #13, `AppStore` and `setDesktopView` are all in the worktree, and no new token is needed.
- Carries over intake's rulings where the issue contradicts itself or the code (`AppScope(store:)`, redirect names, start route, logout rebuild).
- Adds what the issue misses: `AGENTS.md` must name `AppShell` as the one exception to its "never `AppScope`" rule, and fixed-width text must not overflow under the test font.
- Screen content, real auth and a mobile layout stay out.

## Context
**Today.** `lib/main.dart` defines a `const MonedaSeguraApp` that shows the placeholder `lib/login_screen.dart`. There are no routes. `test/widget_test.dart` pumps that app. Nothing else references `lib/login_screen.dart`.

**What this builds on (all present in the worktree):**
- `lib/app/app_scope.dart`: `AppScope({required AppStore store, required Widget child})`, with `AppScope.of` (rebuilds) and `AppScope.read` (callbacks).
- `lib/data/app_store.dart`: `AppStore.seeded({clock})`; `AppUser? signIn(email, password)`, which is synchronous, trims and lowercases the email, and notifies listeners; `signOut()`, which notifies listeners; `currentUser`.
- `lib/data/models/app_user.dart`: `AppUser.can(PermissionCode)`, `initials`, `fullName`, `roles`. `lib/data/labels.dart`: `RoleCode.label` ("Administradora", ...). `lib/data/mock/mock_seed.dart`: `MockSeed.demoPassword` and the six users.
- `lib/theme/`: `buildAppTheme()`, `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppIcons`. Hex values in the issue map to existing tokens: `#14213D` `navBg`/`bgInverse`, `#1D2C4D` `navHover`, `#27385E` `navActive`, `#C3CBDA` `navText`, `#FFFFFF` `navTextActive`/`textInverse`/`bgSurface`, `#7F8AA3` `navTextMuted`, `#2B59C3` `accent`, `#F3F4F6` `bgCanvas`, `#161B26` `textPrimary`, `#545B69` `textSecondary`, `#8B919D` `textTertiary`, `#DFE2E8` `borderDefault`. Radius 6 is `AppRadius.sm`, 10 is `md`, full is `full`. `AppColors.onInverseMuted`, `AppTextStyles.hero` and every icon in the issue exist.
- `lib/widgets/`: `AppButton`, `AppTextField` (has `errorText`, `onSubmitted`, `keyboardType`), `AppAvatar(initials:, background:, size:)`, and the barrel `lib/widgets/widgets.dart`. Sizes outside the spacing scale are private consts in the widget, as `AppTextField._height` does.
- `test/helpers/harness.dart`: `harness()` and `setDesktopView()`. `test/widgets/app_button_test.dart` shows the hover-test pattern (mouse `createGesture`).
- Tag `archive/pr-29-flutter-prototype`: reference code (`lib/screens/login_screen.dart` has a guilloche painter; `lib/widgets/sidebar.dart`, `top_bar.dart`). Read with `git show`. This spec wins over it, and its `lib/data/models.dart`, `mock_data.dart` and `prototype_labels.dart` must not be used.

## Requirements

The full issue is at `factory/jobs/003-add-the-app-shell/issue.md` (and `docs/factory-history/issue-17/issue.md` in the PR). Any Figma value or string not restated here comes from it, under its section of the same name. All on-screen strings must match it exactly.

### App entry and routes
1. `lib/main.dart` only runs `MonedaSeguraApp(store: AppStore.seeded())`. `lib/login_screen.dart` is deleted.
2. `lib/app/app.dart` defines `MonedaSeguraApp({required AppStore store, String initialRoute = AppRoutes.login})`: `AppScope(store: store, child: MaterialApp(...))`, keeping today's title, `es_CO` locale, supported locales, delegates, theme and no debug banner.
3. Starting on any route produces exactly one page, whatever the guard decides. Use `onGenerateInitialRoutes` to run the guard once on the full name, so Flutter does not split `/cases/abc` into a stack.
4. `lib/app/nav_destination.dart` defines the enum `NavDestination` in this order, each with label, icon, route and permission:

   | Value | Label | Icon | Route | Permission |
   |---|---|---|---|---|
   | `dashboard` | Dashboard | `AppIcons.dashboard` | `/dashboard` | `DASHBOARD_READ` |
   | `cases` | Casos | `AppIcons.inbox` | `/cases` | `CASE_READ` |
   | `rules` | Reglas | `AppIcons.sliders` | `/rules` | `RULE_READ` |
   | `models` | Modelos | `AppIcons.cpu` | `/models` | `MODEL_READ` |
   | `simulator` | Simulador | `AppIcons.play` | `/simulator` | `SIMULATOR_RUN` |

5. `lib/app/routes.dart` defines:
   - `abstract final class AppRoutes` with `login`, `dashboard`, `cases`, `caseDetail(id)`, `rules`, `newRule`, `ruleEditor(id)`, `models`, `simulator`.
   - `String firstAllowedRoute(AppUser user)`: the route of the first destination the user can open, or `AppRoutes.login` if there is none.
   - `Route<dynamic>? onGenerateRoute(RouteSettings s, AppStore store)`, mapping `/login` to `LoginScreen`, the five destination routes to their screens, `/cases/<id>` to `CaseDetailScreen(caseId: id)`, `/rules/new` to `RuleEditorScreen(ruleId: null)` and `/rules/<id>` to `RuleEditorScreen(ruleId: id)`. `/rules/new` is matched before `/rules/<id>`.
6. Guards, in order:
   - `/login` always shows the login, even when signed in.
   - Signed out, any other path goes to the login.
   - A missing permission or an unknown path goes to `firstAllowedRoute(user)`. Case routes need `CASE_READ`, `/rules` and `/rules/<id>` need `RULE_READ`, `/rules/new` needs `RULE_WRITE`, the others follow the table. Permission checks go through `AppUser.can`, never role names.
   - Unknown paths include `/`, a null name, extra segments (`/cases/a/b`), an empty id (`/cases/`) and a name that cannot be parsed as a URI (use `Uri.tryParse`; malformed names must not throw).
7. Every page is a `PageRouteBuilder` with zero `transitionDuration` and `reverseTransitionDuration`. Routes that are not redirected use `settings: s`. A redirected route carries the target's name in its `RouteSettings`, not the requested path.

### Stubs
8. The seven stubs exist at the paths, class names and constructors in the issue. Each returns `AppShell(active:, title:, subtitle: '', child: const SizedBox.shrink())`:

   | File under `lib/screens/` | Class | Title | Active |
   |---|---|---|---|
   | `dashboard/dashboard_screen.dart` | `DashboardScreen()` | Dashboard | `dashboard` |
   | `cases/case_queue_screen.dart` | `CaseQueueScreen()` | Cola de casos | `cases` |
   | `cases/case_detail_screen.dart` | `CaseDetailScreen({required String caseId})` | Caso | `cases` |
   | `rules/rules_screen.dart` | `RulesScreen()` | Reglas | `rules` |
   | `rules/rule_editor_screen.dart` | `RuleEditorScreen({String? ruleId})` | Regla | `rules` |
   | `models/models_screen.dart` | `ModelsScreen()` | Modelos | `models` |
   | `simulator/simulator_screen.dart` | `SimulatorScreen()` | Simulador | `simulator` |

### Shell widgets
9. `lib/widgets/nav_item.dart`, `app_sidebar.dart`, `top_bar.dart` and `app_shell.dart` each hold one public widget and are exported from `lib/widgets/widgets.dart`.
10. `NavItem({icon, label, active, onTap})`, per the issue's `NavItem` section: height 36, full width, horizontal padding 12, radius 6, gap 12, icon 20, label `bodyStrong`. Default: no background, `navText`. Hover: `navHover`, white. Active: `navActive`, white. Hover state is the only state it keeps.
11. `AppSidebar({required NavDestination active, required AppUser user, required List<NavDestination> destinations, required ValueChanged<NavDestination> onNavigate, required VoidCallback onLogout})`, per the issue's `AppSidebar` section: width 240, `navBg`, brand, "Operación", one `NavItem` per entry of `destinations` in the given order, spacer, user card. The sidebar does no permission filtering. The role line is `user.roles.first.label`. The logout control is a 20 px `AppIcons.logout` in `navText` with tooltip "Cerrar sesión".
12. `TopBar({required String title, required String subtitle})`, per the issue's `TopBar` section: height 72, the search pill with hint "Buscar transacción, cliente…" and the bell. Neither has behavior yet.
13. `AppShell({active, title, subtitle, child})`, per the issue's `AppShell` section:
    - It is the only file in `lib/widgets/` that names `AppScope` or `AppStore`, and it reads only the session from them. It reads `currentUser` with `AppScope.of`.
    - It computes the visible destinations with `user.can` and passes them to `AppSidebar`.
    - Navigating uses `Navigator.pushReplacementNamed`.
    - Logging out calls `signOut()`, then `pushNamedAndRemoveUntil(AppRoutes.login, (_) => false)`.
    - With no current user it renders `SizedBox.shrink()` and does not throw, because `signOut()` notifies before the navigation runs.
    - Below 1280 wide, the shell lays out at 1280 and scrolls horizontally.
14. Text in fixed-width areas (brand name, nav label, user name, role, top bar title and subtitle) sits in `Expanded` or `Flexible` with `maxLines: 1` and `TextOverflow.ellipsis`. Widget tests use a font whose glyphs are a full em wide, so without this the sidebar brand overflows and fails the test.
15. The widgets take everything through constructors, and no file in `lib/widgets/` other than `app_shell.dart` names `AppScope` or `AppStore`, even in comments.

### Login
16. `lib/screens/login/login_screen.dart`: `LoginScreen` (StatefulWidget) owns the two controllers and `String? error`, reads the store with `AppScope.read`, and on submit:
    - If the trimmed email is empty or the password is empty, sets "Escribe tu correo y tu contraseña." without calling `signIn`.
    - Otherwise calls `signIn`. On success, `pushReplacementNamed(firstAllowedRoute(user))`. On failure, sets "Correo o contraseña incorrectos."
    - Passes `loading: false` to the page.
17. `lib/screens/login/login_page.dart`: `LoginPage` (StatelessWidget) takes the controllers, `error`, `loading` and `onSubmit`, and never calls `AppScope`. Layout, copy and sizes follow the issue's Login section. The message shows through the password field's `errorText`. `loading` true disables the button (`onPressed: null`). Pressing Enter in the password field submits.
18. `lib/screens/login/guilloche_painter.dart`: `GuillochePainter`, in a 760 x 760 box at left 120, top 340 inside the clipped hero, behind the text: 24 ellipses centered in the box, radii 360 x 125, rotated k x 7.5 degrees (k = 0..23), 1 px stroke of `AppColors.textInverse` at 9 % alpha; plus 3 concentric circles with radii 59.5, 119.5 and 179.5, 1 px stroke at 7 % alpha. Alpha uses `withValues`, as `AppButton` does.
19. Below 1000 wide (hero 620 + form 380), the login lays out at 1000 and scrolls horizontally rather than overflowing.

### Tests
20. `test/helpers/pump_app.dart` defines `kTestNow` and `pumpApp` exactly as the issue says, reusing `setDesktopView` from `test/helpers/harness.dart`.
21. Add `test/app/navigation_test.dart`, `test/screens/login_test.dart` and `test/widgets/shell_widgets_test.dart`, and rewrite `test/widget_test.dart`, covering the acceptance criteria below.

### Docs
22. `README.md` gets a "Demo accounts" section (in English) listing the six seed users with email and role code, and stating the shared password is `MockSeed.demoPassword` = `MonedaSegura2026`. Update its `Status: skeleton` to match `AGENTS.md`.
23. `AGENTS.md`:
    - Line 8: replace the "placeholder sign-in screen" status with the current state (simulated login and console shell with stub screens).
    - **Shared widgets** bullet: name `AppShell` as the one exception that reads `AppScope`, for the session only.
    - Add one short **Routing** bullet: `lib/app/routes.dart` holds the routes and guards, `lib/app/nav_destination.dart` the sidebar destinations, new screen tests use `pumpApp` from `test/helpers/pump_app.dart`.

## Acceptance criteria

Each test-backed criterion is verified by running the named file with `flutter test <file>`.

1. **Start screen.** `test/widget_test.dart`: the app starts on the login showing "Iniciar sesión", "Correo", "Contraseña", "Entrar", text containing "Detén el fraude", and "MonedaSegura".
2. **Login errors.** `test/screens/login_test.dart`:
   - A wrong password shows "Correo o contraseña incorrectos." and stays on the login.
   - Both fields empty shows "Escribe tu correo y tu contraseña.", and so do an email of only spaces and a missing password.
3. **Login success.** `test/screens/login_test.dart`: Valentina's credentials land on the Dashboard stub (`TopBar` title "Dashboard") with sidebar items "Dashboard", "Casos", "Reglas", "Modelos", "Simulador" and the user card "Valentina Ríos" / "Administradora". The same sign-in triggered by `tester.testTextInput.receiveAction(TextInputAction.done)` from the password field also lands there.
4. **Login layout.** `test/screens/login_test.dart`: a `CustomPaint` with a `GuillochePainter` is present, and at a 900 x 700 view the login pumps with no exception and a horizontal `Scrollable`.
5. **Sidebar by permission.** `test/app/navigation_test.dart`: signed in as Camilo Torres, the sidebar shows Dashboard, Casos, Reglas, Modelos and not "Simulador".
6. **Guards.** `test/app/navigation_test.dart`, checking both the `TopBar` title and `ModalRoute.of(context)!.settings.name`:
   - Camilo pushing `/simulator` lands on `/dashboard`.
   - Laura Cárdenas pushing `/rules/new` lands on `/dashboard`, and `/rules/abc` opens "Regla" for her.
   - Valentina on `/rules/new` opens `RuleEditorScreen` with `ruleId` null.
   - A signed-in user on `/nope` or `/cases/a/b` lands on `/dashboard`.
   - Signed out, `/dashboard`, `/cases/abc` and `/nope` each show the login.
7. **Start route.** `test/app/navigation_test.dart`: `pumpApp(signInAs: Camilo's email, initialRoute: '/cases/abc')` shows `CaseDetailScreen` with `caseId` "abc", "Casos" active, and `Navigator.canPop` false. `initialRoute: '/simulator'` for Camilo gives `/dashboard` with `canPop` false.
8. **Navigating.** `test/app/navigation_test.dart`: for Valentina, tapping each sidebar item opens the screen with the title Dashboard, Cola de casos, Reglas, Modelos, Simulador, and that item's background is `AppColors.navActive`.
9. **Logout.** `test/app/navigation_test.dart`: tapping the logout control shows the login, `store.currentUser` is null, `tester.takeException()` is null, and `Navigator.canPop` is false.
10. **`firstAllowedRoute`.** `test/app/navigation_test.dart`: it returns `/dashboard` for a seed user and `/login` for an `AppUser` with `roles: []`.
11. **Shell width.** `test/app/navigation_test.dart`: at a 1000 x 800 view, a signed-in screen pumps with no exception and a horizontal `Scrollable`.
12. **`NavItem`.** `test/widgets/shell_widgets_test.dart`: default, hover and active background, icon and text colors equal the tokens in requirement 10, and a tap calls `onTap`.
13. **`TopBar`.** `test/widgets/shell_widgets_test.dart`: it shows the title, the subtitle and "Buscar transacción, cliente…", at height 72.
14. **`AppSidebar` alone.** `test/widgets/shell_widgets_test.dart`: pumped through `harness()` with no `AppScope` and a fake user, it shows "MonedaSegura" and "Operación", renders exactly the `destinations` given, the user card shows name and role, and `onNavigate` and `onLogout` are called with the expected values.
15. **Old file gone.** `test ! -e lib/login_screen.dart` succeeds and `lib/main.dart` has no widget class.
16. **Store isolation.** `grep -rln "AppScope\|AppStore" lib/widgets` prints only `lib/widgets/app_shell.dart`.
17. **Tokens only.** `grep -rnE "Color\(0x|fontSize:|lucide" lib/app lib/screens lib/widgets` prints nothing.
18. **Barrel.** `lib/widgets/widgets.dart` exports `app_shell.dart`, `app_sidebar.dart`, `nav_item.dart` and `top_bar.dart`.
19. **Docs.** `README.md` has a "Demo accounts" section with all six emails and `MonedaSegura2026`. `AGENTS.md` names `AppShell` in the Shared widgets bullet, has a Routing bullet, and no longer says "placeholder sign-in screen".

## Out of scope
- The content of the seven screens, beyond the stubs.
- Search and notification behavior: the pill and bell are visual only.
- A real `POST /auth/login`, storing a token, or keeping the session across a browser reload.
- A mobile layout or bottom navigation bar.
- A `signed-in user on /login` redirect, a dedicated 404 page, or a "not allowed" message.
- A loading state or delay on sign-in (`loading` is only wired through).
- Changing `AppStore`, `lib/data/`, `AppScope`, `AppButton`, `AppTextField`, `AppAvatar`, or `lib/theme/` (no token is missing).
- Using `lib/data/models.dart`, `mock_data.dart` or `prototype_labels.dart` from the archive tag.
- Changes to `factory/checks.sh`, `factory/config.json`, or the other repos.

## Assumptions
- **Sidebar parameter name:** the visible list is called `destinations`. The issue requires the prop but doesn't name it.
- **Password not trimmed for the empty check:** a password of only spaces goes on to `signIn` and gets the "incorrect" message, because `signIn` compares passwords exactly and spaces could be typed deliberately.
- **Error stays until the next submit:** typing doesn't clear it. The issue only defines the message on submit.
- **Login minimum width 1000:** the issue only sets a minimum for the shell. This is the smallest width that shows the hero and the 380 form in full, and it avoids overflow on narrow windows without adding a mobile layout.
- **Session lost on reload:** on web, a reload recreates the store, so the user is signed out and sees the login. The issue rules out storing a token.
- **Malformed route names count as unknown paths:** on web the user can type the URL hash, and a bad path must not crash the app.
- **Demo accounts list role codes:** the README is English, and Spanish labels are for on-screen text only.
- **`AppShell` filters with `user.can` directly:** this is the "session only" read the issue allows, and it keeps role names out of the check.
