# Directory.Build.props — global compiler settings

Place at repo root. Applies to all projects.

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <DebugType>embedded</DebugType>
    <DebugSymbols>true</DebugSymbols>
  </PropertyGroup>
</Project>
```

Add `<Version>` (single source of truth for assembly version) and any project-wide metadata (Company, Product, Copyright) as needed.
