# OpenAPI + Scalar — registration with metadata + curl/PowerShell samples

API metadata (Title / Version / Description / Contact / License) is mandatory — published APIs without metadata are rejected in review. Scalar UI at `/scalar`; OpenAPI document at `/openapi/v1.0.json`. Code samples enabled for **bash curl** and **PowerShell** at minimum.

```csharp
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, _, _) =>
    {
        document.Info = new OpenApiInfo
        {
            Title = "Orders API",
            Version = "v1.0",
            Description = "...",
            Contact = new OpenApiContact { Name = "Platform Team", Email = "platform@example.com" },
            License = new OpenApiLicense { Name = "Proprietary" }
        };
        return Task.CompletedTask;
    });
});

app.MapOpenApi();
app.MapScalarApiReference(options =>
{
    options.WithDefaultHttpClient(ScalarTarget.Shell, ScalarClient.Curl);    // bash curl examples
    options.WithDefaultHttpClient(ScalarTarget.PowerShell, ScalarClient.Invoke); // PowerShell Invoke-RestMethod
    options.WithTheme(ScalarTheme.Default);
});
```

Deprecated endpoints carry the OpenAPI `deprecated: true` flag *and* return a `Sunset` response header.
