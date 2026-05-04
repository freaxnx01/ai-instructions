# Rate limiting — named-policy registration

Named policies per endpoint group — never a single global limit. Partition by authenticated principal first; fall back to remote IP only for anonymous endpoints. Always emit `Retry-After` on `429`.

```csharp
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("per-user", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.User.Identity?.Name ?? httpContext.Connection.RemoteIpAddress!.ToString(),
            factory: _ => new FixedWindowRateLimiterOptions { PermitLimit = 100, Window = TimeSpan.FromMinutes(1) }));

    options.OnRejected = async (ctx, ct) =>
    {
        ctx.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        ctx.HttpContext.Response.Headers.RetryAfter = "60";
        await ctx.HttpContext.Response.WriteAsync("Rate limit exceeded.", ct);
    };
});
```
