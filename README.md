# AI Coding Agent Instructions

Canonical, stack-agnostic AI agent instructions with per-stack overlays. Each project loads **base + exactly one stack** so agent context stays clean — a Flutter session never sees .NET content, and vice versa.

## Repository layout

```
.ai/
  base-instructions.md          ← stack-agnostic conventions (SemVer, Conventional
                                  Commits, TDD, Clean Code, 12-Factor, branching,
                                  git-cliff, Keep a Changelog, UI phase gates)
  stacks/
    dotnet.md                   ← .NET 10 / ASP.NET Core / Blazor / MudBlazor / EF Core
                                  / xUnit / bUnit / Playwright / Serilog / OpenTelemetry
  skills/
    commit.md           · push.md
    ui-brainstorm.md    · ui-flow.md · ui-build.md · ui-review.md

.claude/commands/               ← Claude Code slash-command wrappers for the skills above
```

`sync-ai-instructions` and `release-notes` used to live here as `.ai/skills/*.md`; they are now standalone plugins in the `freaxnx01/agent-skills` / `freaxnx01/claude-code-plugins` marketplaces and are available globally once installed.

New stacks (e.g. `flutter.md`, `node.md`) are added as their own files under `.ai/stacks/`. Nothing else in the repo changes when a stack is added.

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

### Option B — clone as template (.NET only)

This repo's root `CLAUDE.md`, `.github/copilot-instructions.md`, and `SKILL.md` are the pre-assembled rendering for a .NET project. If you want the .NET stack, cloning the repo gives you a working starting point. Fill in the TODO markers in `CLAUDE.md` (project name, purpose) and you're done.

## Supported stacks

| Stack | File | Covers |
|---|---|---|
| `dotnet` | `.ai/stacks/dotnet.md` | .NET 10 · ASP.NET Core Minimal API · Blazor + MudBlazor · EF Core · xUnit / bUnit / Playwright · Serilog + OpenTelemetry · Alpine Docker |

To add a new stack: create `.ai/stacks/<name>.md` following the shape of `dotnet.md` and open a PR.

## Adding a new stack

Each stack overlay should cover, at minimum:

- Tech-stack table
- Architecture conventions specific to the ecosystem
- Language conventions (style, naming, what to never generate)
- Testing framework choices, project layout, example templates
- UI component-library preferences (if applicable)
- Build / run / test commands
- Container / deployment specifics
- Stack-specific agent guardrails

Keep anything stack-agnostic (SemVer, Conventional Commits, TDD principles, Clean Code, 12-Factor, branching) in `base-instructions.md`, not in the overlay.

## Keeping a project in sync

When `base-instructions.md` or the stack overlay changes, consumers re-run `/sync-ai-instructions <stack>` to regenerate their `CLAUDE.md` / copilot / SKILL files. The skill reports the source commit SHA so you know which version of the instructions is in use.
