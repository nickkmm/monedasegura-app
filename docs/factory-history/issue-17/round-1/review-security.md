VERDICT: PASS

## Summary
- The branch adds a simulated login, the console shell, guarded routes and seven empty stub screens, all client-side against the in-memory `AppStore`.
- Route guards use `AppUser.can` only, never role names, and `/simulator` requires `SIMULATOR_RUN`; signed-out, forbidden, unknown and malformed paths all fall back safely.
- No HTTP calls, token storage, logging or new dependencies were added, and no `.env`, `DEPLOY_*` or `S3_*` values were committed.
- The README now publishes the demo password, which the spec asks for; it only unlocks mock data but must not outlive the simulated login.

## Findings
None.

## Notes
- **Client-side guards are UX only.** `lib/app/routes.dart` is a correct display guard, but the authority check belongs to the decision-service once the real API is connected. The screen tasks must not treat these guards as access control.
- **Demo password in docs and bundle.** `README.md:22` documents `MonedaSegura2026`, and `lib/data/mock/mock_seed.dart:170` (pre-existing) ships it in the web bundle. It is not a real credential today because it only opens synthetic in-memory data. Remove both, and the `signIn` mock, when `POST /auth/login` arrives.
- **Raw route ids.** `lib/app/routes.dart:66` deliberately passes ids undecoded and unvalidated from a URL the user can type, so `caseId` and `ruleId` are untrusted input. The stubs ignore them today. Later screen tasks must treat them as untrusted, for example by encoding them when building API paths and when showing them.
- **Password field.** `lib/screens/login/login_page.dart:79` relies on `obscureText`, and `lib/widgets/app_text_field.dart` (pre-existing) sets it correctly. The password stays in the controller after a failed attempt and is released when the screen is replaced. This is acceptable for the mock.
- **Login while signed in.** `/login` stays reachable with an active session, as the spec requires, and the session stays active until a new sign-in replaces it. A successful sign-in replaces the current user, and a failed one leaves that session intact, so returning to `/login` does not end the session. Revisit this with real auth.
- **Guard checks that held up on reading the code:**
  - `/rules/new` matches before `/rules/<id>`, so a user without `RULE_WRITE` cannot reach the new-rule editor through the id pattern.
  - `/rules/new/` and `//rules/new` count as unknown paths.
  - Absolute names such as `http://x/simulator` still go through the permission check on their path.
  - Logout clears the session and the navigation stack, and a later return to a guarded route is sent to the login because guards run each time a route is generated.
  - A user with no roles falls back to `/login`, so `user.roles.first` in `AppSidebar` is not reached for them.
