# Response compression — Brotli first, gzip fallback

```csharp
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});
```

Exclude already-compressed media types (`image/*`, `application/zip`, `application/x-protobuf`, etc.) — wasted CPU otherwise.
