# Endpoint group — Minimal API baseline scaffold

Used when grouping endpoints by module via `IEndpointRouteBuilder` extension methods. Apply the rules in `.ai/stacks/_partials/dotnet-core.md` (or the deeper rules in `.ai/stacks/_layers/dotnet-webapi.md`); this file is just the scaffold.

```csharp
public static class OrderEndpoints
{
    public static IEndpointRouteBuilder MapOrderEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders")
                       .WithTags("Orders")
                       .WithOpenApi();

        group.MapPost("/", CreateOrderAsync).WithName("CreateOrder");
        group.MapGet("/{id:guid}", GetOrderByIdAsync).WithName("GetOrderById");

        return app;
    }
}
```

For versioned WebAPI projects, replace the route prefix with `/api/v{version:apiVersion}/orders` and add `.HasApiVersion(1.0)` to the group — see `.ai/references/dotnet-webapi/api-versioning.md`.
