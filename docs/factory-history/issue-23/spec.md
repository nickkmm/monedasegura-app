# Simulator screen with live results

> Issue #23: Build the simulator screen with live results

## Summary
- Spec for replacing the `SimulatorScreen` stub with a working screen and adding `SimulatorPage`, using the issue's values and its eight acceptance criteria.
- No data-layer change: `AppStore` already has `startRun`, `createOriginationCustomer` and `simulateOne`, and the route guard already exists.
- The spec settles what the issue leaves open: the run total is fixed at start, `DATASET_FRAUD` stays out of the grid, and p95 uses nearest rank.
- It also adds two guards the issue doesn't mention: no crash if the session ends during a run, and no feed overflow at the shell's 1280 px layout width.

## Context
- **Stub to replace:** `lib/screens/simulator/simulator_screen.dart`, a `StatelessWidget` with an empty `AppShell`. `lib/app/routes.dart` builds `const SimulatorScreen()` behind `PermissionCode.SIMULATOR_RUN`, so the constructor must stay `const`.
- **Pattern to follow:** `lib/screens/models/models_screen.dart` and `models_page.dart`, with `test/screens/models_test.dart` for the tests. The Screen reads the store and wraps a Page that takes data and callbacks.
- **Store (`lib/data/app_store.dart`):**
  - `startRun()` returns the run number. The seed's `simulationRunCount` is 17, so the first run is #18.
  - `createOriginationCustomer()` returns a `Customer` named like "Cliente nuevo 18.".
  - `simulateOne({required scenario, required customerId, required runNumber, required index})` takes **named** parameters, not the positional form in the issue. `index` is 0-based (`test/data/app_store_rules_test.dart`).
  - All three throw `DomainError` when the current user lacks `SIMULATOR_RUN`, including after sign-out.
  - Also used here: `customers`, `customerById`, `openCases`, `openCaseCount`, `metrics` (`metrics.decisions` grows per event) and `can`.
- **Models:** `SimulationEvent` (`lib/data/models/simulation_event.dart`) holds `transaction`, `decision` and `customer`. The feed reads `transaction.occurredAt`, `transaction.type`, `transaction.amount`, `decision.verdict`, `decision.latencyMs`, `decision.caseId` and `customer.maskedName`. `Customer.maskedDocument` looks like `****3310`.
- **Labels and formatters:** `lib/data/labels.dart` has `Scenario.label`, `.hint` and `.description`, which already match the issue's copy, and `TransactionType.label`. `lib/data/format.dart` has `formatHms` and `formatCop`.
- **`Scenario.values` is not the grid:** it includes `DATASET_FRAUD` and is in a different order from the issue's grid.
- **Shared widgets (`lib/widgets/widgets.dart`):** `AppShell`, `AppCard`, `OptionCard`, `AppTextField` (`readOnly`, `enabled`, `onTap`, `errorText`, `controller`), `AppButton` (`variant`, `expand`), `StatTile`, `EmptyState`, `VerdictBadge`. `AppIcons.play` exists.
- **Menu pattern:** `_VerdictFilter` in `lib/screens/cases/case_queue_page.dart` uses `MenuAnchor` with `MenuItemButton`.
- **Why some gallery widgets don't fit:**
  - `TableHeaderRow` is a filled `bgSubtle` band with a fixed 16 px gap, but the feed header has no band and a 12 px gap.
  - `FeatureBar` and `ScoreBar` have labels and other colors, but the progress bar is a bare 4 px track.
- **Layout constraint:** `AppShell` puts its child in a vertical `SingleChildScrollView`, so the page gets unbounded height and a bare `Expanded` in a column throws. Below 1280 px wide, the shell lays out at 1280 and scrolls horizontally.
- **Leaving the screen:** the sidebar uses `pushReplacementNamed`, so leaving disposes the screen. Sign-out calls `store.signOut()` before navigating, so the screen stays mounted briefly with no user.
- **Tests:** `pumpApp` and `kTestNow` are in `test/helpers/pump_app.dart`; `harness` and `loadInterFont` are in `test/helpers/harness.dart`. Valentina's demo account has `SIMULATOR_RUN` and Camilo's does not (`test/data/app_store_test.dart`, `test/screens/models_test.dart`).
- **Reference only:** `git show archive/pr-29-flutter-prototype:lib/screens/simulator_page.dart`. This issue's values win, and nothing may depend on that tag's `models.dart`, `mock_data.dart` or `prototype_labels.dart`.

## Requirements

### Host (`lib/screens/simulator/simulator_screen.dart`)
1. `SimulatorScreen` becomes a `StatefulWidget` with a `const SimulatorScreen({super.key})` constructor, rendered in `AppShell(active: NavDestination.simulator, title: 'Simulador', subtitle: 'Crea transacciones de prueba para ver cómo responde el sistema', child: SimulatorPage(...))`.
2. It owns:
   - `Scenario scenario`, default `Scenario.ATO`;
   - `String? customerId`, default the customer whose `maskedName` is "Sofía V.";
   - a count `TextEditingController`, default "20", disposed in `dispose`;
   - `int? runNumber`;
   - the count error text;
   - the total of the current run;
   - `List<SimulationEvent> events`, newest first;
   - `RunState state`;
   - a `Timer`.
3. `enum RunState { idle, running, finished, stopped }` lives in `simulator_page.dart`, so the Page does not import the Screen.
4. Start does the following, in order:
   - Parse `int.tryParse(text.trim())`. If the result is null or outside 1 to 50, set the error "Escribe un número entre 1 y 50." and change nothing else: no `startRun`, and any previous results stay on screen.
   - Otherwise clear the error, clear `events`, store the parsed total and set `state = running`.
   - Set `runNumber = store.startRun()`. For `ORIGINATION`, set `customerId = store.createOriginationCustomer().id`.
   - Start `Timer.periodic(400 ms)`. The first event arrives at 400 ms, not immediately.
5. Each tick calls `store.simulateOne(scenario:, customerId:, runNumber:, index:)` with a 0-based `index` and prepends the event. When `events.length` reaches the run total, it cancels the timer and sets `state = finished`.
6. Before calling the store, a tick checks `store.can(PermissionCode.SIMULATOR_RUN)`. If that is false, it cancels the timer and makes no call, so a sign-out during a run never throws.
7. Stop cancels the timer and sets `state = stopped`. `dispose` cancels the timer. Decisions already made stay in the store.
8. The Screen is the only simulator file that touches `AppScope` or `AppStore`.

### Page (`lib/screens/simulator/simulator_page.dart`)
9. `SimulatorPage` is a `StatelessWidget` that takes through its constructor:
   - `scenario`, `customerId`, `customers`, `countController`, `countError`;
   - `runNumber`, `runTotal`, `events`, `state`;
   - `onScenario`, `onCustomer`, `onStart`, `onStop`.

   It must not import `app_store.dart` or `app_scope.dart`. It lays out a top-aligned `Row` with a 16 px gap, and it works under unbounded height.
10. Private section widgets are allowed in this file, with constructor parameters in and callbacks out. A private stateful customer field may own the display `TextEditingController` and update it in `didUpdateWidget`, because `AppTextField` shows text only through a controller.

### Configuration card (`AppCard`, width 420, gap 16)
11. Heading "Escenario", then a 2 x 2 grid of `OptionCard`s with gap 8, using `Scenario.label` and `.hint`, in this explicit order: `NORMAL`, `CARD_FRAUD`, `ATO`, `ORIGINATION`. `DATASET_FRAUD` is not shown. The selected card uses the dark style (`danger` false). `onTap` is null while running.
12. Below the grid, `scenario.description` in `caption`, `textSecondary`.
13. `AppTextField(label: 'Cliente', readOnly: true)`:
    - It shows "{maskedName} · documento ••••{last 4 of maskedDocument}".
    - Tapping it opens a `MenuAnchor` with one `MenuItemButton` per customer in the same format, and choosing one calls `onCustomer(id)`.
    - For `ORIGINATION` it is disabled and reads "Se crea un cliente nuevo".
    - It is disabled while running.
14. `AppTextField(label: 'Cantidad (máximo 50)', hintText: '20 transacciones', keyboardType: TextInputType.number, errorText: countError)`, disabled while running.
15. Full-width `AppButton`: primary "Iniciar simulación" calling `onStart` when not running; secondary "Detener simulación" calling `onStop` while running.

### Live results card (`AppCard`, expanded, minimum height 795, gap 16)
16. Header row:

    | State | Left | Right |
    |---|---|---|
    | idle | "Resultados en vivo" | "Sin ejecutar" |
    | running | 8 px dot `statusBlock` + gap 8 + "En vivo · ejecución #{n}" | "{sent} / {total} enviadas" |
    | finished | "Ejecución #{n} · terminada" | "{sent} / {total} enviadas" |
    | stopped | "Ejecución #{n} · detenida" | "{sent} / {total} enviadas" |

    Left text is `heading`; right text is `caption`, `textSecondary`. `sent` is `events.length` and `total` is the total stored at start, not the live text of the count field.
17. Progress bar: height 4, radius `AppRadius.full`, track `bgSubtle`, fill `bgInverse`, fraction sent / total, 0 when idle.
18. Four `StatTile`s in a row, equal width, gap 12:
    - "Aprobadas" (`statusApprove`), "En revisión" (`statusReview`) and "Bloqueadas" (`statusBlock`) count this run's events by verdict.
    - "Latencia p95" (`textPrimary`) is the nearest-rank 95th percentile of this run's `latencyMs`: sort ascending and take index `(n * 95 + 99) ~/ 100 - 1`. It reads "168 ms", or "—" with no events.
19. `state == idle`: `EmptyState(icon: AppIcons.play, title: 'Todavía no hay transacciones', hint: 'Elige un escenario y presiona Iniciar simulación.')` centered in the remaining space. A fixed-height idle card (795) with `Expanded` satisfies this under unbounded height; `LayoutBuilder` must not sit under `IntrinsicHeight`.
20. Any other state shows the feed:
    - Header row with gap 12, `label` style, `textTertiary`: "Hora" 64, "Cliente" 130, "Tipo" 84, "Monto" 104, flexible space, "Decisión".
    - One row per event, newest first, in a plain `Column`: gap 12, vertical padding 9, bottom border 1 `borderDefault`.
    - Row cells, in order:
      - `formatHms(occurredAt)`, `caption`, `textTertiary`, width 64;
      - `maskedName`, `bodyStrong`, width 130;
      - `type.label`, `caption`, `statusBlock` for REVIEW or BLOCK, else `textSecondary`, width 84;
      - `formatCop(amount)`, `body`, width 104;
      - spacer;
      - "{latency} ms", `caption`, `textTertiary`;
      - `VerdictBadge(verdict: ...)`.
    - Fixed-width cell text uses `maxLines: 1` with an ellipsis.
21. The feed must not overflow at the shell's 1280 px layout width. Keep the issue's column widths. When the card is narrower than the feed needs (about 600 px), the feed scrolls horizontally inside the card.

### Rules
22. Colors, spacing, radii and text styles come only from `lib/theme/`; no hex color or font size elsewhere. Reuse `lib/data/labels.dart` and `lib/data/format.dart` rather than re-translating or re-formatting. The feed header, feed row, live dot and progress bar stay private to this page, so `lib/widgets/` does not change.
23. Add `test/screens/simulator_test.dart` covering the acceptance criteria below. Tests advance the timer with `tester.pump(const Duration(milliseconds: 400))`, never `pumpAndSettle` while running.

## Acceptance criteria
All are tests in `test/screens/simulator_test.dart`, run with `flutter test test/screens/simulator_test.dart`. Unless stated otherwise they use `pumpApp(tester, signInAs: <Valentina's email>, initialRoute: '/simulator')`.

1. **Idle.** The screen shows "Simulador", the subtitle, "Escenario", the four scenario titles and hints, the ATO description, "Cliente", "Sofía V. · documento ••••3310", "Cantidad (máximo 50)", "Iniciar simulación", "Resultados en vivo", "Sin ejecutar", "Aprobadas", "En revisión", "Bloqueadas", "Latencia p95", "—" and "Todavía no hay transacciones".
2. **Running.** With count "20", after "Iniciar simulación" and 14 steps of 400 ms: "En vivo · ejecución #18", "14 / 20 enviadas", 14 `VerdictBadge`s in the feed, the three counters sum to 14, and the button reads "Detener simulación".
3. **Finished.** After 6 more steps:
   - "Ejecución #18 · terminada", "20 / 20 enviadas" and "Iniciar simulación" are shown;
   - `store.metrics.decisions` grew by 20;
   - every REVIEW or BLOCK event's `decision.caseId` is in `store.openCases`, reading the events from the `SimulatorPage` widget;
   - `store.openCaseCount` grew by the number of those events.
4. **Stopped.** "Detener simulación" after 5 steps shows "Ejecución #18 · detenida" and "5 / 20 enviadas". After more pumps, the feed still has 5 rows and `store.metrics.decisions` has not changed.
5. **Validation.** Each of "0", "51", "" and "abc" shows "Escribe un número entre 1 y 50.", `store.nextRunNumber` stays 18, and "Sin ejecutar" remains.
6. **Originación.** Selecting "Originación" shows "Se crea un cliente nuevo" in a disabled field (`AppTextField.enabled` is false), and a run adds exactly one customer to `store.customers`.
7. **Guard.** Signed in as Camilo Torres, `/simulator` does not show the title "Simulador", read from the `TopBar` as `test/app/navigation_test.dart` does.
8. **Page isolation.**
   - `grep -rn "AppScope\|AppStore" lib/screens/` matches only `*_screen.dart` files.
   - A widget test pumps `SimulatorPage` alone in `harness` inside a `SingleChildScrollView`, with no `AppScope`, plain fake data and recording callbacks, and asserts that tapping "Iniciar simulación" calls `onStart`.
   - The same test asserts that tapping "Detener simulación" with `state: RunState.running` calls `onStop`.
9. **Disabled while running.** During a run, tapping another scenario card does not change the selection, and both the customer and count `AppTextField`s have `enabled` false.
10. **Customer menu.** Tapping the customer field and then "Mariana G. · documento ••••1907" makes the field show that text, and a run produces feed rows with "Mariana G.".
11. **p95.** A page test with 20 fake events having latencies 1 to 20 shows "19 ms". With one event of latency 168 it shows "168 ms".
12. **Frozen total and second run.**
    - After a finished run with count "20", changing the field to "5" still shows "20 / 20 enviadas".
    - Starting again then shows "En vivo · ejecución #19", an empty feed before the first step and "1 / 5 enviadas" after one step.
13. **Timer lifecycle.**
    - Tapping "Modelos" in the sidebar during a run stops new events: `store.metrics.decisions` does not change after more pumps.
    - Calling `store.signOut()` during a run and pumping 400 ms raises no exception (`tester.takeException()` is null).
14. **No overflow.** With `loadInterFont` loaded and the view set to 1280 x 900, a full 20-event ATO run raises no exception, and the last feed row's `VerdictBadge` is built.
15. **Feed row styling.** In a page test with one APPROVE and one BLOCK event, the type label's text color is `AppColors.textSecondary` and `AppColors.statusBlock` respectively, and the rows appear in the order given (newest first).

## Out of scope
- Session-event details in the feed, custom transaction input (`POST /transactions`), saving runs, charts.
- Calling the real API; the app stays on mock data.
- Any change to `lib/data/`, `lib/app/routes.dart` or the route guard, including adding `DATASET_FRAUD` to the grid.
- New shared widgets or new parameters on existing ones, for example changing `TableHeaderRow` to fit the feed.
- Using code from the `archive/pr-29-flutter-prototype` data layer.
- Keeping a run alive after leaving the screen, or resuming it on return.

## Assumptions
- **Default customer lookup:** Sofía V. is found by `maskedName` in `store.customers`, with no UI for an empty customer list, because the app always uses the seeded store.
- **Run total fixed at start:** the header and progress bar use the total stored at start, because the field is editable again once a run ends and the "{sent} / {count}" copy would otherwise change after the run.
- **Empty or non-numeric count:** shows the same error as out of range (intake's decision).
- **Error lifetime:** the count error stays until the next valid Start, because the issue's callback list has no count-changed callback.
- **Invalid Start after a run:** keeps the previous results and state, because the issue says only that it does not start.
- **Leaving during a run:** ends the run, and decisions already made stay in the store (intake's decision).
- **Originación customer:** after a run, the new customer stays selected and appears in the menu when the user switches scenario (intake's decision). Each Originación run creates another customer.
- **Run with no events yet:** a run that is running or stopped with 0 events shows the feed header with no rows, because the issue limits the empty state to idle.
- **p95 method:** nearest rank, with integer arithmetic to avoid floating-point rounding, because the issue doesn't name a method and this is the one used by the PR 29 reference.
- **Right-hand header text:** running, finished and stopped use the same `caption`, `textSecondary` style as "Sin ejecutar", because the issue gives a style only for idle.
- **Feed horizontal scroll (requirement 21):** this is not in the issue. Its fixed columns need about 585 px, but the card has about 490 px at the 1280 layout width, so the verdict badge would be clipped.
- **Sign-out guard (requirement 6):** this is not in the issue. A tick in the moment between `signOut()` and the route change would otherwise throw an uncaught `DomainError`.
- **Docs:** `AGENTS.md` and the delivery doc need no change, because neither describes individual screens' state and no new convention is introduced.
