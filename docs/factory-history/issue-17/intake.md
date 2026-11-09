DECISION: ACCEPT
RISK: medium
SURFACES: ui, security
RESCOPED: no

## Summary
- Accepted as written: the simulated login, console frame, permission-guarded routes, seven stub screens and the demo accounts in the README.
- It fits in one PR because the screens stay stubs and the issue fixes the values, names and tests.
- No contract or data model change is needed: the permissions, roles and seed users the criteria use already match `model.md` and `lib/data/`.
- The issue contradicts itself or the code in a few places, so the readings to use are listed below.
- Not verified: `lib/theme/` and the widgets from #10 and #13 aren't in the checkout I could read, so the spec writer must confirm them first.

## Scope
Build what the issue specifies, on `origin/develop`:

- **Login**: `LoginScreen`, `LoginPage` and `GuillochePainter`, with the layout, copy and two error messages in the issue. Successful sign-in opens the user's first allowed screen.
- **Frame**: `NavDestination`, `NavItem`, `AppSidebar`, `TopBar` and `AppShell`. Search and the bell are visual only.
- **Routing**: `AppRoutes`, `onGenerateRoute`, `firstAllowedRoute` and the guards, using zero-duration page routes.
- **Stubs**: the seven screens, with the exact class names, constructors and titles in the issue.
- **App entry**: `MonedaSeguraApp` moves to `lib/app/app.dart`, `lib/main.dart` starts it with `AppStore.seeded()`, and `lib/login_screen.dart` is deleted.
- **Docs and tests**: the README "Demo accounts" section, `test/helpers/pump_app.dart` and the tests for all six criteria.

**Check first.** The issue needs `lib/theme/`, `buildAppTheme`, `AppButton`, `AppTextField`, `AppAvatar`, `lib/widgets/widgets.dart` and `setDesktopView`. Confirm in the worktree that they exist with the parameters the issue uses. If #10 or #13 isn't merged, stop and report it instead of rebuilding that work here. If only a color or style token is missing, add it to `lib/theme/`.

**Where the issue leaves a conflict or a gap, use these readings:**

- **`AppScope`**: the issue writes `AppScope(notifier: store, ...)`, but the constructor in the code is `AppScope(store: store, child: ...)`. Use the code.
- **`AppSidebar`**: it also takes the visible destinations, as the required prop-drilling section says, even though the earlier signature omits them. `AppShell` filters them using the user's permissions, and the sidebar shows only what it receives.
- **`LoginPage`**: it takes the `loading` flag from the same section. `signIn` is synchronous, so `LoginScreen` passes `false` for now.
- **Validation order**: check for empty fields first, then call `signIn`. Both messages appear through the password field's `errorText`. An email of only spaces counts as empty.
- **Redirects**: a redirected route carries the target's name in its `RouteSettings`, not the requested path, so `/simulator` really lands on `/dashboard`. Routes that aren't redirected use `settings: s` as the issue says.
- **Start route**: Flutter splits an `initialRoute` such as `/cases/abc` into a stack of `/`, `/cases` and `/cases/abc`, which would run the guards on each and leave extra pages behind. Starting on any route must produce exactly one page, whatever the guard decides. `/` counts as an unknown path.
- **Logging out**: `signOut()` notifies listeners before the navigation runs, so `AppShell` can rebuild with no user. It must then render nothing rather than fail on a null user.
- **No allowed screens**: `firstAllowedRoute` returns the login if the user has no allowed destination. No seed user hits this, because all six have `DASHBOARD_READ`.
- **Signed-in user on `/login`**: it shows the login, as the issue's route table says. No extra redirect.
- **Active item**: the case detail stub marks "Casos" active and the rule editor stub marks "Reglas" active.
- **Criterion 6**: its grep matches any mention, so files in `lib/widgets/` other than `app_shell.dart` must not name `AppScope` or `AppStore`, even in comments.

The reference code in the tag `archive/pr-29-flutter-prototype` can be reused where it fits, but this issue wins over it, and the code must build on the current data layer and `AppStore`.

Left out, as the issue says: the content of the seven screens, search and notification behavior, a real `POST /auth/login`, storing a token, and a mobile layout or bottom navigation bar.

## Why
This is the router and frame the delivery plan in `docs/deliveries/flutter-prototype.md` asks for, and every screen task depends on it. The code it builds on fits: `lib/data/app_store.dart` has `signIn`, `signOut`, `currentUser` and `AppStore.seeded({clock})`, `lib/data/labels.dart` has "Administradora", and `lib/data/mock/mock_seed.dart` has the users and password the criteria name. The permissions in the issue match `model.md` §4, so Camilo has no `SIMULATOR_RUN` and Laura Cárdenas has no `RULE_WRITE`.

I rated it medium because it touches many files and adds the permission guards every later screen relies on. It isn't high because the sign-in is simulated, in memory and covered by widget tests. The demo password in the README is a mock value already in the seed, not a real secret. My local checkout is behind `origin/develop`, and the factory only labels this issue once its dependencies are closed, so I expect #10 and #13 to be merged, but I couldn't read that code or confirm it directly.
