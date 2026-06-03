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
