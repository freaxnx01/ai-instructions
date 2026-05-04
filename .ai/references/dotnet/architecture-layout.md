# Architecture — directory layouts

## Modular Monolith — top-level layout

```
src/
  Modules/
    Orders/
      Domain/
      Application/
      Infrastructure/
    Catalog/
      Domain/
      Application/
      Infrastructure/
  Shared/
  Host/           ← ASP.NET Core entry point, wires modules
```

Modules communicate via in-process interfaces — never direct project references across modules. Shared kernel in `src/Shared/` for cross-cutting types only. Modules register their own DI services via `IServiceCollection` extension methods.

## Hexagonal (Ports & Adapters) within a module

Apply when a module has multiple infrastructure adapters (e.g. REST + messaging) or needs strong testability isolation.

```
<Module>/
  Domain/           ← pure domain logic, no dependencies
  Application/
    Ports/
      Driving/      ← IOrderService (inbound)
      Driven/       ← IOrderRepository (outbound)
    UseCases/
  Infrastructure/
    Adapters/
      Persistence/
      Http/
      Messaging/
```
