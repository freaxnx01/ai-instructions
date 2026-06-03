# Directory.Build.props — centralized version & shared settings (net48)

Place at the **repo root** (next to the `.sln`). MSBuild **15+ (VS 2017+/
`msbuild.exe`)** auto-imports it for **every** project in the tree — both
SDK-style and classic `.csproj` — so shared MSBuild *properties* and metadata are
defined in one place with no per-project `<Import>`. Confirm the build agent runs
VS Build Tools 2017 or newer; older toolchains (MSBuild 14 / VS 2015) do not
auto-import it.

**One version value for the whole solution. Never set a version in an individual
`.csproj`.** How the value reaches each assembly depends on the project style —
see *Stamping the version across project styles* below.

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

    <DebugType>full</DebugType>
    <DebugSymbols>true</DebugSymbols>
    <AutoGenerateBindingRedirects>true</AutoGenerateBindingRedirects>
  </PropertyGroup>
</Project>
```

## Stamping the version across project styles

The props file is imported everywhere, but only **SDK-style** projects turn the
`<Version>` MSBuild property into assembly attributes.

- **SDK-style projects** (`Sdk="Microsoft.NET.Sdk"`): `GenerateAssemblyInfo` is on
  by default, so `<Version>` is stamped into `AssemblyVersion` / `FileVersion` /
  `InformationalVersion` automatically — nothing else to do.
- **Classic (non-SDK) projects**: assembly-info generation is an SDK-only feature,
  so these projects **ignore** the MSBuild `<Version>` property. Their version
  still comes from `[assembly: AssemblyVersion(...)]` in
  `Properties/AssemblyInfo.cs`. Setting `<Version>` in `Directory.Build.props`
  alone will **not** change a classic assembly's version.

### Getting one identical version into classic (and mixed) solutions

Link a single shared version file into every project and let it carry the
attributes:

```csharp
// SharedAssemblyInfo.cs at the repo root — the one place the version lives.
using System.Reflection;

[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyInformationalVersion("1.0.0")]
```

```xml
<!-- In every project (classic and SDK-style): -->
<ItemGroup>
  <Compile Include="..\SharedAssemblyInfo.cs">
    <Link>Properties\SharedAssemblyInfo.cs</Link>
  </Compile>
</ItemGroup>
```

Then:

- **Classic projects:** remove the `[AssemblyVersion]` / `[AssemblyFileVersion]` /
  `[AssemblyInformationalVersion]` lines from each project's own `AssemblyInfo.cs`
  (keep the non-version attributes), leaving the shared file as the only source.
- **SDK-style projects:** set `<GenerateAssemblyInfo>false</GenerateAssemblyInfo>`
  so the SDK stops generating its own attributes and uses the linked shared file
  too — now every assembly, classic and SDK, carries the identical version.

> If you keep `<Version>` in `Directory.Build.props` for SDK-style stamping **and**
> a shared file for classic, make sure both hold the same value (or derive the
> shared file's literal from `<Version>` in your release tooling) so there is still
> one number to bump.

## CS0579 "duplicate attribute"

This error means an assembly attribute is defined twice: typically an SDK-style
project generating attributes (`GenerateAssemblyInfo=true`, the default) **while**
a hand-written `AssemblyInfo.cs` (or a linked shared file) also declares them. Fix
by defining each attribute in exactly one place — either strip the duplicates from
`AssemblyInfo.cs`, or set `GenerateAssemblyInfo=false` and rely on the source file.

## Migration note

If the solution currently uses a manually-`<Import>`ed shared props file (e.g. a
`Project.configuration` imported by each `.csproj`), `Directory.Build.props`
supersedes it for shared settings. Keep the imported file only for genuinely
build-matrix-specific settings (per-`Platform` `PlatformTarget`, `OutputPath`)
that you don't want auto-applied to every project.

> Policy (SemVer, Conventional-Commits → bump mapping, changelog, git-cliff)
> lives in `base-instructions.md`. This file is only the net48 stamping mechanism.
