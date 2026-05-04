# Authentication — three approved schemes

**One scheme per API project.** Do not mix schemes in the same service. The choice is made at project bootstrap and applies to every endpoint.

## 1. Pass-through (BFF / wrapper APIs)

For projects that proxy or fan out to an upstream API, the upstream remains the source of authentication truth.

- Forward the incoming `Authorization` header verbatim to the upstream
- Do **not** validate, re-issue, decode, log, or transform the bearer token in transit
- Do not call `AddAuthentication()` for token validation in this project — auth lives upstream
- If the project also exposes its own non-proxied endpoints, it isn't a pass-through project; pick a different scheme

## 2. API key (`X-API-Key`)

Header-based key validation for service-to-service traffic where JWT is overkill.

- Header name is exactly `X-API-Key` — no alternatives, no query-string fallback
- Validate via a custom `AuthenticationHandler<ApiKeySchemeOptions>`; never inline-check in the endpoint
- Keys live in a secret store (env vars / Key Vault / Docker secret) — never in source, never in `appsettings.json`
- Constant-time comparison only (`CryptographicOperations.FixedTimeEquals`)
- Rotate keys without downtime by accepting a small set of valid keys, not a single value

## 3. JWT bearer (token validation)

For APIs consuming tokens issued elsewhere (Identity provider, OAuth2 / OIDC server).

- `AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(...)`
- Validate issuer, audience, lifetime, and signing key — never disable validation in any environment
- Authorization decisions via `AddAuthorization` policies — endpoints reference policy names, not raw role strings
- This API **consumes** tokens — token issuance belongs in a dedicated identity service, not here

## Cross-cutting auth rules

- `[Authorize]` (or `.RequireAuthorization()`) is the default for projects on the API key or JWT scheme; opt out individually with `[AllowAnonymous]`. Pass-through projects do not register an authentication scheme — the upstream enforces auth.
- Anonymous endpoints are limited to `/health/*`, `/scalar`, and the OpenAPI document
- Never log the `Authorization`, `Cookie`, or `X-API-Key` header
