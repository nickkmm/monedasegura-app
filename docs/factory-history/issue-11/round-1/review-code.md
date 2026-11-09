VERDICT: PASS

## Summary
- Adds the pure Dart data layer under `lib/data/` (enums, models, labels, formatters, `MockSeed`) plus four test files in `test/data/`, in four small commits.
- Spot-checked `format.dart`, `app_user.dart`, the AGENTS.md bullet, and the pubspec, analysis_options and Flutter-import constraints. They match the spec.
- The formatters follow requirements 21 to 25: ratio-based percent, elapsed-time `formatAgo`, calendar-date `formatDayAgo` computed in UTC, and no time zone conversion.
- No password field in `AppUser`, no `DateTime.now()` or `Random` in the seed, and no Flutter imports. `pubspec.yaml` and `analysis_options.yaml` are unchanged.
- Checks passed on this commit. I did not audit every seed value in the 1065-line `mock_seed.dart` line by line.

## Findings
None.

## Notes
- The two open product decisions in the spec still need a human: `NIGHT_TRANSFER` v2 `createdAt` (3 d ago) against the "hoy" that #16 and #21 expect, and the `#09F35B` exception to `model.md` §5.
