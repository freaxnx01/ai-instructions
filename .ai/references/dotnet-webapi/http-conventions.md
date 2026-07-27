# WebAPI — HTTP conventions

## Status codes

Non-obvious rules:

- `201 Created` must include a `Location` header pointing at the new resource.
- `202 Accepted` must include a `Location` header pointing at the status resource.
- Use `422 Unprocessable Content` — not `400` — for semantic validation failures, i.e.
  the body parsed fine but its content is invalid. Reserve `400` for malformed requests.
- `429 Too Many Requests` must include `Retry-After`.

## GET with a request body — forbidden for new endpoints

GET bodies have undefined semantics (RFC 9110); proxies and caches may drop them, so the
same request can behave differently depending on the path it takes.

- **New endpoints:** use query parameters, or `POST /search` when the filter set is large
  or sensitive.
- **Legacy endpoints:** allowed for backwards compatibility only. Mark them `[Obsolete]`
  and emit a `Sunset` header so clients can migrate.

## Errors — always ProblemDetails

Every error response, including those from middleware and model binding, is RFC 9457
`ProblemDetails`. Never return raw strings, anonymous `{ error: "..." }` objects, or HTML
error pages. Populate `type`, `title`, `status`, `detail`, `instance`, and add a `traceId`
extension from the current `Activity.TraceId`.

Registration scaffold: [`problem-details.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-webapi/problem-details.md)
