# AGENTS.md — monedasegura-app

Instructions for any coding agent (Claude Code, Antigravity, others) working in this repo.

## What this repo is
The **Flutter app** of MonedaSegura (Flutter 3.47, web + Android): the console used by risk analysts — case queue, case detail and labeling, rules (with shadow, backtest and approval), models, dashboard — plus the **simulator** (admin only) that generates synthetic transactions. There is no customer-facing app.

Owners: Juan José, Santiago. Status: **skeleton** — a placeholder sign-in screen; the rest starts once the data model (ERD) and the prototype are approved.

## Read first (shared context)
The shared specification lives in the sibling repo `../monedasegura-infra/docs/`. Read it; never copy it here.

| File | Why |
|---|---|
| `CONTEXT.md`, `MVP_PLAN.md` | the challenge, the MVP scope and the screen list (§6) |
| `api/decision-api.yaml` | **the only API this app calls** (the decision-service) |
| `model.md` | the RBAC catalog (§4), rule lifecycle (§6) and cases (§7) the screens follow |
| `features.md` | the features the rule editor offers (also served by `GET /features`) |

If the code and those documents disagree, the documents win: change them first with a PR against `monedasegura-infra`, then the code.

**If `../monedasegura-infra` does not exist, stop and set up the workspace before doing anything else** — never guess a contract, a feature name or a table:

```bash
# from the folder that contains this repo
git clone https://github.com/nickkmm/monedasegura-infra.git
sh monedasegura-infra/scripts/bootstrap-workspace.sh
```

The repos are not linked through git; they only rely on being sibling folders inside one workspace folder (e.g. `SecureMoney/`).

## Language policy (this repo is the exception)
- **User-facing text is in Spanish**: labels, buttons, messages, errors shown to the user, screen titles.
- **Everything else is in English**: code, identifiers, file names, comments, logs, tests, docs, commit messages, PR titles and descriptions.
- The API returns English codes (`BLOCK`, `CONFIRMED_FRAUD`, `RULE_APPROVE`…); the app translates them for display. Never send Spanish values to the API.

## Rules for this repo
- Call only `decision-api.yaml`, exactly as specified; never call the scoring-service.
- Show or hide screens and actions from the **permissions** returned by `POST /auth/login` / `GET /me`, never from role names. The simulator requires `SIMULATOR_RUN`.
- Personal data arrives masked; never try to unmask or store it.
- The API base URL is read at runtime from `config.json` (`apiBaseUrl`), written by the container from `API_BASE_URL`; never hard-code it.
- Keep the JWT in memory or secure storage, never in logs.
- Components follow the component gallery of the Figma prototype; a new reusable component goes into a shared widgets folder, once.
- Do not modify the other repos from here.

## Commands
```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run -d chrome                  # local web
flutter build web --release
flutter build apk --release            # Android
docker build -t monedasegura/app:dev .  # web build served by nginx on :80
```

## Branches and commits
- Never push to `develop` or `main`. Create `feature/<task>`, `fix/<task>` or `docs/<task>` and open a PR against `develop`.
- `develop → main` is opened and merged only by Nicolás.
- CI (`.github/workflows/ci.yml`) must pass before merging.
- One topic per PR; commit messages in English, imperative mood.

## Skills
Repo-specific skills go in `.agents/skills/<name>/SKILL.md` (`.claude/skills` is a symlink to it), so they stay versioned with the code.

<!-- factory:start (managed by monedasegura-infra factory/bin/install; edit it there) -->
## Software factory

`/factory run` builds every open GitHub issue labeled `factory` **and assigned to you** through intake → spec → build → gate → review → approve, one PR per issue. A person always reviews and merges the PR: the factory never merges. State is in `factory/jobs/` (gitignored, local to your machine); `factory/bin/job` is its only writer. Checks: `factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then open http://localhost:8000/dashboard.html.

| Command | What it does |
|---|---|
| `/factory run` | release the issues whose dependencies are merged, then build your queue (3 at a time) |
| `/factory run <n>` | build issue `<n>` now (it must be assigned to you) |
| `/factory divide <#n, file or text>` | split a large request into PR-sized issues, each with an owner; shows the plan before creating anything |
| `/factory <anything>` | ask about jobs, give feedback on a PR waiting for you, or file a new feature |

- **Who builds what.** Every factory issue is assigned to one person, and each person's factory only takes their own issues, so two people never build the same issue. Never take an issue assigned to someone else.
- **Order.** A task that needs another one says `Depends on #n` and stays unlabeled; `/factory run` labels it once `#n` is closed by a merged PR.
- **Record.** Each PR carries the job's record (intake, spec, build, reviews, checks, decision) in `docs/factory-history/issue-<n>/`. Only the factory writes there.
- **Branches.** The factory pushes `factory/<job-id>` branches and opens PRs against `develop`; this is the only exception to the branch-name rule above.
- **Worktrees.** Each job works in its own git worktree, a full checkout of the repo at `.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't read `.gitignore` sees those copies too; exclude `.worktrees/` in its config. **Sibling repos are relative to the main checkout, not to the worktree**: from a worktree, the shared docs are at `<main checkout>/../monedasegura-infra/docs/`.
- **Antigravity.** Use the App or the CLI (custom subagents aren't in the IDE yet), from the repo root: `agy --model <id>`, with an id from `agy models` (Gemini 4 Argon if your plan has it, otherwise Gemini 3.8 Flash), then the same `/factory` commands. The agents in `.agents/agents/` are generated from `.claude/agents/` by `factory/bin/sync-agents`; edit the `.claude/agents/` file and run it, never edit `.agents/agents/` by hand.
- **License.** The factory comes from ZazenCodes' software factory v2 (GPLv3, see `factory/LICENSE`).

### This repo (monedasegura-app)

- **Team.** Juan José (`@Jujoroco06`) and Santiago (`@Gomaxd11`) build this repo; the planner assigns each task to one of them. Nicolás (`@nickkmm`) runs `/factory divide` and reviews.
- **Design.** The Figma prototype and component gallery: https://www.figma.com/design/UQgvVVY2Sd9lRZY6cVPISY. Issues created by `/factory divide` already carry the values a builder needs (colors, sizes, copy, states, node ids), so building one never requires Figma access.
- **How to check a page here.** There is no browser tool for agents, and Flutter web draws on a canvas. Builders and reviewers check UI work with widget tests (`flutter test`) and by reading the code against the values in the issue; a person walks through the app with `flutter run -d chrome`. Every new screen, page and shared widget gets widget tests for its acceptance criteria.
- **Structure.** Each reusable component is one widget in a shared widgets folder, built once and reused. The state lives in the host Screen; Pages only show data and capture interaction, reporting up through callbacks, and never keep app data of their own. Mock data are in-memory models and lists consistent with `../monedasegura-infra/docs/model.md`; creating, editing or deleting updates what the screen shows.
- **Data layer.** `lib/data/models/` holds the domain models, `lib/data/labels.dart` the Spanish labels, `lib/data/format.dart` the formatters and `lib/data/mock/mock_seed.dart` the mock data; screens reuse them rather than re-translating or re-formatting.
- **Current delivery.** `docs/deliveries/flutter-prototype.md`.
<!-- factory:end -->
