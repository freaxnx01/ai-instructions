# Project Scaffold Checklists

Init-time checklists. Use when bootstrapping a new project. Layered: each section assumes the previous one applies.

## Baseline (every project, regardless of stack)

- [ ] `README.md` with setup + run commands
- [ ] `CHANGELOG.md` with `[Unreleased]` section
- [ ] `cliff.toml` for `git-cliff`
- [ ] `.gitignore` appropriate to the stack
- [ ] `CLAUDE.md` and `.github/copilot-instructions.md` generated from base + chosen stack overlay
- [ ] `/health/live` and `/health/ready` endpoints wired (or stack equivalent)
- [ ] CI workflow (build + test + security scan)
- [ ] Branch protection on `main`

## .NET baseline (in addition to the above)

- [ ] `Directory.Build.props` with global compiler settings + `<Version>1.0.0</Version>`
- [ ] `Directory.Packages.props` with central package versions
- [ ] `.editorconfig` committed
- [ ] `global.json` pinning SDK version
- [ ] `cliff.toml` for `git-cliff` changelog generation
- [ ] `docker-compose.yml` + `docker-compose.override.yml`
- [ ] `Dockerfile` multi-stage, non-root user, Alpine
- [ ] `/health/live` and `/health/ready` endpoints wired
- [ ] Serilog + OpenTelemetry bootstrapped
- [ ] `RequestLocalizationMiddleware` configured for `de` / `en`
- [ ] GitHub Actions workflow for build + test + vulnerability scan

## .NET WebAPI (in addition to the above)

- [ ] `Asp.Versioning.Http` registered with URL-segment versioning, default v1.0, group name format produces `v{MAJOR}.{MINOR}` URLs
- [ ] Single authentication scheme chosen and documented in `README.md`
- [ ] `AddProblemDetails()` + global `IExceptionHandler` wired in `Program.cs`
- [ ] `AddRateLimiter()` with at least one named policy
- [ ] `AddHttpLogging()` with sensitive headers explicitly cleared from logging
- [ ] CORS configured with explicit origin allowlist per environment
- [ ] `AddResponseCompression()` enabled
- [ ] OpenAPI metadata (Title / Version / Description / Contact / License) populated
- [ ] Scalar UI at `/scalar` with curl + PowerShell code samples enabled
- [ ] Kiota generation script committed (or documented as N/A)
- [ ] `bruno/` collection seeded with at least one happy-path request per endpoint
- [ ] Integration test project using `WebApplicationFactory` + Testcontainers
- [ ] `perf/` directory with at least one k6 smoke scenario per critical endpoint, wired into CI
