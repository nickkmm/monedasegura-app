VERDICT: PASS

## Summary
- The branch adds a pure Dart data layer: enums, models, labels, formatters, an in-memory mock seed and tests.
- It adds no network calls, storage, logging, HTML rendering or new dependencies, and nothing in the running app imports it yet.
- `rolePermissions` matches `model.md` §4 exactly, including `SIMULATOR_RUN` for `ADMIN` only.
- Seed personal data is masked and fictional, and every seeded ACTIVE or RETIRED rule version has an approver other than its creator.
- The only credential-like value is the `demoPassword` the issue asks for. It matches nothing in the sibling repos I searched, so it is a note rather than a blocker.

## Findings
None.

## Notes
1. `lib/data/mock/mock_seed.dart:170` `demoPassword` is a plaintext constant in `lib/`. Once #12 uses it, it will ship in the web bundle, where anyone can read it. That is acceptable only while sign-in is mock-only. It must be removed when the app moves to `POST /auth/login`, and must not be reused as a real seeded password. A search of `monedasegura-infra`, `monedasegura-decision-service` and `monedasegura-scoring-service` found no copy of it.
2. `lib/data/models/app_user.dart:25` `AppUser.permissions` is derived on the client from roles through `rolePermissions`. The issue asks for this and it is fine for the prototype. `AGENTS.md` requires permissions to come from `POST /auth/login` / `GET /me`, so the API-backed version should use the returned permissions instead. Client-side checks only show or hide UI; the service still has to enforce them.
3. `#12` (the store) and `#15` own the sign-in check and the rule approval flow, so neither is exercised here. The two-step rule (`approved_by_id <> created_by_id`) appears in this branch only as seed data and a test, so those jobs should review its enforcement.
4. `Transaction.counterparty` has no masking test on non-TRANSFER rows. The only such seeded value is the merchant `ElectroHogar Bogotá`, which is not personal data, and TRANSFER rows are asserted to match `^\*{4}\d{4}$`.
