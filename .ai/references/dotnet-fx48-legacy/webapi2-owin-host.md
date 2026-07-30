# ASP.NET Web API 2 + OWIN host (self-host and IIS)

Generic skeleton for a net48 REST service built on **ASP.NET Web API 2**
(`System.Web.Http`) — the alternative legacy REST flavour to the Nancy scaffold
in [`nancy-owin-host.md`](nancy-owin-host.md). Use this one when the existing
code has `ApiController` classes rather than `NancyModule`s; don't mix the two
flavours in one project. Replace `Acme.Service` / `<Solution>` with your real
(private) names.

## Controller — attribute routing, one resource area per controller

```csharp
using System.Web.Http;

namespace Acme.Service.Rest.Controllers
{
    [RoutePrefix("widgets")]
    public sealed class WidgetsController : ApiController
    {
        private readonly IWidgetService _widgets;

        public WidgetsController(IWidgetService widgets)
        {
            _widgets = widgets;
        }

        [HttpGet, Route("")]
        public IHttpActionResult GetAll() => Ok(_widgets.All());

        [HttpGet, Route("{id}")]
        public IHttpActionResult Get(string id)
        {
            var widget = _widgets.Find(id);
            return widget is null ? (IHttpActionResult)NotFound() : Ok(widget);
        }

        [HttpPost, Route("")]
        public IHttpActionResult Create(CreateWidget dto)
        {
            var created = _widgets.Create(dto);
            return Created($"widgets/{created.Id}", created);
        }
    }
}
```

## HttpConfiguration — attribute routing + Newtonsoft as the configured formatter

```csharp
using Autofac.Integration.WebApi;
using System.Net.Http.Formatting;
using System.Web.Http;
using Newtonsoft.Json.Serialization;

namespace Acme.Service.Rest
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            config.MapHttpAttributeRoutes();

            config.Formatters.Remove(config.Formatters.XmlFormatter);
            var json = config.Formatters.JsonFormatter;
            json.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            json.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;

            config.Services.Replace(typeof(System.Web.Http.ExceptionHandling.IExceptionHandler),
                new ProblemDetailsExceptionHandler());
            config.Services.Add(typeof(System.Web.Http.ExceptionHandling.IExceptionLogger),
                new NLogExceptionLogger());

            config.DependencyResolver =
                new AutofacWebApiDependencyResolver(ServiceRegistration.BuildContainer());
        }
    }
}
```

## OWIN Startup (self-host)

```csharp
using Owin;
using System.Web.Http;

namespace Acme.Service.Rest
{
    public sealed class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            var config = new HttpConfiguration();
            WebApiConfig.Register(config);
            app.UseWebApi(config);
        }
    }
}
```

Self-host entry point (Console / Windows Service) is identical to the Nancy
scaffold's — `Microsoft.Owin.Hosting.WebApp.Start<Startup>(url)` — but the
package reference is **`Microsoft.AspNet.WebApi.Owin`**, not `Nancy.Owin`.

## IIS host — split from self-host

IIS does **not** go through the OWIN `Startup` class above; it uses the
`System.Web.Http.WebHost` pipeline instead, wired from `Global.asax`:

```csharp
using System.Web.Http;

namespace Acme.Service.Rest.IIS
{
    public class Global : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            GlobalConfiguration.Configure(WebApiConfig.Register);
        }
    }
}
```

Reference **`Microsoft.AspNet.WebApi.WebHost`** (not `.Owin`) for this host
project. The `WebApiConfig.Register` method is shared between both hosts; only
the entry point and the package reference differ — keep `<Solution>.Rest.IIS`
as the thin host project, same as the Nancy layout.

## Central error shaping — `IExceptionHandler` / `IExceptionLogger`

Web API 2 has no `OnError` pipeline; it separates **logging** (side effects,
never changes the response) from **handling** (produces the response):

```csharp
using System.Net.Http;
using System.Web.Http.ExceptionHandling;

namespace Acme.Service.Rest
{
    public sealed class NLogExceptionLogger : ExceptionLogger
    {
        private static readonly NLog.Logger Log = NLog.LogManager.GetCurrentClassLogger();

        public override void Log(ExceptionLoggerContext context)
        {
            Log.Error(context.Exception, "Unhandled exception in {Method} {Path}",
                context.Request.Method, context.Request.RequestUri);
        }
    }

    public sealed class ProblemDetailsExceptionHandler : ExceptionHandler
    {
        public override void Handle(ExceptionHandlerContext context)
        {
            // Map to a ProblemDetails-style JSON body; never leak stack traces.
            context.Result = new System.Web.Http.Results.ResponseMessageResult(
                context.Request.CreateResponse(System.Net.HttpStatusCode.InternalServerError,
                    new { title = "Unexpected error", status = 500 }));
        }
    }
}
```

Register both in `HttpConfiguration.Services` (see `WebApiConfig.Register`
above) — `IExceptionLogger` can have many instances, `IExceptionHandler` is a
single replaceable service.

## DI — `IDependencyResolver` (Autofac/Unity), not TinyIoC

Web API 2 has no built-in container; wire whichever the solution already uses
via `IDependencyResolver`. Autofac shown (`Autofac.WebApi2` package):

```csharp
using Autofac;

namespace Acme.Service.Rest
{
    internal static class ServiceRegistration
    {
        public static IContainer BuildContainer()
        {
            var builder = new ContainerBuilder();
            builder.RegisterType<WidgetService>().As<IWidgetService>().InstancePerRequest();
            return builder.Build();
        }
    }
}
```

`config.DependencyResolver = new AutofacWebApiDependencyResolver(ServiceRegistration.BuildContainer());`
replaces the TinyIoC registration step from the Nancy `Bootstrapper`. Unity is
the equivalent alternative (`Unity.WebApi` package,
`UnityDependencyResolver`) — detect which one is already referenced before
introducing a second container.

## Detecting which flavour is in play

Before adding an endpoint, check the existing REST project for:

- `NancyModule` subclasses + a `Bootstrapper` → use
  [`nancy-owin-host.md`](nancy-owin-host.md).
- `ApiController` subclasses + `WebApiConfig` / `GlobalConfiguration` → use
  this file.

Both can legitimately exist in *different* projects of the same solution
during a migration; never introduce the second flavour into a project that
already commits to one.
