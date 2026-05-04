[//]: # (GENERATED FILE — do not edit directly. Source: .ai/stacks/_partials/dotnet-core.md + .ai/stacks/_layers/dotnet-webapi.md. Run scripts/build-stacks.sh to regenerate.)

[//]: # (Stack partial — shared .NET conventions. Composed with a layer file under .ai/stacks/_layers/ by `scripts/build-stacks.sh` to produce a flat .ai/stacks/dotnet-*.md. Do not edit the generated file directly.)

# .NET Core Conventions

Shared baseline for every .NET stack overlay. Composed with a layer file (`dotnet-blazor` or `dotnet-webapi`) into the published flat overlay.

---

## Tech Stack (.NET baseline)

.NET 10 / C# · ASP.NET Core Minimal API · EF Core (SQLite small / PostgreSQL non-small) · FluentValidation · Serilog · OpenTelemetry · OpenAPI + Scalar · Docker + docker-compose (Alpine) · xUnit + FluentAssertions + NSubstitute.

Full table: [`.ai/references/dotnet/tech-stack.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/tech-stack.md)

---

## Architecture — Modular Monolith

- Separate top-level folders per module: `src/Modules/<ModuleName>/`
- Each module owns its Domain / Application / Infrastructure layers
- Modules communicate via in-process interfaces — never direct project references across modules
- Shared kernel in `src/Shared/` for cross-cutting types only
- Modules register their own DI services via `IServiceCollection` extension methods
- Apply Hexagonal (Ports & Adapters) inside a module when it has multiple infrastructure adapters (e.g. REST + messaging) or needs strong testability isolation

Directory layouts (modular-monolith and hexagonal): [`.ai/references/dotnet/architecture-layout.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/architecture-layout.md)

---

## C# Conventions

`Directory.Build.props` at repo root pins (mandatory): `TargetFramework=net10.0`, `Nullable=enable`, `ImplicitUsings=enable`, `TreatWarningsAsErrors=true`, `EnforceCodeStyleInBuild=true`, `AnalysisLevel=latest-recommended`, `DebugType=embedded`, `DebugSymbols=true`. Full file: [`.ai/references/dotnet/directory-build-props.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/directory-build-props.md)

- File-scoped namespaces always
- `global using` for framework namespaces in each project
- `record` types for DTOs and value objects
- `sealed` by default on non-base classes
- No `var` when the type is not obvious from the right-hand side
- Prefer primary constructors (.NET 8+)
- Central Package Management via `Directory.Packages.props` — no versions in `.csproj`
- Use `ILogger<T>` for logging — never `Console.WriteLine`
- Use specific exception types — not generic `catch (Exception)`
- Use `CancellationToken` in all async methods that call external resources
- Use `async`/`await` end-to-end — never `Task.Result` or `.GetAwaiter().GetResult()`
- No `#nullable disable` or warning suppressions to fix build errors
- Never suppress nullable warnings with `!` without a clear comment

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

Base rules for `de` / `en` support and regional formatting live in `base-instructions.md`. For every ASP.NET Core project on this stack:

- Configure `RequestLocalizationMiddleware` in `Program.cs` with supported cultures `de-CH, de-DE, de-AT, en-US, en-GB` and default `de-CH` / `de`
- Culture resolution order: cookie (`.AspNetCore.Culture`) → `Accept-Language` header → default (`de-CH` / `de`)
- For language `de` with no recognized region (or a `de-*` region not in `SupportedCultures`), fall back to `de-CH` — never `de-DE`
- Format dates / numbers / currency via `CurrentCulture` — never `string.Format` with a hardcoded culture or `CultureInfo.InvariantCulture` for user-visible text

Middleware scaffold: [`.ai/references/dotnet/request-localization.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/request-localization.md)

UI-specific localization rules (resource files for component strings, picker behaviour, language-switcher widgets) live in the Blazor layer.

---

## Testing Strategy

The base testing rules (TDD, no test modification to make green, full suite after implementation) live in `base-instructions.md`.

### Test project layout (baseline)

```
tests/
  <Module>.UnitTests/         ← xUnit, no I/O
  <Module>.IntegrationTests/  ← xUnit, real I/O via Testcontainers
```

Layer-specific test projects (Blazor component tests, Playwright E2E, API integration tests with `WebApplicationFactory`) are added by the layer overlay.

### Unit tests (xUnit)

- One test class per production class
- Naming: `MethodName_StateUnderTest_ExpectedBehavior`
- Use `FluentAssertions` for assertions
- Use `NSubstitute` for mocks/stubs
- No `[Fact]` with logic — use `[Theory]` + `[InlineData]` / `[MemberData]`
- After implementation, run the full test suite (`dotnet test`) — not just the new test

Test class scaffold: [`.ai/references/dotnet/xunit-example.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/xunit-example.md)

---

## Essential Commands

```bash
# Restore / build (warnings as errors) / run
dotnet restore
dotnet build -c Release
dotnet run --project src/Host

# Run full stack locally
docker-compose -f docker-compose.yml -f docker-compose.override.yml up --build

# Tests
dotnet test                                         # all
dotnet test tests/<Module>.UnitTests                # unit only
dotnet test tests/<Module>.IntegrationTests         # integration (needs Docker)
dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage

# Security / package checks
dotnet list package --vulnerable --fail-on-severity high
dotnet list package --outdated
```

**PDB symbols:** Release builds include embedded PDB symbols (`<DebugType>embedded</DebugType>` in `Directory.Build.props`) so exception stack traces contain source file names and line numbers in production. Never strip PDB symbols from release or Docker builds.

---

## Essential Make Targets

Projects using this stack ship a repo-root `Makefile` standardizing the common commands. Target names are canonical; recipe bodies may use project-local variables.

Canonical targets exist for: build/run (`build`, `watch`, `run-edge`), testing (`test`, `test-unit`, `test-coverage`), Docker Compose (`docker-run`, `up`, `down`, `logs`, `rebuild`), quality (`lint`, `outdated`, `vuln`), versioning (`version`, `version-set`, `bump-major|minor|patch`, `bump-auto`), release (`changelog`, `release-notes`, `release`, `release-auto`, `push-release`, `package`), and `clean`. Document each target with an inline `## <description>` comment and expose a `help` target that greps them.

A reference Makefile lives at `.ai/examples/dotnet/Makefile` — copy it and customize the top-of-file variables. Host/tool/project-specific targets (`run-edge`, `release-notes`, `package`) ship as stubs with per-OS examples in comments.

Full target list with descriptions: [`.ai/references/dotnet/makefile-targets.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/makefile-targets.md)

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

- Serilog configured in `Program.cs` via `UseSerilog()`
- Structured properties on every log entry: `{ModuleName}`, `{CorrelationId}`
- Use `LoggerMessage.Define` source-generated logging for hot paths
- Log levels: `Debug` local, `Information` production minimum
- OpenTelemetry: export traces to OTLP collector; expose `/metrics` (Prometheus format)
- Health checks: `/health/live` (liveness) and `/health/ready` (readiness, checks DB)

**12-Factor enforcement points for this stack:**
- Never write to the local filesystem inside a container for application state
- Never use `appsettings.Development.json` for secrets — always env vars
- EF Core migrations must be applied as a separate init container or pre-deploy step — **never** auto-migrated on `app.Run()`
- Serilog sink in production: stdout or OTLP — never file sink in Docker

---

## Security (stack baseline)

Base security rules live in `base-instructions.md`. For every project on this stack:

- HTTPS enforced in all environments; HSTS enabled
- Security response headers: `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`
- No secrets in `appsettings.json` — use `IConfiguration` with environment variable binding
- Run `dotnet list package --vulnerable --fail-on-severity high` in CI — fail build on HIGH/CRITICAL
- Validate all inputs at the API boundary with FluentValidation before any domain logic
- Error responses use `ProblemDetails` (no raw messages)

---

## Versioning (stack binding)

Base rules (SemVer, Conventional Commits → bump mapping, git-cliff) live in `base-instructions.md`. For this stack:

- One global version for all assemblies — defined once in `Directory.Build.props` as `<Version>`, never in individual `.csproj` files
- Docker images tagged with the same version + `latest` on stable releases

---

## CI/CD (GitHub Actions baseline)

Pipeline stages: `build` → `test` → `security-scan` → `docker-build` → `push`. Build and test run on every PR; vulnerable-dependency scan fails the build on HIGH/CRITICAL; container image built and pushed only on `main` after tests pass.

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
- Secrets, connection strings, or credentials in source files
- Cross-module project references (use shared interfaces)
- Tests that are modified to pass (fix the implementation instead)
- Hardcoded return values, mock results, or stub logic to satisfy a test
- Silently swallowed exceptions to make a test green
- `#nullable disable` or warning suppressions to fix build errors
- Commented-out code blocks — delete them, git has history
- `Console.WriteLine` — use `ILogger<T>`
- Generic `catch (Exception)` — use specific exception types
- Missing `CancellationToken` on async methods that call external resources
- `using` statements for namespaces already covered by `global using`

---

[//]: # (Stack layer — composed with .ai/stacks/_partials/dotnet-core.md by `make build-stacks` to produce .ai/stacks/dotnet-webapi.md. Do not edit the generated file directly.)

# .NET WebAPI Layer

Backend-only ASP.NET Core REST API projects (no Blazor, no UI). Composed on top of the shared `dotnet-core` partial.

---

## Tech Stack (WebAPI additions)

REST · ASP.NET Core Minimal API · `Asp.Versioning.Http` (URL-segment) · auth: pass-through / API-key / JWT (single scheme per project) · `ProblemDetails` (RFC 9457) · OpenAPI + Scalar at `/scalar` · Bruno · `WebApplicationFactory` + Testcontainers · k6 · Kiota.

Full table: [`.ai/references/dotnet/tech-stack.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/tech-stack.md)

---

## API Design — Minimal API

- All endpoints grouped by module via `IEndpointRouteBuilder` extension methods
- Route prefix: `/api/v{version}/{module}/...` — see *API versioning* below for the URL format
- One handler per file when the body is non-trivial; inline lambdas only for true one-liners
- FluentValidation runs at the boundary, before any handler logic

Endpoint group scaffold: [`.ai/references/dotnet/endpoint-group.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/endpoint-group.md) (use the versioned route variant)

### HTTP status code conventions

| Code | Use |
|---|---|
| `200 OK` | Successful read or non-creating action |
| `201 Created` | Resource created — **must include `Location` header pointing at the new resource** |
| `202 Accepted` | Async work accepted — include `Location` to status resource (see LRO) |
| `204 No Content` | Successful PUT / PATCH / DELETE with no body |
| `400 Bad Request` | Malformed request (parse failure, missing required field) |
| `401 Unauthorized` | Missing or invalid credentials |
| `403 Forbidden` | Authenticated but not allowed |
| `404 Not Found` | Resource does not exist |
| `409 Conflict` | Request conflicts with current resource state |
| `412 Precondition Failed` | `If-Match` ETag mismatch |
| `422 Unprocessable Entity` | Semantic validation failure (parsed OK, content invalid) |
| `429 Too Many Requests` | Rate limit hit — include `Retry-After` |

### HTTP GET with request body — forbidden for new endpoints

Per RFC 7231 / 9110, GET request bodies have no defined semantics. Servers, proxies, and caches frequently strip, ignore, or reject them, which causes silent breakage and cache poisoning.

- **New endpoints:** use query parameters. If the parameter set is too large or sensitive for a URL, use `POST /search` (or another action sub-resource).
- **Legacy endpoints:** allowed only when required for backward compatibility. Mark the endpoint with `[Obsolete]` (or `.WithMetadata(new ObsoleteAttribute())`) and emit a `Sunset` header carrying the planned removal date.

### Errors — always ProblemDetails

- Every error response — including those produced by middleware and model binding — is RFC 9457 `ProblemDetails`
- Never return raw strings, anonymous `{ error: "..." }` objects, or HTML error pages
- Populate `type`, `title`, `status`, `detail`, `instance` on every response; add a `traceId` extension keyed on the current `Activity.TraceId`

Registration scaffold: [`.ai/references/dotnet-webapi/problem-details.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/problem-details.md)

---

## API Versioning

Use `Asp.Versioning.Http` with **URL-segment** versioning. Format: `v1.0`, `v2.0`, `v2.1` — `MAJOR.MINOR`. The minor segment is part of the URL even when only the major bumps, so the URL shape stays consistent across the lifetime of the API.

- **Unversioned URLs (`/api/orders/...`) are allowed only for backward compatibility.** They resolve to v1.0 explicitly — never to "latest". Rolling out v2.0 must not change what an unversioned caller hits.
- Deprecate an endpoint with `.HasDeprecatedApiVersion(1.0)` plus a `Sunset: <RFC 7231 date>` header on responses.
- Removal is a separate step from deprecation — no version is removed without an announced sunset window.

Registration scaffold: [`.ai/references/dotnet-webapi/api-versioning.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/api-versioning.md)

---

## Authentication

**One scheme per API project.** Do not mix schemes in the same service. The choice is made at project bootstrap and applies to every endpoint. Three approved schemes:

- **Pass-through** (BFF / wrapper APIs): forward incoming `Authorization` to upstream verbatim; do not validate, re-issue, decode, log, or transform; do not call `AddAuthentication()` here. If the project exposes non-proxied endpoints, it isn't pass-through.
- **API key** (`X-API-Key`): header name exact, no query-string fallback; custom `AuthenticationHandler<ApiKeySchemeOptions>`; keys in secret store; constant-time compare via `CryptographicOperations.FixedTimeEquals`; accept a small rotating set, not a single value.
- **JWT bearer**: `AddJwtBearer(...)`; validate issuer, audience, lifetime, signing key — never disable in any environment; authorize via named policies, not raw roles. This API **consumes** tokens; issuance belongs in a dedicated identity service.

Cross-cutting:

- `[Authorize]` / `.RequireAuthorization()` is the default for API key + JWT projects; opt out per-endpoint with `[AllowAnonymous]`. Pass-through projects register no scheme.
- Anonymous endpoints are limited to `/health/*`, `/scalar`, and the OpenAPI document.
- Never log the `Authorization`, `Cookie`, or `X-API-Key` header.

Full per-scheme rules: [`.ai/references/dotnet-webapi/authentication-schemes.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/authentication-schemes.md)

---

## Pagination

**Default to cursor-based** for new endpoints — offset pagination is unstable under concurrent inserts. Request: `GET /api/v1.0/orders?pageSize=50&pageToken=<opaque>`. Response: `{ "items": [...], "nextPageToken": "<opaque>" }` (null when exhausted).

- `pageToken` is opaque to the client — base64 of an internal cursor (`{lastId, lastCreatedAt}`), never a row offset
- Maximum `pageSize` is bounded server-side; reject requests exceeding it with `400`
- Offset pagination (`?page=&pageSize=`) is allowed only for **small bounded admin lists** where stability under inserts is guaranteed (e.g. a fixed config table)

---

## Idempotency for unsafe methods

Accept an `Idempotency-Key` header on `POST` and `PATCH` (and `DELETE` if it triggers side-effects beyond removing a row).

- Cache the response keyed by `(route, key, principal)` for 24 h
- A retry with the same key returns the cached response — no duplicate side-effect, no second `201`
- A retry with the same key but a *different* request body is rejected with `409 Conflict`
- Keys are client-supplied opaque strings; the API does not generate them

---

## Optimistic concurrency

For mutable resources, surface the row version as an `ETag` and require `If-Match` on writes.

- `GET /resources/{id}` returns `ETag: "<rowversion>"`
- `PUT|PATCH|DELETE /resources/{id}` accepts `If-Match: "<rowversion>"` — when present, mismatch returns `412 Precondition Failed`; when absent, the write proceeds without a concurrency check (lenient default — clients opt in to concurrency control by sending the header)
- Wire to EF Core: `[Timestamp] public byte[] RowVersion { get; set; }`
- The handler maps `DbUpdateConcurrencyException` to `412`

---

## Rate limiting

- Named policies per endpoint group — never a single global limit
- Always emit `Retry-After` on `429`
- Partition by authenticated principal first; fall back to remote IP only for anonymous endpoints

Registration scaffold: [`.ai/references/dotnet-webapi/rate-limiting.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/rate-limiting.md)

---

## CORS

- Explicit origin allowlist per environment via `WithOrigins(...)`
- **Never** combine `AllowAnyOrigin()` with `AllowCredentials()` — the combination is rejected by browsers and indicates a misconfiguration
- Methods and headers are scoped to what the API actually accepts — no blanket `AllowAnyMethod()`
- Preflight cache via `SetPreflightMaxAge(TimeSpan.FromHours(1))`

---

## HTTP logging

**Never log** `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, or any header that may carry credentials. Calling `RequestHeaders.Clear()` before adding a curated allowlist is **mandatory** — the framework defaults include sensitive headers.

Registration scaffold: [`.ai/references/dotnet-webapi/http-logging.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/http-logging.md)

---

## Long-running operations

For work that takes longer than a request can reasonably hold open: kickoff `POST` returns `202 Accepted` + `Location: /api/v1.0/operations/{opId}`; status `GET` on that operation returns `200 OK` with `running | succeeded | failed` while in progress, and `303 See Other` + `Location: <result-resource>` on completion. Operations are retained ≥ 24 h after completion so polling clients can observe the terminal state.

---

## Response compression

- Brotli first, gzip fallback
- Exclude already-compressed media types (`image/*`, `application/zip`, `application/x-protobuf`, etc.) — wasted CPU otherwise

Registration scaffold: [`.ai/references/dotnet-webapi/response-compression.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/response-compression.md)

---

## OpenAPI & Scalar

- API metadata (Title / Version / Description / Contact / License) is mandatory — published APIs without metadata are rejected in review
- Scalar UI at `/scalar`; OpenAPI document at `/openapi/v1.0.json`
- Code samples enabled for **bash curl** and **PowerShell** at minimum; other clients are opt-in
- Deprecated endpoints carry the OpenAPI `deprecated: true` flag *and* return a `Sunset` response header

Registration scaffold: [`.ai/references/dotnet-webapi/openapi-scalar.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/openapi-scalar.md)

---

## Client SDK generation

**Kiota** is the default for first-party `.NET` and `TypeScript` consumers:

```bash
kiota generate -l CSharp -d https://api.example.com/openapi/v1.0.json -o ./clients/dotnet -n Acme.Orders.Client
```

- Other languages consume the OpenAPI document directly
- Do **not** introduce NSwag, Refit, AutoREST, or hand-rolled `HttpClient` wrappers without an explicit ask — the OpenAPI document is the contract

---

## Testing (WebAPI additions)

The unit-test conventions and the baseline `<Module>.UnitTests` / `<Module>.IntegrationTests` layout live in the `dotnet-core` partial. For WebAPI projects, the integration test project uses `WebApplicationFactory` + Testcontainers, and one optional contract project may be added:

```
tests/
  Api.ContractTests/          ← optional — pinned OpenAPI snapshot
```

No bUnit, no Playwright — those are Blazor-stack concerns.

### Integration tests — WebApplicationFactory + Testcontainers

- `WebApiFactory : WebApplicationFactory<Program>` swaps real infrastructure for Testcontainers (Postgres, Redis, etc.)
- Each test class owns its database via Testcontainers — no shared mutable state across classes
- Authentication in tests: register a test scheme that injects a known principal — never call the real identity provider

Test class scaffold: [`.ai/references/dotnet-webapi/integration-test.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/integration-test.md)

### Manual / exploratory testing — Bruno

Collections in `bruno/`, committed to Git. One folder per module, mirroring API routes.

- One folder per module; request files named for the action (`create-order.bru`, `get-order-by-id.bru`)
- Base URLs and tokens via Bruno environments — never hardcoded in `.bru` files
- When an endpoint is added or changed, the corresponding Bruno request is added or updated in the same PR
- Include realistic example bodies and useful assertions (status code, response shape)

Directory layout scaffold: [`.ai/references/dotnet-webapi/bruno-layout.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/bruno-layout.md)

### Performance / load testing — k6

Scripts in `perf/`, committed to Git. One scenario per critical user journey or hot endpoint.

- Scenario naming: `<endpoint-or-journey>.<profile>.js` where `<profile>` ∈ `smoke | load | stress | soak`
- Every script declares `thresholds` for `http_req_duration` and `http_req_failed`; a failed threshold fails the run and the CI job
- Target environment via `K6_BASE_URL` env var — never hardcode hosts
- Authentication via shared helpers in `perf/lib/` — never embed real tokens in scripts
- CI: smoke profile runs on every PR (fast, blocking); load / stress / soak run on demand or on schedule (long, non-blocking gate)
- Output: write JSON results to a CI artifact via `--out json=results.json`; optional push to InfluxDB / Grafana for trending
- When an endpoint's expected throughput or latency budget changes, update the corresponding scenario and its thresholds in the same PR

Layout + sample script + profile definitions: [`.ai/references/dotnet-webapi/k6-scenarios.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/k6-scenarios.md)

---

## Project Scaffold Checklist (WebAPI additions)

WebAPI-specific init-time checklist (inherits the base + .NET checklists) lives at [`.ai/references/scaffold-checklists.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/scaffold-checklists.md) under "**.NET WebAPI**".

---

## Agent Guardrails (WebAPI additions)

In addition to the base and `dotnet-core` guardrails:

- Do not enable a second authentication scheme in an API project that already has one — the choice is project-wide
- Do not accept a GET request with a body on a new endpoint — use query params or `POST /search`
- Do not return raw error strings, anonymous error objects, or HTML error pages — always `ProblemDetails`
- Do not combine `AllowAnyOrigin()` with `AllowCredentials()` in CORS configuration
- Do not log the `Authorization`, `Cookie`, `Set-Cookie`, or `X-API-Key` headers
- Do not omit the minor segment in URL paths (use `v1.0`, not `v1`)
- Do not let an unversioned URL resolve to "latest" — pin it to v1.0 explicitly
- Do not introduce NSwag, Refit, or AutoREST — Kiota is the default client generator
- Do not create POST or PATCH endpoints without considering whether `Idempotency-Key` should be supported
- Do not skip `Location` headers on `201 Created` or `202 Accepted` responses
- Do not disable JWT validation (issuer, audience, lifetime, signing key) in any environment, including local
- Do not introduce token issuance into a consumer API — token issuance belongs in a dedicated identity service
