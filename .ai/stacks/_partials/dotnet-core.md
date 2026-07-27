[//]: # (Stack partial — shared .NET conventions. Composed with a layer file under .ai/stacks/_layers/ by `scripts/build-stacks.sh` to produce a flat .ai/stacks/dotnet-*.md. Do not edit the generated file directly.)

# .NET Core Conventions

Shared baseline for every .NET stack overlay. Composed with a layer file (`dotnet-blazor` or `dotnet-webapi`) into the published flat overlay.

---

## Tech Stack (.NET baseline)

.NET 10 / C# · ASP.NET Core Minimal API · EF Core (SQLite small / PostgreSQL non-small) · FluentValidation · Serilog · OpenTelemetry · OpenAPI + Scalar · Docker + docker-compose (Alpine) · xUnit + FluentAssertions + NSubstitute.

Full table: [`.ai/references/dotnet/tech-stack.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/tech-stack.md)

---

## Architecture — Modular Monolith

- One top-level folder per module (`src/Modules/<ModuleName>/`), each owning its Domain / Application / Infrastructure layers
- Modules communicate via in-process interfaces — **never** direct project references across modules
- Shared kernel in `src/Shared/` for cross-cutting types only
- Each module registers its own DI services via `IServiceCollection` extension methods
- Apply Hexagonal (Ports & Adapters) inside a module when it has multiple infrastructure adapters or needs strong testability isolation

Directory layouts: [`architecture-layout.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/architecture-layout.md)

---

## C# Conventions

Correctness rules — get these wrong and the build or production behaviour breaks:

- No `#nullable disable` and no warning suppressions to silence a build error; never suppress a nullable warning with `!` without a comment saying why it is safe
- `async`/`await` end-to-end — never `Task.Result` or `.GetAwaiter().GetResult()`
- `CancellationToken` on every async method that touches an external resource, and pass it down
- Catch specific exception types — not bare `catch (Exception)`
- `ILogger<T>` for logging — never `Console.WriteLine`

Style and project setup (file-scoped namespaces, `record` DTOs, `sealed` by default, primary constructors, Central Package Management, the mandatory `Directory.Build.props` pins): [`csharp-conventions.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/csharp-conventions.md)

---

## API Design — Minimal API baseline

Every ASP.NET Core project (whether it exposes a REST surface or just a few endpoints for a Blazor app) follows these baseline conventions. The `dotnet-webapi` layer adds the deeper REST conventions on top.

- All endpoints grouped by module via `IEndpointRouteBuilder` extension methods
- One handler per file when the body is non-trivial; inline lambdas only for true one-liners
- Input validation via FluentValidation, run at the boundary before any handler logic
- Error responses are always `ProblemDetails` (RFC 9457) — never raw strings, anonymous error objects, or HTML error pages
- OpenAPI via `Microsoft.AspNetCore.OpenApi`; Scalar UI mounted at `/scalar`

Scaffold: [`.ai/references/dotnet/endpoint-group.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/endpoint-group.md)

---

## Entity Framework Core

- One `DbContext` per module (not one global context)
- Migrations in `<Module>/Infrastructure/Persistence/Migrations/`
- `IEntityTypeConfiguration<T>` per entity — no data annotations on domain models
- Never use `EF.Functions` in domain/application layers — only in infrastructure queries
- Always use `AsNoTracking()` for read-only queries
- Seed data via `IEntityTypeConfiguration.HasData()` or a dedicated seeder run at startup

CLI scaffold: [`.ai/references/dotnet/ef-core-cli.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/ef-core-cli.md)

---

## Localization & Regional Formatting (server-side baseline)

Base rules for `de` / `en` support live in `base-instructions.md`. For every ASP.NET Core project on this stack:

- Configure `RequestLocalizationMiddleware` in `Program.cs` — supported cultures, cookie → `Accept-Language` → default resolution order, and the `de-CH` fallback are all in the scaffold below
- Format dates / numbers / currency via `CurrentCulture` — never `string.Format` with a hardcoded culture, and never `CultureInfo.InvariantCulture` for user-visible text

Middleware scaffold and culture list: [`request-localization.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/request-localization.md)

UI-specific localization (resource files for component strings, picker behaviour, language-switcher widgets) lives in the Blazor layer.

---

## Testing Strategy

Base testing rules (TDD, never modify a test to make it green, full suite after implementation) live in `base-instructions.md`. Baseline layout is `tests/<Module>.UnitTests/` (xUnit, no I/O) and `tests/<Module>.IntegrationTests/` (real I/O via Testcontainers); layer overlays add their own projects.

- One test class per production class; naming `MethodName_StateUnderTest_ExpectedBehavior`
- `FluentAssertions` for assertions, `NSubstitute` for mocks/stubs
- No `[Fact]` containing logic — use `[Theory]` + `[InlineData]` / `[MemberData]`
- Run the full suite (`dotnet test`) after implementation, not just the new test

Test class scaffold: [`xunit-example.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/xunit-example.md)

---

## Essential Commands

Routine work runs through `just` — `just build`, `just test`, `just lint`, `just vuln` (canonical recipe names in *Essential just Recipes* below). Underlying `dotnet` / `docker-compose` commands: [`essential-commands.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/essential-commands.md)

**PDB symbols:** Release builds embed PDB symbols (`<DebugType>embedded</DebugType>` in `Directory.Build.props`) so production stack traces carry source file + line numbers. Never strip them from release or Docker builds.

---

## Essential just Recipes

Projects ship a repo-root `justfile` ([casey/just](https://github.com/casey/just)) standardizing commands — **canonical recipe names, project-local bodies**. Groups: build/run, testing, Docker Compose, quality (`lint`, `outdated`, `vuln`), versioning (`version`, `bump-*`), release (`changelog`, `release`, `package`), `clean`. Document each with a leading `# <description>`; the default recipe runs `just --list --unsorted`.

Copy `.ai/examples/dotnet/justfile` and customize the top-of-file variables. Host-specific recipes ship as `[unix]` + `[windows]` pairs, so no WSL is needed; tool-specific ones ship as stubs with per-OS examples in comments.

Full recipe list, install (just ≥ 1.20) and CI setup: [`justfile-recipes.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/justfile-recipes.md)

---

## Docker

- Runtime base: `mcr.microsoft.com/dotnet/aspnet:10.0-alpine`
- Build base: `mcr.microsoft.com/dotnet/sdk:10.0-alpine`
- Multi-stage Dockerfile always
- Run as non-root user in final stage
- `docker-compose.yml` — production-like config
- `docker-compose.override.yml` — local dev overrides (ports, volumes, hot-reload)
- Secrets via environment variables or Docker secrets — **never in image or appsettings**

Dockerfile scaffold: [`.ai/references/dotnet/dockerfile.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/dockerfile.md)

---

## Logging & Observability

Serilog via `UseSerilog()` with `{ModuleName}` / `{CorrelationId}` on every entry; OpenTelemetry traces to OTLP; `/metrics` in Prometheus format; `/health/live` + `/health/ready`. Config detail: [`logging-observability.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/logging-observability.md)

**12-Factor enforcement points — violating these breaks production:**

- Never write to the container filesystem for application state
- Never put secrets in `appsettings.Development.json` — environment variables only
- EF Core migrations run as a separate init container or pre-deploy step — **never** auto-migrated on `app.Run()`
- Serilog sink in production is stdout or OTLP — never a file sink in Docker

---

## Security (stack baseline)

Base security rules live in `base-instructions.md`; this is how they are enforced on this stack:

- HTTPS + HSTS in **all** environments
- Response headers: `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`
- Secrets via `IConfiguration` bound to environment variables — never `appsettings.json`
- `dotnet list package --vulnerable --fail-on-severity high` in CI
- Boundary validation with FluentValidation, before any domain logic
- Error responses are `ProblemDetails` — never raw messages

---

## Versioning (stack binding)

Base rules (SemVer, Conventional Commits → bump mapping, git-cliff) live in `base-instructions.md`. For this stack:

- One global version for all assemblies — defined once in `Directory.Build.props` as `<Version>`, never in individual `.csproj` files
- Docker images tagged with the same version + `latest` on stable releases

---

## CI/CD (GitHub Actions baseline)

Pipeline stages: `build` → `test` → `security-scan` → `docker-build` → `push` (base CI rules apply): build/test on every PR, vuln scan fails on HIGH/CRITICAL, image pushed only on `main` after tests pass.

Layer-specific CI jobs (E2E with Playwright for Blazor, k6 perf smoke for WebAPI) are added by the layer overlay.

Workflow scaffold: [`.ai/references/dotnet/github-actions.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/github-actions.md)

---

## Project Scaffold Checklist (.NET baseline)

.NET-specific init-time checklist (inherits the base checklist) lives at [`.ai/references/scaffold-checklists.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/scaffold-checklists.md) under "**.NET baseline**". Layer additions are in the same file.

---

## Agent Guardrails (.NET baseline)

In addition to the base guardrails:

- Do not install additional NuGet packages without asking first
- Do not change project target frameworks
- Do not modify `.csproj` files unless the task requires it
- Do not introduce new patterns (e.g. MediatR, CQRS) unless explicitly asked

### Never generate (this stack)

- `async void` (except UI event handlers — see the Blazor layer)
- `Task.Result` or `.GetAwaiter().GetResult()` — always `await`
- Magic strings — use `const` or `nameof()`
- Direct `HttpClient` instantiation — always via `IHttpClientFactory`
- Cross-module project references (use shared interfaces)
