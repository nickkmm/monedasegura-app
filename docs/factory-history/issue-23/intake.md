DECISION: ACCEPT
RISK: medium
SURFACES: ui
RESCOPED: no

## Summary
- Accepted as written: the simulator screen with live results, built as one pull request.
- The store operations, the route guard and the shared widgets it needs already exist from the merged tasks.
- No contract, data model or feature catalog change is needed, because the screen runs on the in-memory store.
- Risk is medium because of the timer and because each run changes the cases and dashboard counters other screens show.

## Scope
Replace the `SimulatorScreen` stub with the working screen and add `SimulatorPage`, following the values, copy and eight acceptance criteria in this issue.

Behaviour to build:
- **Configuration:** choose a scenario (default "Toma de cuenta"), a customer (default Sofía V.) and a count (default 20). All three are disabled while a run is in progress.
- **Originación:** the customer field is disabled and reads "Se crea un cliente nuevo". Starting a run creates one new customer.
- **Validation:** a count outside 1 to 50 shows "Escribe un número entre 1 y 50." under the field and does not start a run.
- **Run:** one transaction is decided every 400 ms, newest first, until the count is reached or the user presses "Detener simulación".
- **Live results:** the header and "{sent} / {count} enviadas", the progress bar, the Aprobadas, En revisión and Bloqueadas counters, Latencia p95 and the feed all come from this run's events. Idle shows the empty state.
- **Effects elsewhere:** every REVIEW or BLOCK event opens a case that appears in the queue, and the dashboard counters grow.
- **Access:** users without `SIMULATOR_RUN` are redirected by the existing route guard, which this task does not change.

How I read three details the issue leaves open:
- A count that is empty or not a number shows the same validation error as one out of range.
- Leaving the screen during a run cancels the timer, so the run ends there. Decisions already made stay in the store.
- After an Originación run, the new customer stays selected and is listed in the customer menu if the user switches scenario.

Left out, as the issue says: session-event details in the feed, custom transaction input (`POST /transactions`), saving runs, and charts. Calling the real API is also left out, as the app still runs on mock data.

## Why
The simulator is an MVP screen (`docs/MVP_PLAN.md` §6) and the issue specifies it fully. The code is ready for it: `AppStore` has `startRun`, `createOriginationCustomer` and `simulateOne`, the seed's run count of 17 gives the expected run #18, and `lib/app/routes.dart` already guards the route with `SIMULATOR_RUN`. One note for the spec: `simulateOne` takes named parameters, not the positional form the issue shows.

I read this code in the worktree of the rules list job, because this job's worktree did not exist yet. Its history shows the store operations came from the merged #15.
