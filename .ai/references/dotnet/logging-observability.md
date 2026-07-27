# Logging & observability (.NET baseline)

The 12-factor enforcement points — no local filesystem writes for application state, no
secrets in `appsettings.Development.json`, migrations as a separate step, stdout/OTLP
sinks only — stay inline in the stack overlay, because violating them breaks production
rather than merely being untidy. This file holds the configuration detail.

## Serilog

- Configured in `Program.cs` via `UseSerilog()`.
- Structured properties on every log entry: `{ModuleName}`, `{CorrelationId}`.
- Use `LoggerMessage.Define` source-generated logging on hot paths — it avoids the
  boxing and format-string parsing of the `ILogger` extension methods.
- Log levels: `Debug` locally, `Information` as the production minimum.

## OpenTelemetry

- Export traces to an OTLP collector.
- Expose `/metrics` in Prometheus format.

## Health checks

- `/health/live` — liveness; process is up.
- `/health/ready` — readiness; checks the database and any other hard dependency.

Both are anonymous endpoints (see the WebAPI authentication rules).
