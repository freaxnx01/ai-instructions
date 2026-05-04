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
