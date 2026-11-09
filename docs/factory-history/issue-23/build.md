STATUS: READY

# Build: Simulator screen with live results

## Summary
- `/simulator` is now a working screen: pick a scenario, customer and count, and watch decisions arrive every 400 ms.
- `SimulatorScreen` owns all the run state and the timer; `SimulatorPage` only shows data and reports interaction through callbacks.
- A run ends on finish, on Stop, on leaving the screen, or when the session ends, and a sign-out mid-run never throws.
- The feed keeps its fixed columns and scrolls horizontally inside the card at the shell's 1280 px layout.
- No change to `lib/data/`, `lib/app/` or `lib/widgets/`.

## Changes
- `lib/screens/simulator/simulator_screen.dart`: replaces the stub with a stateful host. It validates the count, starts the run, runs the `Timer.periodic`, guards each tick with `store.can(SIMULATOR_RUN)`, and cancels the timer on stop and dispose.
- `lib/screens/simulator/simulator_page.dart` (new): `RunState` and the stateless `SimulatorPage`, with private section widgets for the configuration card, the customer field and menu, the results card and header, the progress bar, and the feed header and rows. It computes the verdict counters and the nearest-rank p95 from the events it receives.
- `test/screens/simulator_test.dart` (new): 23 tests covering the 15 acceptance criteria.

## Acceptance criteria
All evidence is from `flutter test test/screens/simulator_test.dart` (23 passed), and again in the full `flutter test` run inside `factory/checks.sh`.

1. [x] Idle: test "shows the idle screen" finds every listed text once, including "Sofía V. · documento ••••3310", "—" and "Todavía no hay transacciones".
2. [x] Running: test "shows progress during a run" after 14 ticks finds "En vivo · ejecución #18", "14 / 20 enviadas", 14 `VerdictBadge`s, counters summing to 14 and "Detener simulación".
3. [x] Finished: test "a finished run opens a case per flagged decision" finds "Ejecución #18 · terminada", "20 / 20 enviadas" and "Iniciar simulación"; `metrics.decisions` grew by 20, every flagged event's `caseId` is in `openCases`, and `openCaseCount` grew by the flagged count.
4. [x] Stopped: test "stopping keeps the results and sends nothing more" finds "Ejecución #18 · detenida" and "5 / 20 enviadas"; after 5 more ticks there are still 5 rows and `metrics.decisions` is unchanged.
5. [x] Validation: tests "rejects the count ..." for "0", "51", "" and "abc" show the error, keep `nextRunNumber` at 18 and keep "Sin ejecutar". An extra test checks that an invalid count after a run keeps the previous results.
6. [x] Originación: test "Originación creates one customer per run" shows "Se crea un cliente nuevo" with `AppTextField.enabled` false, and a run adds exactly one customer.
7. [x] Guard: test "the guard keeps out a user without SIMULATOR_RUN": for Camilo, the `TopBar` title is not "Simulador".
8. [x] Page isolation: `grep -rn "AppScope\|AppStore" lib/screens/ | grep -v _screen.dart` prints nothing (the test "only screens reach the store" checks the same). Test "reports the start and stop taps" pumps `SimulatorPage` alone in `harness` inside a `SingleChildScrollView` and records `onStart` and `onStop`.
9. [x] Disabled while running: test "the controls lock during a run": tapping "Normal" keeps ATO selected, and both fields have `enabled` false.
10. [x] Customer menu: test "choosing a customer from the menu drives the run": choosing "Mariana G. · documento ••••1907" updates the field, and the run's rows read "Mariana G.".
11. [x] p95: tests "uses the nearest rank" (latencies 1 to 20 give "19 ms") and "reads one event directly" (168 gives "168 ms").
12. [x] Frozen total and second run: test "a later run keeps its own total": after changing the count to "5" it still reads "20 / 20 enviadas"; restarting shows "En vivo · ejecución #19", no rows, then "1 / 5 enviadas".
13. [x] Timer lifecycle: tests "leaving the screen ends the run" (`metrics.decisions` unchanged after more pumps on Modelos) and "signing out during a run does not throw" (`takeException` is null, no further decisions).
14. [x] No overflow: test "a full run does not overflow at the 1280 px layout": with Inter loaded at 1280 x 900, a 20-event ATO run raises no exception and the last row's `VerdictBadge` is built.
15. [x] Feed row styling: test "feed rows color the type and keep the given order": `textSecondary` for APPROVE, `statusBlock` for BLOCK, rows in the given order.

Rendering check: a temporary test (not committed) wrote PNGs of the app with Inter loaded. Idle and the open customer menu at 1280 px, and a finished run at 1280 and 1600 px, matched the spec's layout. At 1600 px the whole feed shows. At 1280 px the latency and badge columns are past the card's edge until the feed is scrolled sideways, which requirement 21 accepts. Icons render as placeholder squares and shadows as solid black in test renders, so a person should still confirm those with `flutter run -d chrome`.

## Validation
- `bash <main checkout>/factory/checks.sh` from the worktree: passed (exit 0).
  - `flutter pub get`: passed.
  - `dart format --output=none --set-exit-if-changed lib test`: passed, 0 files changed.
  - `flutter analyze`: passed, no issues.
  - `flutter test`: passed, 370 tests.
  - `flutter build web --release`: passed.
- `flutter test test/screens/simulator_test.dart`: passed, 23 tests. The last edit after this run only simplified the no-overflow test, and that version passed in the full run above.
- No dev server or browser was used, because `AGENTS.md` says UI work here is checked with widget tests.

## Log
### Round 1
Built the screen, page and tests from the spec. Decisions the spec left to the builder:
- Vertical gaps inside the cards that neither the spec nor the issue gives use the `AppSpacing` scale.
- The feed's minimum width is 600 px, the value in requirement 21. Neither feed row has a gap on either side of the spacer, so the row needs slightly less than the 12 px per child the spec describes; the fixed columns and all other gaps match.
- `_customerId` is set in `initState` through `AppScope.read`, and is non-nullable in the Screen. The Page still accepts a nullable `customerId`, as the spec lists it.
- When a tick finds no `SIMULATOR_RUN`, the timer is cancelled and `state` stays `running`, because requirement 6 asks only for those two things and the screen is about to be replaced.
