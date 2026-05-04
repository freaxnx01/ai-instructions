# 12-Factor App — full table

Projects follow the [12-Factor App](https://www.12factor.net/) methodology. Each factor stated neutrally; stack-specific enforcement details (which logging library, how migrations are wired) live in the stack overlay.

| Factor | Rule |
|---|---|
| **I. Codebase** | One repo per service/app, tracked in Git |
| **II. Dependencies** | All declared in the project's manifest/lockfile; nothing assumed from the environment |
| **III. Config** | All environment-specific config via environment variables — nothing per-environment baked into config files |
| **IV. Backing services** | DB, cache, message broker treated as attached resources via connection-string env vars |
| **V. Build, release, run** | Multi-stage container build: build image ≠ run image. Never build inside a running container |
| **VI. Processes** | Stateless processes — no sticky sessions, no local file state |
| **VII. Port binding** | App is self-contained; exports HTTP on a configurable port |
| **VIII. Concurrency** | Scale via multiple container replicas, not threads |
| **IX. Disposability** | Fast startup, graceful shutdown on SIGTERM |
| **X. Dev/prod parity** | Local override files mirror prod config as closely as possible |
| **XI. Logs** | Treat logs as event streams — write to stdout, never to files in a container |
| **XII. Admin processes** | Migrations and seed scripts run as one-off commands, not baked into app startup |
