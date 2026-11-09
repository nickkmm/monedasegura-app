ESCALATE

## Summary
- The simulator screen is built as the issue asks. All 15 acceptance criteria are met, the gate passed and all three reviews passed.
- I recommend not merging yet, because two project checks need a person.
- The screen differs from the simulator contract: it offers a count for every scenario and shows decisions one at a time, while the API returns a whole run at once.
- A new `SIMULATOR_RUN` check runs on every timer tick. The route guard itself didn't change.
- At the 1280 px layout, the decision column stays out of view until the user scrolls the feed sideways.

## Why
The work is complete, stays inside intake's Scope, and adds no dependency, migration, environment variable or deploy change. However, this project asks for a person's check when a change differs from a contract in `monedasegura-infra/docs/` or touches permissions or the simulator's access rule, and both apply here. The contract difference comes from the issue itself, and it has no effect while the app runs on mock data, so it needs a decision rather than a code fix in this PR.

## Acceptance criteria
I ran `flutter test test/screens/simulator_test.dart` on commit `ab13003` (23 passed) and read each test. The gate's full run also passed (370 tests), and PR CI passed on the same commit.

1. Idle: met. The test "shows the idle screen" finds every listed text.
2. Running: met. After 14 ticks the test finds the header, "14 / 20 enviadas", 14 badges, counters summing to 14 and the stop button.
3. Finished: met. Decisions grow by 20, every flagged event's case is in `openCases`, and `openCaseCount` grows by the flagged count.
4. Stopped: met. It shows "Ejecución #18 · detenida" and "5 / 20 enviadas", with 5 rows and unchanged decisions after more ticks.
5. Validation: met. "0", "51", "" and "abc" each show the error, and the run number and "Sin ejecutar" stay as they were.
6. Originación: met. The field is disabled with the expected text, and a run adds exactly one customer.
7. Guard: met. Camilo's `TopBar` title is not "Simulador".
8. Page isolation: met. I ran the grep myself and it matches only `*_screen.dart` files. The page test records `onStart` and `onStop` with no `AppScope`.
9. Disabled while running: met. Tapping "Normal" keeps ATO selected, and both fields have `enabled` false.
10. Customer menu: met. Choosing Mariana G. updates the field, and the run's rows show her name.
11. p95: met. Latencies 1 to 20 give "19 ms", which also matches the formula when worked by hand, and one event of 168 gives "168 ms".
12. Frozen total and second run: met. The test sees "20 / 20 enviadas" after the edit, then "En vivo · ejecución #19", no rows and "1 / 5 enviadas".
13. Timer lifecycle: met. Decisions stop after leaving for Modelos, and a mid-run `signOut()` raises no exception.
14. No overflow: met. A 20-event ATO run at 1280 x 900 with Inter loaded raises no exception, and the last badge is built.
15. Feed row styling: met. The type label colors and the row order match the spec.

## For the human
Recommendation: don't merge yet

The code is ready and I found no defect in it. The merge should wait for these three checks.

**1. Decide how to handle the contract difference.** Either accept it for the mock prototype, or update the contract first with a PR against `monedasegura-infra`. `AGENTS.md` says the documents win when code and documents disagree.
- **Count:** `SimulationRequest.count` in `api/decision-api.yaml` is described as "Number of transactions (NORMAL and CARD_FRAUD)". The screen also offers it for ATO, its default scenario with a count of 20, and for Originación.
- **Live feed:** `POST /simulator/runs` returns all of a run's `results` in one response. The screen's feed, one decision every 400 ms and stoppable midway, has no matching call in that endpoint.
- **Run number:** the "ejecución #18" number has no field in `SimulationResult`.
- **Conflicting docs:** `docs/data.md` §3 says the simulator calls `POST /transactions` per event, while `decision-api.yaml` describes `/simulator/runs`. The real integration will have to settle which one applies.

**2. Confirm the permission check is acceptable.** `_onTick` in `simulator_screen.dart` cancels the timer when `store.can(PermissionCode.SIMULATOR_RUN)` is false. It exists so a sign-out during a run doesn't throw. `lib/app/routes.dart` and the store's permission checks are unchanged. After the timer is cancelled, `state` stays `running`, on the assumption that the screen is replaced right after sign-out. The code review saw this as harmless.

**3. Walk through the screen with `flutter run -d chrome`.**
- **Feed at 1280 px:** the spec accepts sideways scrolling here, but the verdict is the main result of each row. Check that it reads well and that the scrollbar is visible on web.
- **Items the code-reading reviews couldn't confirm:** the "Decisión" header's alignment over the badges, the 24 px gap above the button, and whether the "Cliente" field needs a sign that it opens a menu.
- **Icons and shadows:** the builder's test renders showed these incorrectly, so they haven't been checked visually.

Files to look at:
- `lib/screens/simulator/simulator_screen.dart`
- `lib/screens/simulator/simulator_page.dart`
- `test/screens/simulator_test.dart`
- `../monedasegura-infra/docs/api/decision-api.yaml` (`/simulator/runs`, `SimulationRequest`, `SimulationResult`)
- `../monedasegura-infra/docs/data.md` (§3)
