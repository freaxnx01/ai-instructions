# xUnit (desktop runner) test project — net48

net48 test projects run on the **desktop** xUnit runner. SDK-style test projects
reference `xunit` + `xunit.runner.visualstudio`; classic projects pin them via
`packages.config` and the `xunit.runner.console` executable.

## Project layout

```
tests/
  <Module>.Tests/            ← xUnit desktop; Moq + Shouldly
  TestHelpers/               ← shared fakes, fixtures, builders (referenced by tests)
```

## SDK-style test csproj (recommended for new test projects)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" Version="2.9.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="Shouldly" Version="4.2.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\<Solution>.Core\<Solution>.Core.csproj" />
    <ProjectReference Include="..\TestHelpers\TestHelpers.csproj" />
  </ItemGroup>
</Project>
```

## Example test (xUnit + Moq + Shouldly)

Naming: `MethodName_StateUnderTest_ExpectedBehavior` (same as base).

```csharp
using Moq;
using Shouldly;
using Xunit;

public class WidgetServiceTests
{
    [Fact]
    public void Find_UnknownId_ReturnsNull()
    {
        var repo = new Mock<IWidgetRepository>();
        repo.Setup(r => r.Get("missing")).Returns((Widget)null);
        var sut = new WidgetService(repo.Object);

        var result = sut.Find("missing");

        result.ShouldBeNull();
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void Find_BlankId_Throws(string id)
    {
        var sut = new WidgetService(Mock.Of<IWidgetRepository>());

        Should.Throw<ArgumentException>(() => sut.Find(id));
    }
}
```

## Nancy endpoint test (Nancy.Testing)

```csharp
using Nancy.Testing;
using Shouldly;
using Xunit;

public class WidgetsModuleTests
{
    [Fact]
    public void Get_UnknownWidget_Returns404()
    {
        var browser = new Browser(with => with.Module<WidgetsModule>());

        var response = browser.Get("/widgets/missing", with => with.HttpRequest()).Result;

        response.StatusCode.ShouldBe(Nancy.HttpStatusCode.NotFound);
    }
}
```

Run all tests via the Cake `Test` target (see `cake-build.md`); locally,
`dotnet test` works **only** for SDK-style test projects — classic
`packages.config` test projects run through `xunit.console.exe` or `vstest`.
