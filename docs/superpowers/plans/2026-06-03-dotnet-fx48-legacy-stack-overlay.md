# `dotnet-fx48-legacy` Stack Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a public, sanitized `dotnet-fx48-legacy` stack overlay (single-file overlay + linked reference scaffolds) so AI agents maintaining existing .NET Framework 4.8 service projects get the right conventions.

**Architecture:** A self-contained overlay `.ai/stacks/dotnet-fx48-legacy.md` (like `flutter.md`/`go.md`) that inherits everything stack-agnostic from `.ai/base-instructions.md` and only states net48-specific conventions, linking out to full scaffolds under `.ai/references/dotnet-fx48-legacy/`. No build-script/CI changes (the file has no `_layers/` source, so the drift check never touches it).

**Tech Stack (documented, not used to build):** net48 · Nancy + OWIN/Katana · NLog · Newtonsoft.Json · xUnit-desktop + Moq + Shouldly + Nancy.Testing · Cake → `msbuild.exe` · GitLab CI on Windows · centralized `Directory.Build.props`.

**Spec:** `docs/superpowers/specs/2026-06-03-dotnet-fx48-legacy-stack-overlay-design.md`

---

## Working conventions for this plan

- **Branch:** work on `worktree-legacy` (current). Commit per task.
- **Public-repo safety is a hard gate.** The scrub-list grep below MUST return no matches before every commit. Run from repo root:

```bash
# SCRUB CHECK — must print "CLEAN" (case-insensitive, whole tree of new files)
scrub() {
  if grep -rniE 'finnova|bossinfo|pmcinformatik|\bpmc\b|Pmc\.|archiverestapi|\bDMS\b|\bHyp\b|HypArchive|FreeImage|dev\.azure\.com/bossinfo|\.snk|1\.2\.3' \
       .ai/stacks/dotnet-fx48-legacy.md .ai/references/dotnet-fx48-legacy/ 2>/dev/null; then
    echo "SCRUB FAIL — business identifier found above"; return 1
  else echo "CLEAN"; fi
}
```

- **Placeholders only** in every example: `<Solution>`, `<Solution>.Core`, `<Solution>.Rest`, `<Solution>.Host`, `<Module>.Tests`, `Acme.Service`, `Example Co`, version `1.0.0`.
- **Size gate:** after writing the overlay, `scripts/check-claude-md-size.sh` must show `dotnet-fx48-legacy … ok`.

---

## File structure

**Create:**
- `.ai/stacks/dotnet-fx48-legacy.md` — the overlay (≤ ~24 KB)
- `.ai/references/dotnet-fx48-legacy/tech-stack.md`
- `.ai/references/dotnet-fx48-legacy/directory-build-props.md`
- `.ai/references/dotnet-fx48-legacy/nancy-owin-host.md`
- `.ai/references/dotnet-fx48-legacy/xunit-desktop-test.md`
- `.ai/references/dotnet-fx48-legacy/cake-build.md`
- `.ai/references/dotnet-fx48-legacy/gitlab-ci.md`
- `.ai/references/dotnet-fx48-legacy/nlog-config.md`

**Modify:**
- `README.md` — *Supported stacks* table row + layout comment block + single-file/no-`_layers` note

**Author references first, then the overlay** (the overlay links to them), then README, then final verification.

The reference scaffolds below are written **complete and sanitized** — copy them verbatim. The `https://github.com/freaxnx01/ai-instructions/blob/main/...` link base matches the existing `dotnet` references.

---

### Task 1: `tech-stack.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/tech-stack.md`

- [ ] **Step 1: Write the file**

````markdown
# Tech Stack — .NET Framework 4.8 (Legacy) service

| Layer | Technology |
|---|---|
| Target framework | `net48` (full .NET Framework); projects in a single solution may mix **SDK-style** (`Sdk="Microsoft.NET.Sdk"` + `PackageReference`) and **classic** (`<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>` + `packages.config`) styles |
| Language | C# (the latest lang version the installed SDK/compiler allows on net48); **no** implicit usings, **no** nullable reference types by default |
| REST framework | [Nancy](https://github.com/NancyFx/Nancy) 2.x on **OWIN/Katana** — self-hosted via `Microsoft.Owin.Host.HttpListener` and/or hosted in **IIS**. (Alternative legacy flavour: ASP.NET Web API 2 on OWIN.) |
| Views (optional) | Nancy SuperSimpleViewEngine (`.sshtml`) |
| Hosting | Console / **Windows Service** (`System.ServiceProcess`) for self-host; IIS for the web host |
| DI | Nancy **TinyIoC** (built in); register in a custom `Bootstrapper` |
| JSON | [Newtonsoft.Json](https://www.newtonsoft.com/json) 13.x |
| Logging | [NLog](https://nlog-project.org/) 5.x, configured via `NLog.config` |
| Config | `app.config` / `web.config` + `System.Configuration`; binding redirects via `AutoGenerateBindingRedirects` |
| Tests | [xUnit](https://xunit.net/) **desktop runner** (`xunit.runner.console` / `xunit.runner.visualstudio`), [Moq](https://github.com/moq/moq4), [Shouldly](https://github.com/shouldly/shouldly), [Nancy.Testing](https://github.com/NancyFx/Nancy), [RestSharp](https://restsharp.dev/) |
| Build | [Cake](https://cakebuild.net/) (`build.ps1` bootstrap → `build.cake`) driving full-framework **`msbuild.exe`** (not `dotnet build`); 7-Zip for packaging |
| Versioning | Centralized in a repo-root `Directory.Build.props` — one `<Version>` for **all** assemblies |
| CI | GitLab CI running `powershell build.ps1` on a **Windows** runner (alternative: Azure DevOps Pipelines) |
| API exploration | [Bruno](https://www.usebruno.com/) collection under `api-client/` |
````

- [ ] **Step 2: Scrub check**

Run: `scrub` (from the function defined above)
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/tech-stack.md
git commit -m "docs(dotnet-fx48-legacy): add tech-stack reference"
```

---

### Task 2: `directory-build-props.md` reference (centralized versioning)

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/directory-build-props.md`

- [ ] **Step 1: Write the file**

````markdown
# Directory.Build.props — centralized version & shared settings (net48)

Place at the **repo root** (next to the `.sln`). MSBuild (VS2017+/`msbuild.exe`)
auto-imports it for **every** project in the tree — **both** SDK-style and
classic `.csproj` — so there are no per-project edits and no manual `<Import>`.

**One version for the whole solution. Never set a version in an individual `.csproj`.**

```xml
<Project>
  <PropertyGroup>
    <!-- THE single source of truth for the solution version. -->
    <Version>1.0.0</Version>

    <!-- Derived from <Version> unless overridden; keep them inheriting. -->
    <AssemblyVersion>$(Version)</AssemblyVersion>
    <FileVersion>$(Version)</FileVersion>
    <InformationalVersion>$(Version)</InformationalVersion>

    <Company>Example Co</Company>
    <Product>Acme Service</Product>

    <!-- net48 builds; classic projects keep their own <TargetFrameworkVersion>. -->
    <DebugType>full</DebugType>
    <DebugSymbols>true</DebugSymbols>
    <AutoGenerateBindingRedirects>true</AutoGenerateBindingRedirects>
  </PropertyGroup>
</Project>
```

## net48 caveat — classic projects with a hand-written `AssemblyInfo.cs`

Classic projects ship `Properties/AssemblyInfo.cs` with `[assembly: AssemblyVersion(...)]`
etc. With a central version in `Directory.Build.props`, MSBuild *also* generates
those attributes, producing **CS0579 "duplicate attribute"** build errors.

Resolve it **one** of two ways — but define the value in exactly one place:

1. **Let MSBuild generate them (preferred):** in the project (or the shared
   props) set `<GenerateAssemblyInfo>true</GenerateAssemblyInfo>` and **delete**
   the `[AssemblyVersion]`, `[AssemblyFileVersion]`, and
   `[AssemblyInformationalVersion]` lines from `AssemblyInfo.cs`.
2. **Keep a single shared file:** link one generated/shared `AssemblyVersion.cs`
   into every project (`<Compile Include="..\AssemblyVersion.cs" Link="..." />`)
   and remove the version attributes from each project's own `AssemblyInfo.cs`.

## Migration note

If the solution currently uses a manually-`<Import>`ed shared props file (e.g. a
`Project.configuration` imported by each `.csproj`), `Directory.Build.props`
**supersedes it for versioning and common settings**. Keep the imported file only
for genuinely build-matrix-specific settings (per-`Platform` `PlatformTarget`,
`OutputPath`) that you don't want auto-applied to every project.

> Policy (SemVer, Conventional-Commits → bump mapping, changelog, git-cliff)
> lives in `base-instructions.md`. This file is only the net48 stamping mechanism.
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/directory-build-props.md
git commit -m "docs(dotnet-fx48-legacy): add centralized Directory.Build.props reference"
```

---

### Task 3: `nancy-owin-host.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/nancy-owin-host.md`

- [ ] **Step 1: Write the file**

````markdown
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
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/nancy-owin-host.md
git commit -m "docs(dotnet-fx48-legacy): add Nancy + OWIN host reference"
```

---

### Task 4: `xunit-desktop-test.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/xunit-desktop-test.md`

- [ ] **Step 1: Write the file**

````markdown
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
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/xunit-desktop-test.md
git commit -m "docs(dotnet-fx48-legacy): add xUnit desktop test reference"
```

---

### Task 5: `cake-build.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/cake-build.md`

- [ ] **Step 1: Write the file**

````markdown
# Cake build → msbuild.exe (net48)

net48 solutions build with **full-framework `msbuild.exe`**, not `dotnet build`.
Cake orchestrates restore → build → test → package on a Windows agent.

## `build.ps1` (bootstrap)

```powershell
param(
    [string]$Target = "Default",
    [string]$Configuration = "Release"
)
$ErrorActionPreference = "Stop"
dotnet tool restore                       # installs Cake.Tool from .config/dotnet-tools.json
dotnet cake build/build.cake --target=$Target --configuration=$Configuration
```

## `.config/dotnet-tools.json`

```json
{
  "version": 1,
  "isRoot": true,
  "tools": {
    "cake.tool": { "version": "4.0.0", "commands": ["dotnet-cake"] }
  }
}
```

## `build/build.cake`

```csharp
var target = Argument("target", "Default");
var configuration = Argument("configuration", "Release");

var solution = "./<Solution>.sln";

Task("Restore")
    .Does(() => MSBuild(solution, s => s.WithTarget("Restore")
        .SetConfiguration(configuration)));

Task("Build")
    .IsDependentOn("Restore")
    .Does(() => MSBuild(solution, s => s
        .SetConfiguration(configuration)
        .SetPlatformTarget(PlatformTarget.MSIL)   // AnyCPU
        .SetMaxCpuCount(0)));

Task("Test")
    .IsDependentOn("Build")
    .Does(() =>
    {
        // VSTest discovers net48 xUnit (desktop) test assemblies.
        var testAssemblies = GetFiles($"./tests/**/bin/{configuration}/**/*.Tests.dll");
        VSTest(testAssemblies, new VSTestSettings { Parallel = true });
    });

Task("Package")
    .IsDependentOn("Test")
    .Does(() => Zip($"./src/<Solution>.Host/bin/{configuration}", "./artifacts/app.zip"));

Task("Default").IsDependentOn("Test");

RunTarget(target);
```

`MSBuild`/`VSTest` resolve Visual Studio Build Tools on the agent. The packaging
step uses Cake's `Zip` (or 7-Zip via `Context.Tools.Resolve("7za.exe")` if a
specific archive format is required).
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/cake-build.md
git commit -m "docs(dotnet-fx48-legacy): add Cake build reference"
```

---

### Task 6: `gitlab-ci.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/gitlab-ci.md`

- [ ] **Step 1: Write the file**

````markdown
# GitLab CI — Cake on a Windows runner (net48)

net48 + `msbuild.exe` requires a **Windows** runner with Visual Studio Build
Tools. CI just invokes the Cake bootstrap. (Azure DevOps Pipelines is the
equivalent alternative — a `windows-latest` pool running the same `build.ps1`.)

```yaml
stages:
  - build

variables:
  CONFIGURATION: "Release"

build:
  stage: build
  tags:
    - windows            # runner tag pointing at a Windows + VS Build Tools host
  script:
    - powershell -ExecutionPolicy Bypass -File ./build.ps1 -Target Test -Configuration $CONFIGURATION
  artifacts:
    name: "$CI_PROJECT_NAME-$CI_COMMIT_SHORT_SHA"
    paths:
      - artifacts/
    expire_in: 2 weeks
  only:
    - main
    - merge_requests
```

Keep the build logic in Cake, not in CI YAML — the same `build.ps1 -Target …`
runs identically on a developer machine and on the runner.
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/gitlab-ci.md
git commit -m "docs(dotnet-fx48-legacy): add GitLab CI reference"
```

---

### Task 7: `nlog-config.md` reference

**Files:**
- Create: `.ai/references/dotnet-fx48-legacy/nlog-config.md`

- [ ] **Step 1: Write the file**

````markdown
# NLog.config baseline (net48)

Copy `NLog.config` to the host project; set **Copy to Output Directory =
PreserveNewest**. Use `ILogger`-style usage via `LogManager.GetCurrentClassLogger()`.

```xml
<?xml version="1.0" encoding="utf-8"?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      throwConfigExceptions="true">
  <targets>
    <!-- Console for self-host / dev. -->
    <target name="console" xsi:type="ColoredConsole"
            layout="${longdate}|${level:uppercase=true}|${logger}|${message} ${exception:format=ToString}" />
    <!-- Rolling file for Windows Service / IIS. -->
    <target name="file" xsi:type="File"
            fileName="${basedir}/logs/app.log"
            archiveAboveSize="10485760" maxArchiveFiles="10"
            layout="${longdate}|${level:uppercase=true}|${logger}|${message} ${exception:format=ToString}" />
  </targets>
  <rules>
    <logger name="*" minlevel="Info" writeTo="console,file" />
  </rules>
</nlog>
```

```csharp
private static readonly NLog.Logger Log = NLog.LogManager.GetCurrentClassLogger();
// ...
Log.Info("Started widget {WidgetId}", id);
```

Configure structured properties (`${event-properties}`) and an OTLP/JSON target
if the service ships logs to a collector. Never log secrets or full request bodies.
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add .ai/references/dotnet-fx48-legacy/nlog-config.md
git commit -m "docs(dotnet-fx48-legacy): add NLog.config reference"
```

---

### Task 8: The overlay `.ai/stacks/dotnet-fx48-legacy.md`

**Files:**
- Create: `.ai/stacks/dotnet-fx48-legacy.md`

Write the overlay below **verbatim** (it is already sanitized and links to the
Task 1–7 references). Match the single-file overlay style of `go.md`/`flutter.md`.

- [ ] **Step 1: Write the file**

````markdown
[//]: # (Stack overlay — loaded together with .ai/base-instructions.md for .NET Framework 4.8 legacy projects)

# .NET Framework 4.8 (Legacy) Stack Overlay

Applies on top of `.ai/base-instructions.md` for **existing .NET Framework 4.8
(`net48`) service projects** — the maintenance counterpart to the modern
`dotnet-blazor` / `dotnet-webapi` stacks. Use it for multi-project solutions that
expose a REST API on Nancy/OWIN, self-host in a Console/Windows Service and/or
IIS, build with Cake → `msbuild.exe`, and predate SDK-everywhere tooling.

Everything stack-agnostic — **SemVer, Conventional Commits, the changelog policy,
TDD, Clean Code, 12-Factor, branching, PR conventions, security baseline** — comes
from `base-instructions.md` and is **not** repeated here. This overlay states only
what is net48-specific or overrides the base.

Full tech-stack table: [`tech-stack.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/tech-stack.md)

---

## Tech Stack (summary)

`net48` · mixed SDK-style + classic `.csproj` · Nancy 2.x on OWIN/Katana
(self-host + IIS) · NLog · Newtonsoft.Json · Nancy TinyIoC · xUnit desktop runner
+ Moq + Shouldly + Nancy.Testing · Cake → `msbuild.exe` · GitLab CI on Windows ·
centralized `Directory.Build.props`.

---

## Solution & Project Layout

- Multi-project `.sln`; layer by assembly responsibility, not by technical tier:
  - `<Solution>.Core` — domain/business logic, no framework dependencies
  - domain libraries (`<Solution>.<Area>`) — one per bounded area
  - `<Solution>.Rest` — Nancy modules + bootstrapper (the REST surface)
  - `<Solution>.Rest.IIS` — thin IIS host (OWIN wiring + `web.config`)
  - `<Solution>.Host` — Console / Windows Service self-host
  - `<Module>.Tests` — one test project per library
  - `TestHelpers` — shared fakes/fixtures/builders
- Cross-assembly calls go through interfaces defined in `<Solution>.Core`.

---

## Project Styles & Packages

- A solution may mix **SDK-style** (`Sdk="Microsoft.NET.Sdk"` + `PackageReference`)
  and **classic** (`<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>` +
  `packages.config` + `<Reference HintPath>`) projects. **Both are valid** —
  don't bulk-convert classic → SDK-style unless explicitly asked.
- Prefer `PackageReference` for **new** projects; leave working `packages.config`
  projects as they are.
- Keep `AutoGenerateBindingRedirects` on; net48 needs binding redirects for
  transitive version conflicts.

---

## C# Conventions (net48)

- Use the latest C# language version the installed compiler allows on net48, but
  assume **no implicit usings** and **no nullable reference types** unless a
  project opts in — add `using` directives explicitly.
- `async`/`await` end-to-end; **never** `Task.Result` / `.GetAwaiter().GetResult()`
  (classic SynchronizationContext deadlocks). Use `ConfigureAwait(false)` in
  library code.
- `ILogger`-style logging via NLog — never `Console.WriteLine` outside a console
  entry point.
- Specific exception types; no generic `catch (Exception)` swallowing.
- No `dotnet` CLI assumptions — the build is `msbuild.exe` driven (see Build & CI).

---

## REST — Nancy on OWIN

- One `NancyModule` per resource area, mounted on a base path; bind request
  bodies with `this.Bind<T>()`; return JSON via `Response.AsJson` / `Negotiate`.
- Register dependencies in a custom `Bootstrapper` (TinyIoC).
- Shape errors centrally in the bootstrapper's `OnError` pipeline as a
  ProblemDetails-style JSON body — never leak stack traces.
- Self-host (Console / Windows Service) and IIS share one OWIN `Startup`.
- Alternative legacy REST flavour: **ASP.NET Web API 2 on OWIN** — same hosting
  model, controllers instead of modules.

Scaffold (module, bootstrapper, Startup, self-host, IIS): [`nancy-owin-host.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/nancy-owin-host.md)

---

## Logging, JSON, Config (overrides base)

- **Logging: NLog** (not Serilog) via `NLog.config`. Scaffold: [`nlog-config.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/nlog-config.md)
- **JSON: Newtonsoft.Json** (not System.Text.Json) — it is the Nancy/OWIN default
  and the ecosystem standard on net48.
- **Config: `app.config` / `web.config`** + `System.Configuration` (not
  `appsettings.json`). Keep secrets out of committed config — use environment
  variables or a deployed, untracked config transform.

---

## Testing

Base TDD rules (tests first, no test-editing to go green, full suite after
implementation) apply. Stack specifics:

- xUnit **desktop runner**; assertions with **Shouldly**, mocks with **Moq**,
  HTTP/endpoint tests with **Nancy.Testing**.
- Naming `MethodName_StateUnderTest_ExpectedBehavior`; `[Theory]` + `[InlineData]`
  over logic-in-`[Fact]`.
- Run tests through the Cake `Test` target (VSTest discovers net48 test
  assemblies). `dotnet test` works for SDK-style test projects only.

Layout + examples: [`xunit-desktop-test.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/xunit-desktop-test.md)

---

## Build & CI

- **Build: Cake** — `build.ps1` bootstrap → `build/build.cake` → full-framework
  **`msbuild.exe`** (restore → build → VSTest → package). Never `dotnet build` a
  classic project. Scaffold: [`cake-build.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/cake-build.md)
- **CI: GitLab CI on a Windows runner** (VS Build Tools) invoking `build.ps1`;
  Azure DevOps Pipelines is the equivalent alternative. Scaffold: [`gitlab-ci.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/gitlab-ci.md)
- Keep build logic in Cake, not CI YAML, so it runs identically locally.

---

## Versioning (stack binding)

Base rules (SemVer, Conventional Commits → bump mapping, changelog, git-cliff)
live in `base-instructions.md`. For this stack, only the **stamping mechanism**:

- **One version for the whole solution**, defined once in a repo-root
  `Directory.Build.props` (`<Version>` → `AssemblyVersion` / `FileVersion` /
  `InformationalVersion`). **Never** set a version in an individual `.csproj`.
- `Directory.Build.props` is auto-imported by `msbuild.exe` for **both**
  SDK-style and classic projects — no per-project edits.
- **net48 caveat:** classic projects with a hand-written `AssemblyInfo.cs` cause
  **CS0579 duplicate attribute** errors. Fix by setting `GenerateAssemblyInfo=true`
  and removing the version attributes from `AssemblyInfo.cs`, **or** by linking a
  single shared version file — value defined in exactly one place.

Scaffold + migration note: [`directory-build-props.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet-fx48-legacy/directory-build-props.md)

---

## 12-Factor Caveats

Base 12-Factor rules apply, but net48 service hosting diverges:

- Hosting is **Windows Service / IIS**, not containers — process model and
  config-via-env differ; bind config from environment variables where practical.
- Config lives in `app.config`/`web.config` transforms, not a flat env file —
  still keep secrets out of source.
- Logs go to NLog file/console targets on the host (no stdout-only container
  assumption); ship to a collector if one exists.

---

## Agent Guardrails (this stack)

In addition to the base guardrails:

- Build/test with **Cake / `msbuild.exe` / VSTest** — do **not** run `dotnet
  build` or `dotnet ef` against classic projects.
- Do **not** bulk-migrate classic `.csproj` → SDK-style, or `packages.config` →
  `PackageReference`, unless explicitly asked.
- Do not add NuGet packages or change the target framework without asking first.
- Set the version in `Directory.Build.props` only — never per-`.csproj`.

### Never generate (this stack)

- `dotnet build` / `dotnet ef` commands for classic projects
- System.Text.Json, Minimal API, top-level statements, or file-scoped namespaces
  in projects whose style doesn't support them (assume net48 classic unless the
  project is SDK-style)
- `Task.Result` / `.GetAwaiter().GetResult()` — always `await`
- A version number in an individual `.csproj`
- Serilog/`appsettings.json` wiring (this stack uses NLog + `app.config`)
````

- [ ] **Step 2: Scrub check**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 3: Size-budget check**

Run: `./scripts/check-claude-md-size.sh`
Expected: a table row `dotnet-fx48-legacy   …   ok` and overall exit 0. If it
reads `FAIL`, trim prose from the overlay (push detail into the references) until
it passes — do not raise `MAX_ASSEMBLED_BYTES`.

- [ ] **Step 4: Drift check (must stay clean — overlay is hand-authored)**

Run: `./scripts/build-stacks.sh && git diff --exit-code .ai/stacks/dotnet-*.md`
Expected: `build-stacks.sh` writes only `dotnet-blazor.md`/`dotnet-webapi.md`;
`git diff` exits 0 (the new overlay is untouched — it has no `_layers/` source).

- [ ] **Step 5: Commit**

```bash
git add .ai/stacks/dotnet-fx48-legacy.md
git commit -m "feat(stacks): add dotnet-fx48-legacy overlay (.NET Framework 4.8)"
```

---

### Task 9: Update `README.md`

**Files:**
- Modify: `README.md` — *Supported stacks* table, repository-layout comment block, single-file note

- [ ] **Step 1: Add the row to the *Supported stacks* table**

Find the table row for `dotnet-webapi` and add **after** it:

```markdown
| `dotnet-fx48-legacy` | `.ai/stacks/dotnet-fx48-legacy.md` | .NET Framework 4.8 (legacy) · mixed SDK-style + classic `.csproj` · Nancy + OWIN/Katana (self-host + IIS) · NLog · Newtonsoft.Json · xUnit-desktop + Moq + Shouldly · Cake → `msbuild.exe` · GitLab CI on Windows · centralized `Directory.Build.props` |
```

- [ ] **Step 2: Add to the repository-layout code block**

In the `.ai/` layout block, find the `go.md` line and add **after** it:

```
    go.md                       ← single-file overlay (no layer split)
    dotnet-fx48-legacy.md       ← single-file overlay (.NET Framework 4.8;
                                  hand-authored — no _layers/ entry, not generated)
```

- [ ] **Step 3: Add the no-`_layers` caution**

In the *Adding a new stack* → *Split overlay* subsection, after the line
**"Never edit the generated `.ai/stacks/<base>-<flavour>.md` files directly"**,
add:

```markdown
> **Note:** `dotnet-fx48-legacy.md` is intentionally a **single-file** overlay
> (like `flutter.md`/`go.md`) despite its `dotnet-` prefix. Do **not** create a
> `_layers/dotnet-fx48-legacy.md` — `build-stacks.sh` would then overwrite the
> hand-authored file. The `build-stacks-drift` check stays green because no such
> layer exists.
```

- [ ] **Step 4: Verify the table renders and links resolve**

Run: `grep -n "dotnet-fx48-legacy" README.md`
Expected: at least the three insertions above are present.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs(readme): list dotnet-fx48-legacy stack"
```

---

### Task 10: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Full scrub over all new files**

Run: `scrub`
Expected: `CLEAN`

- [ ] **Step 2: Size budget across all stacks**

Run: `./scripts/check-claude-md-size.sh`
Expected: every row `ok`, exit 0.

- [ ] **Step 3: Drift check**

Run: `./scripts/build-stacks.sh && git diff --exit-code .ai/stacks/dotnet-*.md`
Expected: exit 0, no diff.

- [ ] **Step 4: Confirm file set**

Run: `git status --porcelain && ls .ai/references/dotnet-fx48-legacy/`
Expected: working tree clean; 7 reference files present (`tech-stack`,
`directory-build-props`, `nancy-owin-host`, `xunit-desktop-test`, `cake-build`,
`gitlab-ci`, `nlog-config`).

- [ ] **Step 5: (Optional) sanity-check the assembled overlay link targets**

Run: `grep -oE 'dotnet-fx48-legacy/[a-z-]+\.md' .ai/stacks/dotnet-fx48-legacy.md | sort -u`
Expected: each linked reference filename exists under
`.ai/references/dotnet-fx48-legacy/`.

---

## Self-review against the spec

- **Overlay + references, single-file, no build-script change** → Tasks 1–9. ✔
- **Centralized `Directory.Build.props` versioning + CS0579 caveat** → Tasks 2 & 8. ✔
- **Defer SemVer/Conventional Commits to base (one-line deferral)** → Task 8
  "Versioning (stack binding)" opens with the base-deferral sentence. ✔
- **Sanitization (public repo)** → `scrub` gate on every task + Task 10. ✔
- **Size budget < 39 KB** → Task 8 Step 3 + Task 10 Step 2. ✔
- **Drift safety / no `_layers/` entry** → Task 8 Step 4, Task 9 Step 3, Task 10
  Step 3. ✔
- **Nancy centered, Web API 2 brief mention; GitLab CI ref + ADO note** → Tasks
  3, 6, 8. ✔
- **README updated** → Task 9. ✔
- **Out of scope (no `_partials`/`_layers`, no `justfile`, services-only)** —
  honored; no task introduces them. ✔
