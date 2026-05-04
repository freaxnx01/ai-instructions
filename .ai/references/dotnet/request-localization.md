# RequestLocalization middleware — `de` / `en` configuration

Wire in `Program.cs`. Resolution order: cookie (`.AspNetCore.Culture`) → `Accept-Language` header → default (`de-CH` / `de`).

```csharp
var supportedCultures = new[] { "de-CH", "de-DE", "de-AT", "en-US", "en-GB" }
    .Select(c => new CultureInfo(c)).ToList();
var supportedUICultures = new[] { "de", "en" }
    .Select(c => new CultureInfo(c)).ToList();

app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture("de-CH", "de"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedUICultures,
    ApplyCurrentCultureToResponseHeaders = true,
});
```

For language `de` with no recognized region (or a `de-*` region not in `SupportedCultures`), the framework falls back to `de-CH` via the default — never `de-DE`.
