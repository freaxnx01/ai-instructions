# .NET Stack — Tech Stack tables

## .NET baseline

| Layer | Technology |
|---|---|
| Runtime | .NET 10 / C# |
| Backend | ASP.NET Core, Minimal API |
| ORM | Entity Framework Core |
| DB (small) | SQLite |
| DB (non-small) | PostgreSQL |
| Validation | FluentValidation |
| Logging | Serilog with structured output |
| Observability | OpenTelemetry (traces + metrics) |
| API docs | OpenAPI + Scalar |
| Containerization | Docker + docker-compose (Alpine base images) |
| Unit / integration testing | xUnit + FluentAssertions + NSubstitute |

## .NET WebAPI additions

| Layer | Technology |
|---|---|
| API style | REST · ASP.NET Core Minimal API |
| API versioning | `Asp.Versioning.Http` (URL-segment) |
| Authentication | One of: pass-through · API key (`X-API-Key`) · JWT bearer — **single scheme per project** |
| Error responses | `ProblemDetails` (RFC 9457) |
| API docs | `Microsoft.AspNetCore.OpenApi` + Scalar UI at `/scalar` |
| Manual / exploratory | Bruno (collections in `bruno/`) |
| Integration testing | xUnit + `WebApplicationFactory` + Testcontainers |
| Performance / load testing | k6 (scripts in `perf/`) |
| Client SDK generation | Kiota |
