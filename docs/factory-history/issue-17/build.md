STATUS: READY

# Build: App shell, permission-guarded routes and simulated login

## Summary
- The app starts on a simulated login and signs in with the mock users.
- A signed-in user gets the console frame (sidebar, top bar), with only the destinations their permissions allow, and seven stub screens.
- Routes are guarded: signed out goes to the login; a missing permission or an unknown or malformed path goes to the first allowed destination.
- Logging out returns to the login with an empty navigation stack.
- Draft PR: https://github.com/nickkmm/monedasegura-app/pull/42

## Changes
- `lib/main.dart`: only runs `MonedaSeguraApp(store: AppStore.seeded())`. `lib/login_screen.dart` is deleted.
- `lib/app/app.dart`: `MonedaSeguraApp`, with `AppScope` around `MaterialApp`. `onGenerateInitialRoutes` guards the full start route once, so it gives one page.
- `lib/app/nav_destination.dart`: the `NavDestination` enum (label, icon, route, permission).
- `lib/app/routes.dart`: `AppRoutes`, `firstAllowedRoute`, `onGenerateRoute` and the guards. Pages have zero-length transitions, and a redirected route carries the target's name.
- `lib/screens/{dashboard,cases,rules,models,simulator}/`: the seven stubs.
- `lib/screens/login/`: `LoginScreen` (controllers, error, submit), `LoginPage` (layout, no store access, 1000 minimum width) and `GuillochePainter`.
- `lib/widgets/nav_item.dart`, `app_sidebar.dart`, `top_bar.dart`, `app_shell.dart`: the shell widgets, exported from `widgets.dart`. Only `AppShell` reads `AppScope`, for the session, and it lays out at 1280 minimum width.
- `test/helpers/pump_app.dart`, `test/app/navigation_test.dart`, `test/screens/login_test.dart`, `test/widgets/shell_widgets_test.dart`: new. `test/widget_test.dart`: rewritten.
- `README.md`: "Demo accounts" section and updated status. `AGENTS.md`: updated status, `AppShell` exception, Routing bullet.

## Acceptance criteria
Criteria 1 to 14 were checked with `flutter test <file>`; each named file printed "All tests passed!".

1. [x] Start screen: `test/widget_test.dart` passes, with all the login strings found.
2. [x] Login errors: `test/screens/login_test.dart` passes. It covers a wrong password (stays on the login), and both fields empty, an email of only spaces and a missing password.
3. [x] Login success: `test/screens/login_test.dart` passes, for the button and for `receiveAction(TextInputAction.done)`. Both land on "Dashboard" with the five items and "Valentina Ríos" / "Administradora".
4. [x] Login layout: `test/screens/login_test.dart` passes. The `GuillochePainter` is present in a 760 x 760 box, and it draws 24 ovals and 3 circles with the specified stroke and alpha. At 900 x 700 there is no exception and there is a horizontal scroll view.
5. [x] Sidebar by permission: `test/app/navigation_test.dart` passes. Camilo gets four items and no "Simulador".
6. [x] Guards: `test/app/navigation_test.dart` passes, checking the title and `settings.name` for every listed case. It also covers `/`, `/cases/`, `/rules/`, a relative name and the malformed `http://[`.
7. [x] Start route: `test/app/navigation_test.dart` passes. `/cases/abc` gives `caseId` "abc", "Casos" active and `canPop` false. `/simulator` for Camilo gives `/dashboard` and `canPop` false.
8. [x] Navigating: `test/app/navigation_test.dart` passes, with the five titles and each item's background `AppColors.navActive`.
9. [x] Logout: `test/app/navigation_test.dart` passes. It shows the login, `currentUser` is null, `takeException` is null and `canPop` is false.
10. [x] `firstAllowedRoute`: `test/app/navigation_test.dart` passes (`/dashboard` for a seed user, `/login` for `roles: []`).
11. [x] Shell width: `test/app/navigation_test.dart` passes. At 1000 x 800 there is no exception and there is a horizontal scroll view; at 1440 there is none.
12. [x] `NavItem`: `test/widgets/shell_widgets_test.dart` passes, for default, hover and active colors and the tap.
13. [x] `TopBar`: `test/widgets/shell_widgets_test.dart` passes, for the three texts and height 72.
14. [x] `AppSidebar` alone: `test/widgets/shell_widgets_test.dart` passes with no `AppScope` and a fake user, including `onNavigate` and `onLogout`.
15. [x] Old file gone: `test ! -e lib/login_screen.dart` succeeds, and `grep -c "class " lib/main.dart` prints 0.
16. [x] Store isolation: `grep -rln "AppScope\|AppStore" lib/widgets` prints only `lib/widgets/app_shell.dart`.
17. [x] Tokens only: `grep -rnE "Color\(0x|fontSize:|lucide" lib/app lib/screens lib/widgets` prints nothing (exit 1).
18. [x] Barrel: `lib/widgets/widgets.dart` exports the four files (checked with grep).
19. [x] Docs: `README.md` has "Demo accounts", all six emails and `MonedaSegura2026`. `AGENTS.md` names `AppShell` in the Shared widgets bullet, has a Routing bullet and has no "placeholder sign-in" text.

The app was not run in a browser: per `AGENTS.md`, agents check UI with widget tests and by reading the code, and a person walks through it with `flutter run -d chrome`.

## Validation
- `bash factory/checks.sh` from the worktree: passed (exit 0). That covers `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze` ("No issues found!"), `flutter test` (284 tests, "All tests passed!") and `flutter build web --release` (built `build/web`).
- `flutter test` on each of the four named test files: passed.

## Log
### Round 1
Built the spec from scratch: login, routes and guards, shell widgets, stubs, tests and docs.

Choices the spec left open:
- `_match` in `routes.dart` splits the raw `uri.path` rather than using `Uri.pathSegments`, because decoding can throw on bad bytes such as `/cases/%ff`. As a result, ids reach the screens undecoded. A test covers this case.
- The form sits in a vertical `SingleChildScrollView`, so a short window scrolls it. The hero has no such handling and can overflow in a very short window.
- The horizontal-scroll tests look for a horizontal `SingleChildScrollView`, not any `Scrollable`, because every single-line `TextField` holds a horizontal `Scrollable` of its own. They also assert there is none at 1440.
- The minimum-width wrapper is written inline in both `AppShell` and `LoginPage`, because the spec lists no shared widget for it.
- The new widgets use the `spacing:` parameter of `Row` and `Column`; the existing widgets use `SizedBox` gaps.
