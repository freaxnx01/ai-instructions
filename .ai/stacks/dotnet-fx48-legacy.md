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
  library code so awaited continuations don't re-enter that captured context.
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
  assemblies). `dotnet test` works for **fully** SDK-style test projects (SDK format + `PackageReference`) only.

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
live in `base-instructions.md`. For this stack, only the **stamping mechanism** —
goal: **one version value, every assembly in the solution identical**. **Never**
set a version in an individual `.csproj`.

- **Define the version once** in a repo-root `Directory.Build.props` (`<Version>`).
  It is auto-imported by **MSBuild 15+ (VS 2017+/`msbuild.exe`)** for every project
  — confirm the build agent is VS Build Tools 2017 or newer.
- **SDK-style projects** stamp `<Version>` into `AssemblyVersion` / `FileVersion` /
  `InformationalVersion` automatically (`GenerateAssemblyInfo` default-on).
- **Classic (non-SDK) projects ignore the MSBuild `<Version>`** — assembly-info
  generation is SDK-only, so their version still comes from `AssemblyInfo.cs`. To
  put them on the same value, **link one shared `SharedAssemblyInfo.cs`** into every
  project and strip the version attributes from each project's own `AssemblyInfo.cs`
  (set `GenerateAssemblyInfo=false` on SDK-style projects so they share it too).
- **CS0579 "duplicate attribute"** = the version is declared twice (generated +
  hand-written). Define each attribute in exactly one place.

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
- Detect the REST flavour from existing code (Nancy modules vs. `ApiController`) before adding endpoints — don't mix Nancy and Web API 2 in one project.

### Never generate (this stack)

- `dotnet build` / `dotnet ef` commands for classic projects
- System.Text.Json, Minimal API, top-level statements, or file-scoped namespaces
  in projects whose style doesn't support them (assume net48 classic unless the
  project is SDK-style)
- `Task.Result` / `.GetAwaiter().GetResult()` — always `await`
- A version number in an individual `.csproj`
- Serilog/`appsettings.json` wiring (this stack uses NLog + `app.config`)
