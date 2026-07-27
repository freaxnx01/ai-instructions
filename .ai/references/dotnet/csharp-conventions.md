# C# conventions (.NET baseline)

Correctness rules that agents most often get wrong — nullable suppression, async
end-to-end, `CancellationToken` propagation, exception specificity — stay inline in the
stack overlay. This file holds the style and project-setup conventions.

## Style

- File-scoped namespaces always.
- `global using` for framework namespaces in each project.
- `record` types for DTOs and value objects.
- `sealed` by default on non-base classes.
- No `var` when the type is not obvious from the right-hand side.
- Prefer primary constructors (.NET 8+).

## Project setup

- **Central Package Management** via `Directory.Packages.props` — no versions in `.csproj`.
- `Directory.Build.props` at the repo root pins, mandatorily: `TargetFramework=net10.0`,
  `Nullable=enable`, `ImplicitUsings=enable`, `TreatWarningsAsErrors=true`,
  `EnforceCodeStyleInBuild=true`, `AnalysisLevel=latest-recommended`,
  `DebugType=embedded`, `DebugSymbols=true`.

Full file: [`directory-build-props.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/directory-build-props.md)

`DebugType=embedded` is why Release builds carry source file and line numbers in
production stack traces — never strip PDBs from a release or Docker build.
