# Changelog

<!-- changelog-covers-through: 84e7850 -->

All notable changes to `ai-instructions` are documented here, following
[Keep a Changelog](https://keepachangelog.com). Sections are dated rather than
versioned: this repo carries no tags or releases.

**Who this is for.** You sync `base-instructions.md` + one stack overlay into your own
project. This file answers one question: *has anything changed that means you should
re-run `/sync-ai-instructions`, and was it your overlay?* Groups are ordered by that —
`Base` affects everyone, `Stack overlays` is where you look for your own, and
`Repo only` never needs a re-sync.

To find what is new for you, compare against the date of your last sync commit
(`git log -1 --format=%ad -- .ai/base-instructions.md` in your project).

Entries are generated from Conventional Commits with `git-cliff`. The 17 non-conventional
commits — the pre-convention history up to 2026-05-27, plus three merge commits — are
**not** included; see `git log` for those. Files under `.ai/references/` are linked by the
overlays rather than inlined, so changes there reach you without a re-sync.

## 2026-09-18

### Stack overlays

- **browser-game** — blur the language toggle after a click (#40)
- **browser-game** — warn to re-copy i18n.js when adding keyboard controls (#42)
- **browser-game** — CHANGELOG is hand-written, never regenerated with git cliff (#43)

### Repo only — no re-sync needed

- **changelog** — cover #36 through #38 (#39)

## 2026-09-17

### Repo only — no re-sync needed

- **changelog** — point the watermark at a commit on main (#36)
- **agent-workflow** — opt in to the AI-review + human-merge flow (#37)
- **agent-workflow** — enable the review self-fix pass (#38)

## 2026-09-15

### Repo only — no re-sync needed

- **changelog** — add a consumer-facing CHANGELOG.md (#35)

## 2026-09-14

### Base — affects every stack

- **ai** — split instructions into stack-agnostic base + stack overlays
- **base** — add Git Worktrees conventions section
- **base** — add i18n and regional formatting conventions
- **base** — add Working Method meta-rules section
- **lint** — polyglot pre-commit standard + template (#13)
- **base** — allow trivial non-code changes to skip PR review (#16)
- **base** — require Windows PowerShell 5.1 for customer-delivered scripts (#19)
- **base** — drop the direct-push exception for trivial edits (#22)
- **base** — document Issue Title Conventions (#24)
- **base** — add descriptive action+outcome logging convention
- **scaffold** — name .worktrees/ in the baseline and Flutter .gitignore entries (#29)

### Stack overlays

- **dotnet** — standardize Makefile targets for stack
- **dotnet** — add reference Makefile
- **dotnet-webapi** — trim layer to keep assembled CLAUDE.md under 40k
- **go** — add two-tier TUI testing (teatest + tmux PTY) (#6)
- **ci-overlay** — shellcheck via find, not a `**/*.sh` glob (#10)
- **quality-gates** — document standard + canonical layout + dotnet template (#15)
- **dotnet-fx48-legacy** — add Web API 2 / OWIN reference scaffold (#23)
- **browser-game** — document concrete DE/EN i18n pattern
- **browser-game** — document i18n toggle framework-managed-nav gotcha
- **browser-game** — clarify dc-tool has no CLI, re-bundling is manual (#27)
- **ci** — add .gitignore entry to the scaffold checklist (#30)
- **browser-game** — forbid backgrounded verification in headless runs (#33)

### Stack overlays (unspecified)

- **stacks** — add Flutter overlay
- **stacks** — add CI / automation overlay
- **stacks** — split dotnet overlay into core partial + blazor layer
- **stacks** — add dotnet-webapi overlay for backend-only REST projects
- **stacks** — move long code blocks + checklists to references/, slim CLAUDE.md
- **stacks** — trim duplicated rules to bring CLAUDE.md under 40k
- **stacks** — replace Makefile with justfile across dotnet/ci/flutter
- **stacks** — add Go stack overlay (#5)
- **stacks** — add dotnet-fx48-legacy overlay (.NET Framework 4.8) (#7)
- **stacks** — add browser-game overlay (#17)
- **stacks** — reclaim assembled-CLAUDE.md headroom, 5 B -> 1540 B (#20)
- **stacks** — trim the .NET overlays, headroom 1540 B -> 3644 B (#21)
- **stacks** — add gdscript-godot, shell-scripts, dotnet-library overlays

### Shared skills & commands

- **skills** — add UI workflow commands for Claude Code and GitHub Copilot (#1)
- **skills** — add release-notes skill for user-friendly release notes
- **skills** — auto-detect stack on init-instructions re-run
- **skills** — move the 4-phase UI workflow to the agent-workflow console (#18)

### Unscoped or unmapped — see the commit

- add AI agent instruction files
- add UI development workflow and MudBlazor conventions
- add commit/push slash commands and strengthen conventions
- add docs structure, Bruno API testing, and global versioning rule
- enable embedded PDB symbols for release builds
- standardize on git-cliff for changelog and release notes
- add Makefile template for .NET modular monolith projects
- add Clean Code principles to AI instructions
- rename /init-instructions references to /sync-ai-instructions
- regenerate root agent files from dotnet-blazor stack (#9)

### Repo only — no re-sync needed

- remove init-instructions skill/command (promoted to plugin)
- remove release-notes skill (promoted to plugin)
- **readme** — list ci overlay in supported stacks table
- enforce assembled CLAUDE.md size budget per stack
- add opt-in local pre-commit hook for the CLAUDE.md size check
- **workflow** — add work-scoped ideas-lab mirror to repo inventory
- auto-add new issues to freaxnx01 Backlog project
- **repo** — repo-specific root CLAUDE.md + Copilot instructions; relocate dotnet-blazor template (#11)
- **conventions** — add cross-forge milestone conventions
- **agent-workflow** — add consumer stub
- ignore .worktrees/ for isolated worktree checkouts
- **changelog** — spec and plan for a consumer-facing CHANGELOG (#31) (#32)
- **agent-workflow** — auf @v2 heben
- **changelog** — add Task 0 to install git-cliff on the runner (#34)
- **changelog** — add cliff.toml with consumer-impact grouping
