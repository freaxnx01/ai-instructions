# Integration test — `WebApplicationFactory` + Testcontainers

`WebApiFactory : WebApplicationFactory<Program>` swaps real infrastructure for Testcontainers (Postgres, Redis, etc.). Each test class owns its database via Testcontainers — no shared mutable state across classes. Authentication in tests: register a test scheme that injects a known principal — never call the real identity provider.

```csharp
public sealed class OrderApiTests : IClassFixture<WebApiFactory>
{
    private readonly HttpClient _client;

    public OrderApiTests(WebApiFactory factory) => _client = factory.CreateClient();

    [Fact]
    public async Task PostOrder_ValidPayload_Returns201WithLocation()
    {
        var response = await _client.PostAsJsonAsync("/api/v1.0/orders",
            new CreateOrderRequest(CustomerId: Guid.NewGuid(), Items: []));

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        response.Headers.Location.Should().NotBeNull();
    }
}
```
