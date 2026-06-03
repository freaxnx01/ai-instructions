# Design — `dotnet-fx48-legacy` stack overlay

**Date:** 2026-06-03
**Status:** Draft for review
**Repo:** `freaxnx01/ai-instructions` (public)

---

## Goal

Add a new stack overlay, `dotnet-fx48-legacy`, that gives AI agents the right
conventions when **maintaining existing .NET Framework 4.8 service projects** —
the kind that predate modern .NET (SDK-style everywhere, `dotnet` CLI, Alpine
containers, Serilog/System.Text.Json). It is the maintenance counterpart to the
modern `dotnet-blazor` / `dotnet-webapi` overlays.

The overlay's conventions are **derived from the patterns observed in a private
customer solution** (a net48 archive REST service), but the published artifact
must contain **zero business-specific identifiers** (see *Sanitization rules*).

---

## Reference shape (the kind of project this targets)

A multi-project `net48` solution that exposes a REST API and is observed to use:

- **TFM** `net48`, with a **mix of project styles** in the same solution:
  SDK-style csproj (`Sdk="Microsoft.NET.Sdk"` + `PackageReference`) **and**
  classic csproj (`<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>` +
  `packages.config` + `<Reference HintPath>`).
- **REST via Nancy 2.x on OWIN/Katana** — self-hosted through
  `Microsoft.Owin.Host.HttpListener` (Console / Windows Service) **and** an IIS
  host variant. Views via the Nancy SuperSimpleViewEngine (`.sshtml`). *Not*
  ASP.NET MVC / Web API.
- **NLog** for logging, **Newtonsoft.Json** for JSON, DI via Nancy **TinyIoC**.
- Shared MSBuild props imported by every project (legacy `Directory.Build.props`
  analogue): build matrix (Debug/Release × AnyCPU/x64/x86), strong-name signing,
  binding redirects, version metadata.
- **Tests**: xUnit **desktop runner**, **Moq**, **Shouldly**, **Nancy.Testing**,
  RestSharp — `packages.config`-based test projects, plus a shared test-helpers
  project.
- **Build via Cake** (`build.ps1` bootstrap → `build.cake`) driving
  full-framework **`msbuild.exe`** (not `dotnet build`), 7-Zip packaging.
- **CI: GitLab CI** running `powershell build.ps1` on a Windows runner.
- API exploration via a **Bruno** collection.

---

## Approach

**Single self-contained overlay** at `.ai/stacks/dotnet-fx48-legacy.md`, like
`flutter.md` / `go.md` — **not** a layer on the modern `_partials/dotnet-core.md`
(net48 shares almost nothing with it: no implicit usings, no nullable-by-default,
classic csproj, full-framework MSBuild, Windows hosting, no `dotnet` CLI).

The overlay stays lean and **links out** to full scaffolds under
`.ai/references/dotnet-fx48-legacy/` (same pattern as `.ai/references/dotnet/*`).
Linking out keeps the overlay under the **assembled-size ceiling**: a consumer's
`CLAUDE.md` = sync header + `base-instructions.md` (≈14.3 KB) + one stack overlay
must stay **< 39 KB** (`scripts/check-claude-md-size.sh`). Target overlay size
**≤ ~24 KB**. Reference files are GitHub links, not assembled in, so they don't
count toward the budget.

**No build-script / CI changes.** The name matches the `dotnet-*` glob, but
because there is **no `_layers/dotnet-fx48-legacy.md`**, `scripts/build-stacks.sh`
never regenerates it and the `build-stacks-drift` check (`git diff --exit-code
.ai/stacks/dotnet-*.md`) stays green. This must be documented so nobody later
adds a `_layers/` entry that would overwrite the hand-authored file.

### Approaches considered

- **A — Single-file overlay only** (no references). Matches flutter/go exactly;
  fewest files. Rejected: net48 needs real scaffolds (shared props, Nancy/OWIN
  host, Cake) that would blow the size budget if inlined.
- **B — Single-file overlay + reference scaffolds** *(chosen)*. Lean overlay,
  depth lives in linked references; mirrors the modern dotnet stack.
- **C — Split `_partials` + `_layers`** for multiple legacy flavours. Rejected as
  premature (YAGNI): only one flavour exists today.

---

## Sanitization rules (public-repo safety)

The overlay and all references are **public**. They must contain only generic,
reusable technology conventions and public OSS names — **no business data**.

**Scrub list (must NOT appear anywhere):** customer / company / product names
and their domains; private NuGet package and feed names; internal assembly /
project / namespace names; internal service or domain terms; the source repo's
host URL; strong-name key filenames; real version numbers; support URLs;
product-specific dependencies.

**Allowed:** public OSS tech names (net48, Nancy, OWIN/Katana, NLog,
Newtonsoft.Json, xUnit, Moq, Shouldly, Nancy.Testing, RestSharp, Cake, MSBuild,
7-Zip, GitLab CI) and generic patterns.

**Placeholders only** in every example: `<Solution>`, `<Solution>.Core`,
`<Solution>.Rest`, `<Solution>.Host`, `<Module>.Tests`, `Acme.Service`,
`Example Co`, version `1.0.0`. Same placeholder convention the existing overlays
use (`<ModuleName>`, `<project-name>`).

A self-review pass greps the finished files against the scrub list before commit.

---

## Overlay structure (`.ai/stacks/dotnet-fx48-legacy.md`)

Standard single-file header
(`[//]: # (Stack overlay — loaded together with .ai/base-instructions.md for
.NET Framework 4.8 legacy projects)` + `# .NET Framework 4.8 (Legacy) Stack
Overlay`), then sections that **override base only where net48 diverges**:

1. **Tech Stack table** — the stack listed above.
2. **Solution / project layout** — multi-project `.sln`; layered assemblies
   (`<Solution>.Core`, domain libraries, `<Solution>.Rest`,
   `<Solution>.Rest.IIS`, `<Solution>.Host.Console` / Windows Service);
   `<Module>.Tests`; shared test-helpers; scratch/playground projects.
3. **Project styles & packages** — keep classic `packages.config` +
   `<Reference HintPath>` when it works; migrate to SDK-style `PackageReference`
   only when asked; binding redirects (`AutoGenerateBindingRedirects`).
   Links → `directory-build-props.md`.
4. **C# / language conventions for net48** — usable C# language version; **no**
   implicit usings, **no** nullable-by-default; async-over-sync hazards;
   `ConfigureAwait(false)` in library code; no `dotnet` CLI assumptions.
5. **REST via Nancy + OWIN** — modules, bootstrapper/DI (TinyIoC), self-host
   (Console / Windows Service) vs IIS host, `.sshtml` views, ProblemDetails-style
   error shaping. Brief note: ASP.NET **Web API 2 / OWIN** is the alternative
   legacy REST flavour. Links → `nancy-owin-host.md`.
6. **Logging / JSON / Config** — **NLog** (override base's Serilog),
   **Newtonsoft.Json** (override System.Text.Json), `app.config` / `web.config`
   + `System.Configuration` (override appsettings.json). Links → `nlog-config.md`.
7. **Testing** — xUnit **desktop runner** + Moq + Shouldly + Nancy.Testing
   layout. Links → `xunit-desktop-test.md`.
8. **Build & CI** — Cake (`build.ps1` → `build.cake`) → `msbuild.exe`, 7-Zip
   packaging; GitLab CI on a Windows runner (note: Azure DevOps Pipelines is the
   alternative). Overrides base's generic CI outline. Links → `cake-build.md`,
   `gitlab-ci.md`.
9. **Versioning — centralized `Directory.Build.props`** *(see below)*.
10. **12-Factor caveats** — which factors don't map cleanly (Windows
    Service/IIS hosting, file-based config, no containers).
11. **Agent guardrails + "Never generate"** — don't run `dotnet build` /
    `dotnet ef`; don't bulk-migrate classic → SDK csproj unasked; don't add
    NuGet packages or change the TFM unasked; don't inject modern-only APIs
    (System.Text.Json, Minimal API, top-level statements, file-scoped namespaces
    where the project style doesn't support them) into net48.

### Versioning — centralized via root `Directory.Build.props`

- **One source of truth:** a repo-root `Directory.Build.props` defines the
  version **once** (`<Version>` → drives `AssemblyVersion`, `FileVersion`,
  `InformationalVersion`). Every project in the solution inherits the **exact**
  version; **never** set a version in an individual `.csproj`. (Aligns with the
  modern `dotnet-core` partial's single-`<Version>` rule.)
- **Why it works on net48:** modern `msbuild.exe` (VS2017+) auto-imports
  `Directory.Build.props` for **both** SDK-style **and** classic `.csproj`, so
  even old-style projects pick up the central version with no per-project edits.
- **net48 caveat (must be called out):** classic projects that still ship a
  hand-written `Properties/AssemblyInfo.cs` will hit **CS0579 duplicate
  attribute** because the generated assembly attributes collide with the ones in
  `AssemblyInfo.cs`. Resolution: either set `GenerateAssemblyInfo=true` and
  remove the `[AssemblyVersion]` / `[AssemblyFileVersion]` /
  `[AssemblyInformationalVersion]` attributes from `AssemblyInfo.cs`, or keep a
  single shared generated version file — but define the value in exactly one
  place.
- **Supersedes the legacy manual-import pattern:** `Directory.Build.props`
  replaces a manually-`<Import>`ed shared props file for versioning. A shared
  props file may remain only for genuinely build-matrix-specific settings
  (platform targets) if a project still needs the explicit import.

---

## Reference scaffolds (`.ai/references/dotnet-fx48-legacy/`)

Markdown-wrapped scaffolds, same shape as `.ai/references/dotnet/*.md` (title +
prose + fenced code), all sanitized with placeholder names:

- `tech-stack.md` — full tech-stack table.
- `directory-build-props.md` — centralized version (single `<Version>` for all
  assemblies) + shared compiler/signing settings; net48 `AssemblyInfo.cs`
  duplicate-attribute caveat; migration note from a manually-imported shared
  props file.
- `nancy-owin-host.md` — Nancy module + bootstrapper (TinyIoC) + OWIN `Startup`
  + self-host (Console / Windows Service) + IIS host.
- `xunit-desktop-test.md` — test project layout + example (xUnit desktop + Moq +
  Shouldly + Nancy.Testing).
- `cake-build.md` — `build.cake` skeleton + `build.ps1` bootstrap driving
  `msbuild.exe`.
- `gitlab-ci.md` — Cake-driven `.gitlab-ci.yml` on a Windows runner.
- `nlog-config.md` — `NLog.config` baseline.

---

## Repo edits

- **README.md** — add a `dotnet-fx48-legacy` row to the *Supported stacks* table
  and to the repository-layout comment block; add a one-line note that it is a
  **single-file overlay** that must **not** receive a `_layers/` entry (the
  generator would overwrite it).

No change to `scripts/build-stacks.sh`, `scripts/check-claude-md-size.sh`, or the
`build-stacks-drift` workflow. `/sync-ai-instructions` discovers the stack by
listing `.ai/stacks/*.md`, so adding the file is sufficient.

---

## Out of scope (YAGNI)

- No split `_partials` / `_layers` for this stack.
- No `build-stacks.sh` change.
- No WinForms / WPF / WCF depth — this overlay targets net48 **services**.
- No `justfile` (legacy build is Cake-driven).

---

## Verification

- `scripts/check-claude-md-size.sh` passes (assembled `dotnet-fx48-legacy`
  CLAUDE.md < 39 KB).
- Scrub-list grep over the overlay + all references returns **no** business
  identifiers.
- `./scripts/build-stacks.sh` followed by `git diff --exit-code
  .ai/stacks/dotnet-*.md` is clean (no drift).
- README *Supported stacks* table renders with the new row.
