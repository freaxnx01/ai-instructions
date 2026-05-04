# HTTP logging — registration with sensitive-header exclusion

The `RequestHeaders.Clear()` call is **mandatory** — the framework defaults include sensitive headers. Never log `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, or any header that may carry credentials.

```csharp
builder.Services.AddHttpLogging(options =>
{
    options.LoggingFields = HttpLoggingFields.RequestMethod
                          | HttpLoggingFields.RequestPath
                          | HttpLoggingFields.ResponseStatusCode
                          | HttpLoggingFields.Duration;
    options.RequestHeaders.Clear();
    options.ResponseHeaders.Clear();
    options.RequestHeaders.Add("User-Agent");
    options.RequestHeaders.Add("X-Correlation-Id");
});
```
