# Nancy + OWIN host (self-host and IIS)

Generic skeleton for a net48 REST service built on Nancy 2.x over OWIN/Katana.
Replace `Acme.Service` / `<Solution>` with your real (private) names.

## Module — one resource area per module

```csharp
using Nancy;
using Nancy.ModelBinding;

namespace Acme.Service.Rest.Modules
{
    public sealed class WidgetsModule : NancyModule
    {
        public WidgetsModule(IWidgetService widgets) : base("/widgets")
        {
            Get("/", _ => Response.AsJson(widgets.All()));

            Get("/{id}", parameters =>
            {
                var widget = widgets.Find((string)parameters.id);
                return widget is null
                    ? Negotiate.WithStatusCode(HttpStatusCode.NotFound)
                    : Response.AsJson(widget);
            });

            Post("/", _ =>
            {
                var dto = this.Bind<CreateWidget>();
                var created = widgets.Create(dto);
                return Negotiate
                    .WithStatusCode(HttpStatusCode.Created)
                    .WithHeader("Location", $"/widgets/{created.Id}")
                    .WithModel(created);
            });
        }
    }
}
```

## Bootstrapper — TinyIoC registration + JSON via Newtonsoft

```csharp
using Nancy;
using Nancy.Bootstrapper;
using Nancy.TinyIoc;

namespace Acme.Service.Rest
{
    public sealed class Bootstrapper : DefaultNancyBootstrapper
    {
        protected override void ConfigureApplicationContainer(TinyIoCContainer container)
        {
            base.ConfigureApplicationContainer(container);
            container.Register<IWidgetService, WidgetService>();
        }

        protected override void RequestStartup(
            TinyIoCContainer container, IPipelines pipelines, NancyContext context)
        {
            pipelines.OnError.AddItemToEndOfPipeline((ctx, ex) =>
            {
                // Map to a ProblemDetails-style JSON body; never leak stack traces.
                ctx.Response = new Nancy.Responses.JsonResponse(
                    new { title = "Unexpected error", status = 500 },
                    new Nancy.Responses.DefaultJsonSerializer(ctx.Environment))
                { StatusCode = HttpStatusCode.InternalServerError };
                return ctx.Response;
            });
        }
    }
}
```

## OWIN Startup (shared by self-host and IIS)

```csharp
using Nancy.Owin;
using Owin;

namespace Acme.Service.Rest
{
    public sealed class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            app.UseNancy(options => options.Bootstrapper = new Bootstrapper());
        }
    }
}
```

## Self-host (Console / Windows Service)

```csharp
using Microsoft.Owin.Hosting;

// Console entry point:
using (WebApp.Start<Startup>("http://localhost:8080"))
{
    Console.WriteLine("Listening on http://localhost:8080 — press Enter to stop.");
    Console.ReadLine();
}
```

For a Windows Service, wrap `WebApp.Start<Startup>(url)` in `ServiceBase.OnStart`
and dispose the returned handle in `OnStop`.

## IIS host

Reference `Microsoft.Owin.Host.SystemWeb`; the `Startup` class above is discovered
automatically (or pin it with `[assembly: OwinStartup(typeof(Startup))]`). The
web host is a thin project (`<Solution>.Rest.IIS`) that references the Nancy
modules assembly and contains only `web.config` + the OWIN wiring.
