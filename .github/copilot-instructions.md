# GitHub Copilot Instructions

These apply to **this** repository — the `ai-instructions` source repo. It is a
**Markdown + Bash content repo** that *produces* AI-agent instruction files for other
projects. It is **not** an application: there is no compiler, package manager, or test
runner here, despite what the stack overlays under `.ai/stacks/` describe. Those overlays
are *published content*, not the stack of this repo.

> Looking for the .NET Blazor starter that used to be at the repo root? It moved to
> `.ai/examples/dotnet-blazor/`. The fuller guide for working here is the root `CLAUDE.md`.

## Mental model

A consuming project's instruction files are **composed, never referenced**:

```
.ai/base-instructions.md  +  .ai/stacks/<stack>.md  +  .ai/skills/*
        ↓  (assembled at sync time — full content inlined, no imports)
   target project's  CLAUDE.md · .github/copilot-instructions.md · SKILL.md
```

A project loads **base + exactly one stack**. Editing an overlay here changes nothing
downstream until that project re-runs `/sync-ai-instructions`.

## The rule that bites

**Never edit the generated flat files** `.ai/stacks/dotnet-blazor.md` or
`.ai/stacks/dotnet-webapi.md` — they carry a `GENERATED FILE — do not edit` banner. To
change .NET content:

1. Edit the source: `.ai/stacks/_partials/dotnet-core.md` (shared) or
   `.ai/stacks/_layers/dotnet-*.md` (per-flavour delta).
2. Run `./scripts/build-stacks.sh` to regenerate the flat files.
3. Commit the source **and** the regenerated flat files together.

CI (`build-stacks-drift`) regenerates and fails the PR if the committed flat files differ,
so a forgotten regenerate or a direct edit to a generated file is caught automatically.

Single-file overlays (`flutter.md`, `go.md`, `ci.md`, `dotnet-fx48-legacy.md`) have no
partial/layer split — edit directly.

## When generating or completing here

- Keep **stack-agnostic** rules (SemVer, TDD, Clean Code, 12-Factor, git) in
  `base-instructions.md`; keep framework-specific rules in the overlay. Don't duplicate
  across both.
- Don't treat the `.NET` / `Flutter` / `Go` commands inside overlays as commands for *this*
  repo — they are published content describing *other* projects.
- The trio under `.ai/examples/dotnet-blazor/` is a **sample rendering**. Only update it when
  the dotnet-blazor sources change; don't wire it into this repo's tooling.
- Move long code blocks / checklists out of overlays into `.ai/references/` and link them,
  following the existing pattern, to keep overlays lean.
- Commits follow Conventional Commits, scoped by area (e.g. `docs(readme):`,
  `refactor(stacks):`). The content itself is written imperative and terminal-friendly —
  it's read by agents, so favour precise rules over prose.
