# ProblemDetails (RFC 9457) + global exception handler — registration

```csharp
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
```

Every error response — including those produced by middleware and model binding — must be RFC 9457 `ProblemDetails`. Populate `type`, `title`, `status`, `detail`, `instance` on every response; add a `traceId` extension keyed on the current `Activity.TraceId`.
