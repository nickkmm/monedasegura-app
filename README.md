# monedasegura-app

Risk-analyst console for MonedaSegura, with an admin simulator. User-facing text is in Spanish.

**Stack:** Flutter 3.47 · web + Android · **Owners:** Juan José, Santiago · **Status:** skeleton

Part of MonedaSegura (Universidad Icesi + Lovelytics). The shared specification — context, MVP plan, data model, architecture and API contracts — lives in [`monedasegura-infra`](https://github.com/nickkmm/monedasegura-infra), cloned next to this repo inside a `SecureMoney/` workspace folder. Contract: `../monedasegura-infra/docs/api/decision-api.yaml`.

## Run

```bash
flutter pub get
flutter analyze && flutter test
flutter run -d chrome
docker build -t monedasegura/app:dev .   # served by nginx on :80
```

The whole stack (Postgres, Redis, Kafka and the three services) runs from `../monedasegura-infra` with `docker compose --profile apps up -d --build`.

## Contributing

Branch from `develop` (`feature/…`, `fix/…`, `docs/…`) and open a PR against `develop`; `main` only receives `develop → main` from Nicolás. CI must pass. Everything is in English; only user-facing app text is in Spanish. Agent instructions: [`AGENTS.md`](AGENTS.md).
