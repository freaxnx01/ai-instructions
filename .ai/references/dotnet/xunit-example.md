# xUnit unit test — example shape

Reference shape for a unit test class. One test class per production class. Naming: `MethodName_StateUnderTest_ExpectedBehavior`. Use `FluentAssertions` for assertions, `NSubstitute` for mocks.

```csharp
public sealed class CreateOrderHandlerTests
{
    private readonly IOrderRepository _repository = Substitute.For<IOrderRepository>();
    private readonly CreateOrderHandler _sut;

    public CreateOrderHandlerTests() => _sut = new CreateOrderHandler(_repository);

    [Fact]
    public async Task Handle_ValidCommand_CreatesAndPersistsOrder()
    {
        // Arrange
        var command = new CreateOrderCommand(CustomerId: Guid.NewGuid(), Items: []);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        await _repository.Received(1).AddAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>());
    }
}
```

No `[Fact]` with logic — use `[Theory]` + `[InlineData]` / `[MemberData]` for parameterized cases.
