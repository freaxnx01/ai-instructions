# Essential Make targets — canonical names + descriptions

Projects on the .NET stack ship a repo-root `Makefile` standardizing common commands. Recipe bodies may use project-local variables (`$(SLN)`, `$(API_DIR)`, `$(PROPS_FILE)`, `$(COMPOSE)`) but the **target names below are canonical** — do not rename them.

A reference Makefile lives at `.ai/examples/dotnet/Makefile` — copy it to your repo root and customize the top-of-file variables. Host/tool/project-specific targets (`run-edge`, `release-notes`, `package`) ship as stubs with per-OS examples in comments.

Document each target with an inline `## <description>` comment and expose a `help` target that greps them.

## Build & run
- `build` — build the solution in Release mode
- `watch` — run the API with hot reload (`dotnet watch`)
- `run-edge` — start the frontend and open it in the developer's preferred browser
  *Recipe is host-specific (Windows/WSL: powershell + msedge; macOS: `open -a Safari`; Linux: `xdg-open`). Standardize the target name; leave the body to each project.*

## Testing
- `test` — run every test project in the solution
- `test-unit` — run unit test projects only (iterate a `TEST_UNIT_PROJECTS` list)
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
- `version-set V=X.Y.Z` — set version explicitly
- `bump-major` / `bump-minor` / `bump-patch` — SemVer bumps via `sed` on `Directory.Build.props`
- `bump-auto` — derive next version from Conventional Commits via `git-cliff --bumped-version`; refuse major bumps (require explicit `bump-major`)

## Release
- `changelog` — `git-cliff --output CHANGELOG.md`
- `release-notes` — generate user-friendly release notes for the current version
  *Recipe is tool-specific (Claude Code, Copilot CLI, llm CLI, OpenAI, hand-rolled). Standardize the target name; leave the body to each project.*
- `release` — tag `v$(VERSION)`, regenerate `CHANGELOG.md`, invoke `release-notes`, commit, tag (no auto-push)
- `release-auto` — `bump-auto` + `release` in one step
- `push-release` — `git push origin main "v$(VERSION)"` (run only after `release` succeeds)
- `package` — build a distributable artifact (ZIP / tarball / image) and deliver to the project's drop location
  *Recipe is project-specific (artifact format, drop location, signing). Standardize the target name; leave the body to each project.*

## Cleanup
- `clean` — remove `bin/`, `obj/`, `publish/` trees and `./coverage/`
