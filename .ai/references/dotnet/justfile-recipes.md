# Essential just recipes — canonical names + descriptions

Projects on the .NET stack ship a repo-root `justfile` standardizing common commands using [casey/just](https://github.com/casey/just). Recipe bodies may use project-local variables (`sln`, `api_dir`, `props_file`, `compose`) but the **recipe names below are canonical** — do not rename them.

A reference `justfile` lives at `.ai/examples/dotnet/justfile` — copy it to your repo root and customize the top-of-file variables. Host/tool/project-specific recipes (`run-edge`, `release-notes`, `package`) ship as stubs with per-OS examples in comments.

Document each recipe with a leading `# <description>` comment line. The default recipe runs `just --list --unsorted` so `just` with no args prints the documented set.

## Why `just` (vs `make`)

- Native Windows binary — no MSYS / WSL required (`winget install Casey.Just`, `scoop install just`)
- Per-recipe shells via shebangs: a recipe can declare `#!/usr/bin/env pwsh` and the whole body runs as one PowerShell script. Variables persist across lines; no `\` continuations, no `$$` escaping
- `[unix]` / `[windows]` / `[macos]` / `[linux]` recipe attributes split per-OS implementations cleanly — replaces the "canonical target, body is host-specific" stub pattern Make can't express
- Recipe parameters are first-class: `just version-set 1.2.3` not `make version-set V=1.2.3`
- `just --list` / `just` is free help — no awk one-liner
- Recipe dependencies without `$(MAKE)` recursion: `release-auto: bump-auto release`

## Install

Requires **just ≥ 1.20** (for `[group(...)]` attributes).

```bash
# Linux
sudo apt install just         # or: cargo install just
# macOS
brew install just
# Windows
winget install Casey.Just     # or: scoop install just
```

CI (GitHub Actions): `extractions/setup-just@v2`.

## Cross-OS authoring rules

- **Multi-line Windows recipes need a `#!/usr/bin/env pwsh` shebang.** Without one, just invokes `pwsh` once per line and shell variables (`$cur`, `$xml`, …) do not persist. Single-line Windows recipes can omit the shebang and rely on the `set windows-shell` directive.
- **Unix recipes use portable POSIX tools** (`sed -n`, `mktemp`, `mv`) — not `grep -oP` or `sed -i`. This way the same recipe runs on Linux (GNU) and macOS (BSD) without coreutils.
- **PowerShell output for piping**: use `Write-Output` (not `Write-Host`) when the value may be consumed by `$(just <recipe>)` — `Write-Host` writes to the host stream and is invisible to capture.

## Build & run

- `build` — build the solution in Release mode
- `watch` — run the API with hot reload (`dotnet watch`)
- `run-edge` — start the frontend and open it in the developer's preferred browser
  *Body is host-specific. Ship `[unix]` + `[windows]` variants with the canonical recipe name; bodies use per-OS launchers (Windows: `pwsh` + `Start-Process msedge`; macOS: `open -a Safari`; Linux: `xdg-open`).*

## Testing

- `test` — run every test project in the solution
- `test-unit` — run unit test projects only (iterate a `test_unit_projects` list)
- `test-coverage` — run tests with `--collect:"XPlat Code Coverage" --results-directory ./coverage`

## Docker (Compose)

- `docker-run` — `compose up --build` in the foreground
- `up` — `compose up -d --build`
- `down` — `compose down`
- `logs` — `compose logs -f`
- `rebuild` — `down` + `up`

## Quality

- `lint` — `dotnet format --verify-no-changes`
- `outdated` — `dotnet list package --outdated`
- `vuln` — `dotnet list package --vulnerable --include-transitive`

## Versioning (single source of truth: `Directory.Build.props` → `<Version>`)

- `version` — print current version
- `version-set 1.2.3` — set version explicitly (positional arg, no `V=` prefix)
- `bump-major` / `bump-minor` / `bump-patch` — SemVer bumps. Unix recipes use `sed`; Windows recipes use the PowerShell `[xml]` parser
- `bump-auto` — derive next version from Conventional Commits via `git-cliff --bumped-version`; refuse major bumps (require explicit `bump-major`)

## Release

- `changelog` — `git-cliff --output CHANGELOG.md`
- `release-notes` — generate user-friendly release notes for the current version
  *Body is tool-specific. Standardize the recipe name; leave the body to each project (Claude Code, Copilot CLI, llm CLI, OpenAI, hand-rolled).*
- `release` — tag `v$(version)`, regenerate `CHANGELOG.md`, invoke `release-notes`, commit, tag (no auto-push)
- `release-auto` — `bump-auto` + `release` in one step (uses native recipe deps, not `$(MAKE)` recursion)
- `push-release` — `git push origin main "v$(version)"` (run only after `release` succeeds)
- `package` — build a distributable artifact (ZIP / tarball / image) and deliver to the project's drop location
  *Body is project-specific (artifact format, drop location, signing). Standardize the recipe name; leave the body to each project.*

## Cleanup

- `clean` — remove `bin/`, `obj/`, `publish/` trees and `./coverage/`. Unix uses `find -exec`; Windows uses `Get-ChildItem -Recurse | Remove-Item`.
