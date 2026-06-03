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
