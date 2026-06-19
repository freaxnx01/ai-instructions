# CLAUDE.md

Agent context for **this** repository. Read this before taking any action here.

> This is the `ai-instructions` **source repo** — a content repository of Markdown
> conventions and a small Bash build script. It is **not** an application. There is no
> .NET / Flutter / Go / Node project to build or test here, despite what the stack overlays
> describe. The overlays are *content we publish*, not the stack of this repo.
>
> Looking for the pre-assembled .NET Blazor starter that used to live at the repo root?
> It moved to `.ai/examples/dotnet-blazor/` (CLAUDE.md, SKILL.md, copilot-instructions.md).

---

## Project Overview

**Name:** `ai-instructions`
**Purpose:** Canonical, stack-agnostic AI coding-agent instructions with per-stack overlays.
Each consuming project loads **base + exactly one stack** so agent context stays clean.
**Architecture:** Markdown content + a Bash composition script. No runtime.
**Status:** Active.

---

## Mental Model

A consuming project's instruction files are **composed**, never referenced:

```
.ai/base-instructions.md   (stack-agnostic: SemVer, TDD, Clean Code, 12-Factor, git…)
        +
.ai/stacks/<stack>.md      (one published flat overlay)
        +
.ai/skills/*               (shared skill bodies)
        ↓  (assembled at sync time — full content inlined, no @imports)
   target project's  CLAUDE.md · .github/copilot-instructions.md · SKILL.md
```

The indirection lives entirely at **build/sync time**. The output files are flat and
self-contained. Editing an overlay here changes nothing in any project until that project
re-runs `/sync-ai-instructions`.

---

## Repository Structure

```
.ai/
  base-instructions.md          ← stack-agnostic conventions (edit freely)
  stacks/
    flutter.md · go.md · ci.md          ← single-file overlays (edit directly)
    dotnet-fx48-legacy.md               ← single-file overlay, hand-authored (not generated)
    dotnet-blazor.md                    ← GENERATED — do not edit
    dotnet-webapi.md                    ← GENERATED — do not edit
    _partials/
      dotnet-core.md            ← shared .NET content (edit this)
    _layers/
      dotnet-blazor.md          ← Blazor delta (edit this)
      dotnet-webapi.md          ← WebAPI delta (edit this)
  skills/                       ← shared skill bodies (commit, push, ui-*)
  references/                   ← long code blocks / checklists pulled out of overlays
  examples/
    dotnet/justfile             ← sample artifacts referenced by overlays
    dotnet-blazor/              ← pre-assembled dotnet-blazor rendering (Option B template)
scripts/
  build-stacks.sh               ← composes _partials + _layers → flat stacks/dotnet-*.md
.github/workflows/
  build-stacks-drift.yml        ← CI: fails if generated files drift from sources
.claude/commands/               ← Claude Code slash-command wrappers for the skills
workflows/                      ← cross-cutting workflow docs that span repos
README.md                       ← human-facing overview
CLAUDE.md                       ← this file
```

---

## Working in This Repo — The One Rule That Bites

**Never edit the generated flat files** `.ai/stacks/dotnet-blazor.md` or
`.ai/stacks/dotnet-webapi.md` directly. They carry a `GENERATED FILE — do not edit`
banner. To change .NET content:

1. Edit the source — `.ai/stacks/_partials/dotnet-core.md` (shared) or the relevant
   `.ai/stacks/_layers/dotnet-*.md` (per-flavour delta).
2. Regenerate: `./scripts/build-stacks.sh`
3. Commit the source **and** the regenerated flat files together.

The `build-stacks-drift` CI check runs `build-stacks.sh` and fails the PR if
`git diff --exit-code .ai/stacks/dotnet-*.md` shows changes — so a forgotten regenerate,
or a direct edit to a generated file, is caught automatically.

Single-file overlays (`flutter.md`, `go.md`, `ci.md`, `dotnet-fx48-legacy.md`) have no
partial/layer split — edit them directly.

---

## Essential Commands

```bash
# Regenerate the flat .NET overlays after editing a partial or layer
./scripts/build-stacks.sh

# Verify you're in sync with the sources (what CI checks)
./scripts/build-stacks.sh && git diff --exit-code .ai/stacks/dotnet-*.md
```

There is no compiler, package manager, or test runner in this repo.

---

## Adding or Changing Content

- **Stack-agnostic rule** (applies to every language) → `base-instructions.md`, not an overlay.
- **New single-file stack** (no shared baseline) → create `.ai/stacks/<name>.md` directly,
  then add it to the README "Supported stacks" table.
- **New .NET flavour** → add `_layers/dotnet-<flavour>.md`, run `build-stacks.sh`, commit
  the new flat file too.
- **Long code blocks / checklists** → keep overlays lean by moving them under
  `.ai/references/` and linking, following the existing pattern.

---

## Conventions for This Repo

- **Commits:** Conventional Commits (`docs`, `refactor`, `feat`, `ci`, `chore`). Scope by
  area, e.g. `refactor(stacks): …`, `docs(readme): …`.
- **Branching:** branch from `main`, PR back, squash/rebase merge.
- **Tone of the content itself:** imperative, terminal-friendly, no fluff. The overlays are
  read by agents, so favour precise rules over prose.
- **Keep base and overlays disjoint:** if a rule is true for every stack, it belongs in
  base; if it's framework-specific, it belongs in the overlay. Don't duplicate across both.

---

## Agent Guardrails

- Do **not** edit generated `.ai/stacks/dotnet-*.md` files — edit the partial/layer sources.
- Do **not** treat the `.NET` / `Flutter` / `Go` commands inside the overlays as commands for
  *this* repo — they are published content describing *other* projects.
- The trio under `.ai/examples/dotnet-blazor/` is a **sample rendering** (Option B template).
  Don't wire it into this repo's tooling; only update it when the dotnet-blazor sources change.
- Keep changes minimal and focused; don't refactor unrelated overlays in an unrelated PR.
