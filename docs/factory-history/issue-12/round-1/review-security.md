VERDICT: PASS

## Summary
- This branch adds the in-memory `AppStore`, `DomainError` and `AppScope`, plus tests and an `AGENTS.md` note. It has no HTTP calls, persistence or new dependencies, and `AppScope` isn't wired into the app yet.
- Every mutation checks permissions: `takeCase` and `resolveCase` need `CASE_RESOLVE`, `retrainNow` needs `MODEL_TRAIN`, and signed out counts as forbidden. No role names are used.
- `resolveCase` also requires the case to be IN_REVIEW and assigned to the caller, so one analyst can't resolve another's case.
- The password is compared and never stored, logged or put in an error. `app_store.dart` has no logging, and the branch commits no secrets.
- No blocking findings. The notes cover read getters that aren't permission-gated, which matters once screens are built.

## Findings
None.

## Notes
- `lib/data/app_store.dart:99-137,187-217`: read getters (`openCases`, `caseById`, `customers`, `users`, `models`, `metrics`) return data while signed out and don't check `CASE_READ`, `MODEL_READ` or `DASHBOARD_READ`. The spec doesn't ask for these checks, and this is seeded mock data held in the client, so it doesn't block. `users` does expose staff emails to any caller of the store. Screens must gate on `can(...)`, and the real API must enforce these permissions when it replaces the store.
- `lib/data/app_store.dart:70`: `signIn` accepts one shared demo password for every user. The password (`MockSeed.demoPassword`, `lib/data/mock/mock_seed.dart:170`) was committed before this branch and ends up in the web build. This is fine for a prototype, but this store and password must not ship as a real authentication path. The login screen should show the same message for a wrong password and an unknown email; `signIn` already returns null for both.
- `lib/data/app_store.dart:271-282`: `addCaseRecord` and `updateMetrics` skip permission checks. `@protected` is only an analyzer hint, not a runtime limit. The next task's public operations must make the check (for example `SIMULATOR_RUN`) before calling them.
- `lib/data/domain_error.dart:12`: error messages hold only case ids and permission codes, with no personal data. Their text is English and for developers, so the UI shouldn't show it directly.
- `lib/app/app_scope.dart:13-14,20-21`: the asserts are stripped in release builds, where `scope!` throws a null-check error instead. This only affects the failure message, not security.
- Personal data: `Customer` holds only `maskedName` and `maskedDocument` among the name and document fields checked, and the store doesn't unmask anything.
- No rule approval, JWT, `Idempotency-Key`, `SCORING_SERVICE_TOKEN` or simulator code is in this change. Rule approval (`approved_by_id <> created_by_id`) and the `SIMULATOR_RUN` check belong to the next task and should be reviewed there.
- I reviewed by reading the code and did not run the tests or checks; `build.md` reports that `factory/checks.sh` passed.
