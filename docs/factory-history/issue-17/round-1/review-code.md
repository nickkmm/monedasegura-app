VERDICT: PASS

## Summary
- Routes, guards, login, shell widgets, the seven stubs, tests and docs match the spec requirements.
- Guards use `AppUser.can` only and cover signed out, missing permission and unknown or malformed paths. The initial route gives a single page.
- Only `app_shell.dart` names `AppScope` or `AppStore` in `lib/widgets/`, and `AGENTS.md` records that exception.
- Logout is safe: `AppShell` renders nothing once the user is null, then the stack is cleared.
- Docs (`README.md` demo accounts, `AGENTS.md` status and Routing) are updated. `factory/checks.sh` passed per `round-1/checks.md`.

## Findings
None.

## Notes
- `_match` leaves route ids undecoded (for example `%20`). This is documented in build.md and tested, and it is acceptable for now.
- The hero in `LoginPage` has no vertical scroll, so a very short window can overflow. This is non-blocking.
- The new widgets use `Row(spacing:)` where the older widgets use `SizedBox` gaps. This is a style difference only.
