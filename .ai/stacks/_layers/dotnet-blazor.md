[//]: # (Stack layer — composed with .ai/stacks/_partials/dotnet-core.md by `scripts/build-stacks.sh` to produce .ai/stacks/dotnet-blazor.md. Do not edit the generated file directly.)

# .NET Blazor Layer

ASP.NET Core projects with a Blazor + MudBlazor UI (CSR, SSR, or both). Composed on top of the shared `dotnet-core` partial.

---

## Tech Stack (Blazor additions)

| Layer | Technology |
|---|---|
| Frontend | Blazor CSR or SSR (per project) |
| UI components | MudBlazor |
| Component testing | bUnit |
| End-to-end testing | Playwright |

---

## Blazor Conventions

- CSR (WebAssembly) for full SPA, SSR for SEO-critical or auth-heavy pages
- MudBlazor as the only component library — no mixing with other UI libs
- Components in `src/Host/Components/` or per-module `Components/` folder
- `@code` block kept minimal — extract logic to services or `ViewModel` classes
- Use `[Parameter]` only for the public API of a component; internal state via fields
- `EventCallback<T>` for child-to-parent communication

### MudBlazor Conventions

- Prefer MudBlazor components over raw HTML at all times
- Use `MudDataGrid` for tabular data (not `MudTable` unless legacy)
- Use `MudForm` + `MudTextField` / `MudSelect` for forms with validation
- Use `MudDialog` for confirmations and modals (not custom overlays)
- Use `MudSnackbar` for user feedback / toast messages
- Use `MudSkeleton` for loading states
- Layout: `MudLayout` → `MudAppBar` + `MudDrawer` + `MudMainContent`
- Icons: use `Icons.Material.Filled.*` consistently

### Component Conventions

- One component per file
- Component files: `PascalCase.razor`
- Code-behind files: `PascalCase.razor.cs` (partial class)
- Services injected via `@inject` or constructor in code-behind
- No business logic in `.razor` files — only binding and UI events
- Reuse components from `/src/Shared/` before creating new ones

### State & Data Flow

- Components do not call APIs directly — always go through a service
- Services are registered in `Program.cs` with appropriate lifetime
- Use `EventCallback` for child→parent communication
- Use `CascadingParameter` only for truly global state (e.g. auth, theme)

### UI workflow — stack-specific hints

The phase order and gates are defined in `base-instructions.md`. For Blazor projects:

- **Phase 1 (wireframe):** think in MudBlazor regions — `MudAppBar`, `MudDrawer`, `MudMainContent`, `MudDataGrid`, `MudForm`, `MudDialog`.
- **Phase 2 (flow):** use MudBlazor component names in the component & state map.
- **Phase 3 (build):** code-behind `.razor.cs` for all logic; use `MudSkeleton` / `MudProgressLinear` for loading, `MudSnackbar` for errors, `MudDialog` for destructive confirmations, `MudForm` + `DataAnnotations` for validation, `ma-*` / `pa-*` / `MudStack` / `MudGrid` for spacing.
- **Phase 4 (review):** verify no raw HTML where a MudBlazor component exists; `MudDataGrid` (not `MudTable`), `MudSnackbar` (not custom toast), `Icons.Material.Filled.*`, a bUnit test file exists for the component.

---

## Localization & Regional Formatting (Blazor additions)

Server-side localization (RequestLocalization, culture resolution, fallback rules, `CurrentCulture` formatting) is covered by the `dotnet-core` partial. For Blazor / MudBlazor specifically:

- UI strings go through `IStringLocalizer<T>` + `.resx` resources per `de` / `en`. Do not put translatable strings inline in `.razor` files.
- MudBlazor pickers (`MudDatePicker`, `MudNumericField`, etc.) read `CurrentCulture` automatically — do not override per-component.
- Provide a language switcher in the layout (`MudMenu` in `MudAppBar`) that writes the chosen language into the `.AspNetCore.Culture` cookie and reloads the page.

---

## Testing (Blazor additions)

The unit-test conventions and test project layout baseline live in the `dotnet-core` partial. For Blazor projects, add:

```
tests/
  <Module>.ComponentTests/    ← bUnit
  E2E/                        ← Playwright
```

### Blazor component tests (bUnit)

- Test components in isolation using `bUnit` + `Bunit.Web.AngleSharp`
- Use `Ctx.RenderComponent<T>()` with parameter builders
- Assert on rendered markup and component state
- Mock services via `Ctx.Services.AddSingleton<IMyService>(mock)`
- Test event handlers: `cut.Find("button").Click()` then assert resulting state
- Test parameter changes: `cut.SetParametersAndRender(p => p.Add(x => x.Param, newValue))`
- Test async lifecycle: `cut.WaitForState(() => condition)` for loading states

```csharp
public sealed class OrderListComponentTests : TestContext
{
    [Fact]
    public void OrderList_WithOrders_RendersOrderRows()
    {
        // Arrange
        Services.AddSingleton(Substitute.For<IOrderService>());

        // Act
        var cut = RenderComponent<OrderList>(p =>
            p.Add(c => c.Orders, [new OrderDto(Guid.NewGuid(), "Pending")]));

        // Assert
        cut.FindAll("tr.order-row").Should().HaveCount(1);
    }
}
```

### E2E tests (Playwright)

- Tests in `tests/E2E/`
- Use `Microsoft.Playwright.NUnit` or an xUnit wrapper
- Page Object Model (POM) pattern — no raw selectors in test methods
- Tests must be independent and idempotent (seed + teardown own data)
- Run against the `docker-compose` stack in CI

```csharp
public sealed class OrderCreationTests : PageTest
{
    [Test]
    public async Task CreateOrder_ValidInput_ShowsConfirmation()
    {
        var page = new OrderPage(Page);
        await page.GotoAsync();
        await page.FillOrderFormAsync(customerId: "test-001");
        await page.SubmitAsync();
        await Expect(page.ConfirmationBanner).ToBeVisibleAsync();
    }
}
```

### CI addition

```yaml
e2e:
  needs: docker
  - docker-compose up -d
  - dotnet test tests/E2E
  - docker-compose down
```

---

## Project Scaffold Checklist (Blazor additions)

Inherits the `dotnet-core` checklist, plus:

- [ ] `MudBlazor` registered in `Program.cs` (`AddMudServices()`)
- [ ] Component test project (`<Module>.ComponentTests`) using bUnit
- [ ] E2E project (`tests/E2E`) using Playwright, wired into CI behind the docker stack
- [ ] Language switcher (`MudMenu` in `MudAppBar`) wired to the `.AspNetCore.Culture` cookie
- [ ] `IStringLocalizer<T>` + `.resx` resources seeded for `de` and `en`

---

## Agent Guardrails (Blazor additions)

In addition to the base and `dotnet-core` guardrails:

- Do not mix UI component libraries — MudBlazor is the only one
- Do not put business logic in `.razor` files — extract to code-behind, services, or view models
- Do not put translatable strings inline in `.razor` files — use `IStringLocalizer<T>`
- Do not call APIs directly from a component — always go through a registered service
- Do not use `MudTable` for new tabular data — use `MudDataGrid`
- Do not use custom toast / overlay widgets — use `MudSnackbar` and `MudDialog`
- Do not skip a bUnit test when adding or materially changing a component
- `async void` is allowed only on Blazor event handlers — never elsewhere
