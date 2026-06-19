# AI Coding Agent Instructions

Canonical, stack-agnostic AI agent instructions with per-stack overlays. Each project loads **base + exactly one stack** so agent context stays clean — a Flutter session never sees .NET content, and vice versa.

## TL;DR

- **What this repo is:** a Markdown + Bash *content* repo. It produces instruction files for *other* projects — it is not itself an app. (Working on the sources? See the root [`CLAUDE.md`](CLAUDE.md).)
- **Composition, not references:** a consuming project's `CLAUDE.md` / `copilot-instructions.md` / `SKILL.md` are assembled from `base-instructions.md` **+ exactly one** `stacks/<stack>.md` **+** shared skills, with the **full content inlined** — no `@imports` or "see other file" pointers. All indirection happens at **build/sync time**, so the output is flat and self-contained.
- **Consume it:** run `/sync-ai-instructions <stack>` from your project (Option A), or copy a ready-made rendering from `.ai/examples/<stack>/` (Option B). Editing an overlay here changes nothing downstream until a project re-syncs.
- **Generated vs. source:** `.ai/stacks/dotnet-blazor.md` and `dotnet-webapi.md` are **generated** — never edit them. Edit `_partials/dotnet-core.md` (shared) or `_layers/dotnet-*.md` (per-flavour), then run `./scripts/build-stacks.sh`. Single-file overlays (`flutter.md`, `go.md`, `ci.md`, `dotnet-fx48-legacy.md`) are edited directly.
- **When `build-stacks.sh` runs:** manually, after you edit a partial/layer; and in CI (`build-stacks-drift`) on PRs touching `.ai/stacks/**` and on push to `main` — there it runs as a **drift check** (regenerate, then fail if the committed flat files differ). CI never commits regenerated files back, so the generated files in the repo are always the product of a manual run.

## Repository layout

```
.ai/
  base-instructions.md          ← stack-agnostic conventions (SemVer, Conventional
                                  Commits, TDD, Clean Code, 12-Factor, branching,
                                  git-cliff, Keep a Changelog, UI phase gates)
  stacks/
    dotnet-blazor.md            ← generated: dotnet-core + Blazor layer
    dotnet-webapi.md            ← generated: dotnet-core + WebAPI layer
    flutter.md                  ← single-file overlay (no layer split)
    go.md                       ← single-file overlay (no layer split)
    dotnet-fx48-legacy.md       ← single-file overlay (.NET Framework 4.8;
                                  hand-authored — no _layers/ entry, not generated)
    _partials/
      dotnet-core.md            ← shared .NET conventions (C#, EF, Docker,
                                  logging, justfile, CI, security, basic
                                  Minimal API + ProblemDetails)
    _layers/
      dotnet-blazor.md          ← Blazor + MudBlazor + bUnit + Playwright
                                  + UI workflow + UI-specific localization
      dotnet-webapi.md          ← REST conventions (versioning, auth, status
                                  codes, idempotency, ETag, rate limiting,
                                  CORS, HTTP logging, LRO, OpenAPI/Scalar,
                                  k6, Kiota, Bruno, integration tests)
  skills/
    commit.md           · push.md
    ui-brainstorm.md    · ui-flow.md · ui-build.md · ui-review.md
  references/                     ← long code blocks / checklists pulled out of overlays
  examples/
    dotnet/justfile               ← sample artifacts referenced by overlays
    dotnet-blazor/                ← pre-assembled dotnet-blazor rendering (Option B
                                    template: CLAUDE.md, SKILL.md, copilot-instructions.md)

scripts/
  build-stacks.sh               ← concatenates _partials/dotnet-core.md +
                                  _layers/dotnet-*.md into the flat
                                  stacks/dotnet-*.md files

.claude/commands/               ← Claude Code slash-command wrappers for the skills above

workflows/                      ← cross-cutting workflow docs that span repos
  personal-dev-workflow.md      ← brainstorm↔CC handoff, repo roles, content placement

CLAUDE.md                       ← agent context for working in THIS repo (content + build
                                  script) — not a stack rendering
```

`sync-ai-instructions` and `release-notes` used to live here as `.ai/skills/*.md`; they are now standalone plugins in the `freaxnx01/agent-skills` / `freaxnx01/claude-code-plugins` marketplaces and are available globally once installed.

The flat files under `.ai/stacks/` are the **published** overlays — that is what `sync-ai-instructions` and any direct-fetch consumer pulls. The split source under `_partials/` and `_layers/` exists so the .NET stacks don't duplicate their shared content. A CI check (`build-stacks-drift`) fails any PR where the flat files have drifted from the sources.

New stacks that don't share content with an existing stack (e.g. `flutter.md`, `node.md`) live as a single self-contained file under `.ai/stacks/`. Stacks that share a baseline split into a `_partials/<base>.md` plus one `_layers/<base>-<flavour>.md` per published overlay. Nothing else in the repo changes when a stack is added.

### Breaking change in this revision

The single overlay `dotnet.md` has been renamed to `dotnet-blazor.md`, with its content refactored through a `_partials/dotnet-core.md` + `_layers/dotnet-blazor.md` split so additional .NET flavours can be added without duplicating the shared conventions. Projects that previously ran `/sync-ai-instructions dotnet` should:

1. Run `/sync-ai-instructions dotnet-blazor`
2. Delete the old `.ai/stacks/dotnet.md` from the project — the sync skill won't remove it automatically

## How to use this repo in a project

### Option A — `/sync-ai-instructions` skill (recommended)

Install once:

```
/plugin marketplace add freaxnx01/agent-skills
/plugin install sync-ai-instructions@freax-agent-skills
/reload-plugins
```

Then from inside your target project (not this repo):

```
/sync-ai-instructions dotnet
```

The skill fetches `base-instructions.md`, `stacks/dotnet.md`, and all shared skill files from `main`, assembles them into the target project's `CLAUDE.md`, `.github/copilot-instructions.md`, `SKILL.md`, and writes the stack overlay to `.ai/stacks/dotnet.md`. The target project ends up with **only** the stack it uses.

Idempotent: safe to run for first-time setup **or** to refresh an already-initialized project. If `$ARGUMENTS` is omitted, the skill lists available stacks and asks. It refuses to fall back silently on a missing stack.

### Option B — copy the template (.NET Blazor only)

`.ai/examples/dotnet-blazor/` holds the pre-assembled rendering for a .NET Blazor project — `CLAUDE.md`, `copilot-instructions.md`, and `SKILL.md`. If you want that stack, copy those files into your project root (`copilot-instructions.md` → `.github/copilot-instructions.md`), fill in the TODO markers in `CLAUDE.md` (project name, purpose), and you're done.

> These are a **sample output**, not this repo's own context. The repo root `CLAUDE.md` and `.github/copilot-instructions.md` describe how to work on the instruction sources themselves. Prefer Option A (`/sync-ai-instructions`) — it always fetches the current `main` rendering, whereas these files are only as fresh as the last regeneration.

## Supported stacks

| Stack | File | Covers |
|---|---|---|
| `dotnet-blazor` | `.ai/stacks/dotnet-blazor.md` | .NET 10 · ASP.NET Core · Blazor + MudBlazor · EF Core · xUnit / bUnit / Playwright · Serilog + OpenTelemetry · Alpine Docker |
| `dotnet-webapi` | `.ai/stacks/dotnet-webapi.md` | .NET 10 · ASP.NET Core REST API · Asp.Versioning.Http · ProblemDetails · OpenAPI + Scalar · JWT / API key / pass-through auth · `WebApplicationFactory` + Testcontainers · Bruno · k6 · Kiota |
| `dotnet-fx48-legacy` | `.ai/stacks/dotnet-fx48-legacy.md` | .NET Framework 4.8 (legacy) · mixed SDK-style + classic `.csproj` · Nancy + OWIN/Katana (self-host + IIS) · NLog · Newtonsoft.Json · xUnit-desktop + Moq + Shouldly · Cake → `msbuild.exe` · GitLab CI on Windows · centralized `Directory.Build.props` |
| `flutter` | `.ai/stacks/flutter.md` | Flutter / Dart |
| `go` | `.ai/stacks/go.md` | Go (modules) · Cobra CLI · Bubble Tea / Bubbles / Lipgloss TUI · stdlib `net/http` ServeMux · `log/slog` · stdlib `testing` + hand-rolled fakes · `golangci-lint` · `govulncheck` · ldflags version injection |
| `ci` | `.ai/stacks/ci.md` | Bash · GitHub Actions reusable workflows + composite actions · `actionlint` + `shellcheck` · `act` |

To add a new stack: see *Adding a new stack* below.

## Adding a new stack

### Single-file overlay (no shared baseline)

For a stack that doesn't share content with an existing one, create `.ai/stacks/<name>.md` directly. Cover at minimum:

- Tech-stack table
- Architecture conventions specific to the ecosystem
- Language conventions (style, naming, what to never generate)
- Testing framework choices, project layout, example templates
- UI component-library preferences (if applicable)
- Build / run / test commands
- Container / deployment specifics
- Stack-specific agent guardrails

Keep anything stack-agnostic (SemVer, Conventional Commits, TDD principles, Clean Code, 12-Factor, branching) in `base-instructions.md`, not in the overlay.

### Split overlay (shared baseline + flavour layer)

When a stack has multiple flavours that share substantial content (currently: the .NET family), split the source:

```
.ai/stacks/
  _partials/<base>.md           ← shared content
  _layers/<base>-<flavour>.md   ← per-flavour delta
  <base>-<flavour>.md           ← GENERATED — flat overlay consumers fetch
```

After editing the partial or any layer, run:

```bash
./scripts/build-stacks.sh
```

This concatenates each `_partials/<base>.md` + `_layers/<base>-<flavour>.md` pair into the corresponding `.ai/stacks/<base>-<flavour>.md`. The CI workflow `build-stacks-drift` fails any PR that touches the source files but forgets to commit the regenerated flat files.

**Never edit the generated `.ai/stacks/<base>-<flavour>.md` files directly** — changes will be overwritten on the next regen.

> **Note:** `dotnet-fx48-legacy.md` is intentionally a **single-file** overlay
> (like `flutter.md`/`go.md`) despite its `dotnet-` prefix. Do **not** create a
> `_layers/dotnet-fx48-legacy.md` — `build-stacks.sh` would then overwrite the
> hand-authored file. The `build-stacks-drift` check stays green because no such
> layer exists.

The build script currently handles `dotnet-*` only. Extending it to a second split family (e.g. `node-*`) is a one-line change to its glob.

### Size budget (CI + local hook)

The assembled `CLAUDE.md` a consumer ends up with (`base-instructions.md` + one stack overlay) must stay under **39,000 bytes** — that's 1k below Claude Code's 40k performance warning. The check lives in `scripts/check-claude-md-size.sh` and runs in the `build-stacks-drift` workflow.

For fail-fast feedback locally, enable the bundled pre-commit hook once per clone:

```bash
git config core.hooksPath scripts/git-hooks
```

The hook runs the size check only when a commit touches `.ai/base-instructions.md`, anything under `.ai/stacks/`, or either build/check script. Use `git commit --no-verify` to bypass for unrelated commits if needed.

## Keeping a project in sync

When `base-instructions.md` or the stack overlay changes, consumers re-run `/sync-ai-instructions <stack>` to regenerate their `CLAUDE.md` / copilot / SKILL files. The skill reports the source commit SHA so you know which version of the instructions is in use.

## Workflows

Beyond per-stack agent instructions, this repo also hosts cross-cutting workflow docs under `workflows/` — practices that span multiple repos rather than belonging to any single stack. The current entry, [`workflows/personal-dev-workflow.md`](workflows/personal-dev-workflow.md), defines repo roles (consumer vs. implementer), content placement across the personal toolchain, and the brainstorm→CC handoff pattern.

## Document types in a project using this workflow

A project that adopts the personal dev workflow ends up with a small, predictable set of document types. Each has a distinct purpose and lifecycle — don't conflate them.

| Document | Lives at | Purpose | Lifecycle |
|---|---|---|---|
| **`CLAUDE.md`** / `.github/copilot-instructions.md` / `SKILL.md` | Repo root | Agent session-priming context. Tool-specific framing of the same content. **Assembled by `/sync-ai-instructions` — never hand-edit** (changes get wiped on next sync). | Regenerated on every sync. |
| **`.ai/base-instructions.md`** | Sub-folder | Source of truth for stack-agnostic conventions (TDD, Conventional Commits, Clean Code, 12-Factor). Copied into each project by sync. | Updated upstream in this repo. |
| **`.ai/stacks/<stack>.md`** | Sub-folder | Source of truth for stack-specific conventions (Blazor, Flutter, CI, etc.). Exactly one per project. | Updated upstream in this repo. |
| **`WORKFLOW-ROLE.md`** | Repo root | This repo's role in the workflow — implementer / consumer / workflow infrastructure. Read by agents via a conditional reference in `base-instructions.md`. Survives sync because it's a separate file. Optional for pure consumer repos. | Stable; updated when role changes. |
| **`PROJECT-OVERVIEW.md` (PO)** | Repo root | The product's stable strategic framing: name, purpose, status, stakeholders, vision, core customer need, key features, one-paragraph architecture. Read by agents via a conditional reference in `base-instructions.md`. Survives sync. | Evergreen; changes when the project's purpose changes (rare). |
| **`AGENT-NOTES.md`** | Repo root | Project-specific agent-facing content that doesn't fit elsewhere: operational gotchas (sharp edges), project-specific commands (the `## Essential Commands` role the regenerated CLAUDE.md can't play), repo-local workflow conventions (branch naming, PR body templates). Read by agents via a conditional reference in `base-instructions.md`. Survives sync. | Mutable; updated as the project's quirks and commands evolve. |
| **PRD (`docs/specs/<feature>.md` or `designs/<feature>.md`)** | Sub-folder | Per-feature requirements: user stories, acceptance criteria, NFRs, success metrics. References the PO instead of re-deriving stakeholder/vision context. | Mutable per initiative; may be retired when the feature ships. Many over time. |
| **ADR (`docs/adr/NNNN-<slug>.md`)** | Sub-folder | One architectural decision with context, options, decision, consequences. Per-repo for project-scoped decisions; cross-cutting ADRs land in `ai-instructions/decisions/` per the workflow doc's hybrid rule. | Immutable once accepted; superseded by a newer ADR rather than edited. |
| **`CHANGELOG.md`** | Repo root | Release-versioned, user-visible change log per [Keep a Changelog](https://keepachangelog.com). Generated by `git-cliff` from Conventional Commits. | One entry per release; `[Unreleased]` accumulates between releases. |
| **`TODO.md`** | Repo root | Cross-cutting follow-up work that spans sessions or repos. In-repo work goes to GitHub Issues; `TODO.md` is for items that don't fit there. | Items get checked off as done; new ones land in the right section. |

Quick mental model:
- **CLAUDE.md / SKILL.md / copilot-instructions.md** = HOW to code (regenerated, never edit directly).
- **WORKFLOW-ROLE.md** = WHERE this repo fits in the workflow.
- **PROJECT-OVERVIEW.md** = WHAT the product is and WHY it exists.
- **AGENT-NOTES.md** = project-specific GOTCHAS, COMMANDS, and repo-local CONVENTIONS.
- **PRDs** = WHAT to build next (per feature).
- **ADRs** = WHY a specific technical choice was made.
- **CHANGELOG.md** = WHAT changed in each release.
- **TODO.md** = WHAT's left across sessions.

For the full lifecycle and routing rules, see [`workflows/personal-dev-workflow.md`](workflows/personal-dev-workflow.md) — in particular the Routing Daily Thoughts section.
