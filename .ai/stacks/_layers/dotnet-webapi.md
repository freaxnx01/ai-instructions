[//]: # (Stack layer — composed with .ai/stacks/_partials/dotnet-core.md by `make build-stacks` to produce .ai/stacks/dotnet-webapi.md. Do not edit the generated file directly.)

# .NET WebAPI Layer

Backend-only ASP.NET Core REST API projects (no Blazor/UI), composed on the shared `dotnet-core` partial.

---

## Tech Stack (WebAPI additions)

REST · ASP.NET Core Minimal API · `Asp.Versioning.Http` (URL-segment) · auth: pass-through / API-key / JWT (single scheme per project) · `ProblemDetails` (RFC 9457) · OpenAPI + Scalar at `/scalar` · Bruno · `WebApplicationFactory` + Testcontainers · k6 · Kiota.

Full table: [`.ai/references/dotnet/tech-stack.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/tech-stack.md)

---

## API Design — Minimal API

- Endpoints grouped by module via `IEndpointRouteBuilder` extension methods
- Route prefix `/api/v{version}/{module}/...` — URL format under *API versioning* below
- One handler per file when the body is non-trivial; inline lambdas only for true one-liners
- FluentValidation runs at the boundary, before any handler logic

Endpoint group scaffold: [`.ai/references/dotnet/endpoint-group.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/endpoint-group.md) (use the versioned route variant)

### HTTP status code conventions

Non-obvious rules: `201 Created` and `202 Accepted` must include a `Location` header (to the new resource / status resource respectively); use `422` (not `400`) for semantic validation failures (body parsed OK, content invalid); `429` must include `Retry-After`.

### HTTP GET with request body — forbidden for new endpoints

GET bodies have undefined semantics (RFC 9110) — proxies and caches may drop them. New endpoints: use query params, or `POST /search` for large/sensitive filter sets. Legacy: allowed for backwards-compat only; mark `[Obsolete]` and emit a `Sunset` header.

### Errors — always ProblemDetails

- Every error response — including from middleware and model binding — is RFC 9457 `ProblemDetails`
- Never return raw strings, anonymous `{ error: "..." }` objects, or HTML error pages
- Populate `type`, `title`, `status`, `detail`, `instance`; add a `traceId` extension from the current `Activity.TraceId`

Registration scaffold: [`.ai/references/dotnet-webapi/problem-details.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/problem-details.md)

---

## API Versioning

`Asp.Versioning.Http` with **URL-segment** versioning. Format `v1.0`, `v2.0`, `v2.1` (`MAJOR.MINOR`). The minor segment stays in the URL even when only the major bumps, keeping the URL shape stable across the API's lifetime.

- **Unversioned URLs (`/api/orders/...`) are allowed only for backward compatibility** — they resolve to v1.0 explicitly, never "latest". Rolling out v2.0 must not change what an unversioned caller hits.
- Deprecate with `.HasDeprecatedApiVersion(1.0)` plus a `Sunset: <RFC 7231 date>` response header.
- Removal is separate from deprecation — no version is removed without an announced sunset window.

Registration scaffold: [`.ai/references/dotnet-webapi/api-versioning.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/api-versioning.md)

---

## Authentication

**One scheme per API project**, chosen at bootstrap and applied to every endpoint — never mixed. Three approved schemes (full rules in the reference doc):

- **Pass-through** (BFF / wrapper APIs): forward `Authorization` upstream verbatim; do not validate, decode, log, or call `AddAuthentication()`. Any non-proxied endpoint disqualifies the project from pass-through.
- **API key** (`X-API-Key` header, no query-string fallback): custom handler, keys in secret store, constant-time compare (`CryptographicOperations.FixedTimeEquals`), accept a small rotating set.
- **JWT bearer**: validate issuer/audience/lifetime/signing key in every environment (no exceptions, including local); authorize via named policies, not raw roles. This API **consumes** tokens — issuance belongs in a dedicated identity service.

Cross-cutting:

- `[Authorize]` / `.RequireAuthorization()` is the default for API key + JWT projects; opt out per-endpoint with `[AllowAnonymous]`. Pass-through projects register no scheme.
- Anonymous endpoints are limited to `/health/*`, `/scalar`, and the OpenAPI document.

Full per-scheme rules: [`.ai/references/dotnet-webapi/authentication-schemes.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/authentication-schemes.md)

---

## Pagination

**Default to cursor-based** for new endpoints (offset is unstable under concurrent inserts): `GET .../orders?pageSize=50&pageToken=<opaque>` → `{ "items": [...], "nextPageToken": "<opaque>" }` (null when exhausted).

- `pageToken` is opaque base64 of an internal cursor (`{lastId, lastCreatedAt}`), never a row offset
- `pageSize` bounded server-side; over-limit requests return `400`
- Offset pagination only for small bounded admin lists where insert-stability is guaranteed

---

## Idempotency for unsafe methods

Accept `Idempotency-Key` on `POST`/`PATCH` (and `DELETE` if it has side-effects beyond removing a row).

- Cache the response keyed by `(route, key, principal)` for 24 h
- Same key → cached response returned (no duplicate side-effect, no second `201`)
- Same key but a *different* request body → `409 Conflict`
- Keys are client-supplied opaque strings; the API never generates them

---

## Optimistic concurrency

For mutable resources, surface the row version as an `ETag` and require `If-Match` on writes.

- `GET /resources/{id}` returns `ETag: "<rowversion>"`
- `PUT|PATCH|DELETE /resources/{id}` accepts `If-Match: "<rowversion>"` — present + mismatch → `412 Precondition Failed`; absent → write proceeds (lenient default; clients opt in by sending the header)
- EF Core: `[Timestamp] public byte[] RowVersion { get; set; }`; the handler maps `DbUpdateConcurrencyException` to `412`

---

## Rate limiting

- Named policies per endpoint group — never a single global limit
- Always emit `Retry-After` on `429`
- Partition by authenticated principal first; fall back to remote IP only for anonymous endpoints

Registration scaffold: [`.ai/references/dotnet-webapi/rate-limiting.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/rate-limiting.md)

---

## CORS

- Explicit origin allowlist per environment via `WithOrigins(...)`
- **Never** combine `AllowAnyOrigin()` with `AllowCredentials()` — browsers reject it; it signals a misconfiguration
- Scope methods and headers to what the API accepts — no blanket `AllowAnyMethod()`
- Preflight cache via `SetPreflightMaxAge(TimeSpan.FromHours(1))`

---

## HTTP logging

**Never log** `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, or any header that may carry credentials. Calling `RequestHeaders.Clear()` before adding a curated allowlist is **mandatory** — the framework defaults include sensitive headers.

Registration scaffold: [`.ai/references/dotnet-webapi/http-logging.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/http-logging.md)

---

## Long-running operations

For work too long for one request: the kickoff `POST` returns `202 Accepted` + `Location: /api/v1.0/operations/{opId}`; polling `GET` returns `200 OK` (`running | succeeded | failed`) in progress, then `303 See Other` + `Location: <result-resource>` on completion. Retain operations ≥ 24 h so clients can observe the terminal state.

---

## Response compression

- Brotli first, gzip fallback
- Exclude already-compressed media types (`image/*`, `application/zip`, `application/x-protobuf`, etc.) — wasted CPU otherwise

Registration scaffold: [`.ai/references/dotnet-webapi/response-compression.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/response-compression.md)

---

## OpenAPI & Scalar

- API metadata (Title / Version / Description / Contact / License) is mandatory — published APIs without it are rejected in review
- Scalar UI at `/scalar`; OpenAPI document at `/openapi/v1.0.json`
- Code samples enabled for **bash curl** and **PowerShell** at minimum; other clients opt-in
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

Unit-test conventions and the baseline `<Module>.UnitTests` / `<Module>.IntegrationTests` layout live in the `dotnet-core` partial. For WebAPI, the integration project uses `WebApplicationFactory` + Testcontainers, plus one optional contract project:

```text
tests/
  Api.ContractTests/          ← optional — pinned OpenAPI snapshot
```

No bUnit, no Playwright — those are Blazor-stack concerns.

### Integration tests — WebApplicationFactory + Testcontainers

- `WebApiFactory : WebApplicationFactory<Program>` swaps real infrastructure for Testcontainers (Postgres, Redis, etc.)
- Each test class owns its database via Testcontainers — no shared mutable state across classes
- Auth in tests: register a test scheme injecting a known principal — never call the real identity provider

Test class scaffold: [`.ai/references/dotnet-webapi/integration-test.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/integration-test.md)

### Manual / exploratory testing — Bruno

Collections in `bruno/`, one folder per module, committed to Git. Base URLs and tokens come from Bruno environments — never hardcoded. When an endpoint changes, update its Bruno request in the same PR with realistic bodies and useful assertions.

Layout + naming: [`.ai/references/dotnet-webapi/bruno-layout.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/bruno-layout.md)

### Performance / load testing — k6

Scripts in `perf/`, one scenario per critical journey or hot endpoint. Naming: `<endpoint-or-journey>.<profile>.js`, profile ∈ `smoke | load | stress | soak`. Every script declares `thresholds` for `http_req_duration` and `http_req_failed` — a failed threshold fails CI. Env via `K6_BASE_URL`; auth via `perf/lib/` helpers — never hardcoded. CI: smoke blocks every PR; load / stress / soak on demand.

Layout + sample script + profile defs: [`.ai/references/dotnet-webapi/k6-scenarios.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/k6-scenarios.md)

---

## Project Scaffold Checklist (WebAPI additions)

WebAPI-specific init-time checklist (inherits the base + .NET checklists) lives at [`.ai/references/scaffold-checklists.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/scaffold-checklists.md) under "**.NET WebAPI**".

---

## Agent Guardrails (WebAPI additions)

Every rule in this layer is enforced as written above. One additional guardrail:

- Do not create POST or PATCH endpoints without considering whether `Idempotency-Key` should be supported
