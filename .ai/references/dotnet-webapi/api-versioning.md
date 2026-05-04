# Asp.Versioning.Http — URL-segment versioning setup

URL format: `v1.0`, `v2.0`, `v2.1` — `MAJOR.MINOR`. The minor segment is part of the URL even when only the major bumps, so the URL shape stays consistent across the lifetime of the API.

```csharp
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;   // unversioned URLs → v1.0
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
    options.ReportApiVersions = true;                     // emit api-supported-versions / api-deprecated-versions headers
}).AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";                   // must produce "v{MAJOR}.{MINOR}" — verify against the installed Asp.Versioning version
    options.SubstituteApiVersionInUrl = true;
});
```

Deprecate an endpoint with `.HasDeprecatedApiVersion(1.0)` plus a `Sunset: <RFC 7231 date>` header on responses. Removal is a separate step from deprecation — no version is removed without an announced sunset window.
