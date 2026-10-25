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
