Personal Development Workflow

Status: Seed document — captured from a Claude App brainstorm on 2026-05-25.
Needs refinement in CC CLI session. Open questions are flagged inline.

Purpose
Define a coherent personal development workflow that answers:

Where do different types of content live (designs, ideas, conventions, notes)?
How do I move between brainstorming (Claude App) and concrete work (CC CLI)?
How do cross-cutting concerns that span multiple repos get handled?
How does each repo relate to the workflow itself (consumer vs. implementer)?

Core Principles
1. Docs live near the work they describe
Validated empirically: CAS notes were originally in a separate vault, later
migrated into the CAS repo because that felt more natural — the notes and the
code informed each other and CC had full context in one place.
2. Repos have explicit roles relative to the workflow
Not every repo relates to the workflow the same way. Two roles:

Consumer repos — real projects (e.g. quicktask-vikunja, business apps).
The workflow is applied to them. They follow it as background guidance.
Implementer/meta repos — workflow infrastructure
(e.g. agent-pipeline, bridge, ideas-lab, ai-instructions itself).
The workflow is their subject matter. They implement part of it.

This distinction drives how each repo's CLAUDE.md is framed (see below).
Content Placement Model
Homelab vault (Obsidian, Git-backed, private)
Scope: Homelab infrastructure — network, services, hardware, configuration
notes, runbooks.
What goes here: Homelab-specific notes, service configs and rationale,
network topology, hardware decisions, infrastructure runbooks.
What does NOT go here: Workflow/dev practices, project ideas, cross-cutting
designs. The "homelab" name is correctly scoped — don't dilute it.
ai-instructions (public GitHub repo)
Scope: How I work — tech stack conventions, AI tooling configuration,
workflows, cross-stack design patterns.
What goes here:

Per-stack CLAUDE.md / SKILL.md / .ai/base-instructions.md (existing)
workflows/ — personal dev workflow, meta-patterns, conventions
designs/ — cross-cutting designs that are mature and publishable

Sanitization required: Public repo. Abstract specifics — no real hostnames,
no employer-internal details, no homelab specifics that reveal attack surface.
Use placeholders (<homelab-host>, "internal company GitHub org") or keep
sensitive values in gitignored local/ files.
ideas-lab (private GitHub repo, to be created)
Scope: Ideas-before-projects, experiments, rough thinking.
What goes here:

ideas/ — project ideas with no repo yet, rough specs, "what if I built X"
experiments/ — weekend hacks that may or may not graduate to real projects
archived/ — graduated (moved to real repo) or abandoned ideas

Graduation path: Idea matures → gh repo create freaxnx01/<project> →
copy/move the idea doc into the new repo as README.md or docs/origin.md →
archive original in ideas-lab/archived/.
Concrete project repos
Scope: Project-specific code AND project-specific notes/designs.
What goes here: Design docs that are scoped to this project
(agent-pipeline-design.md belongs in agent-pipeline, not in
ai-instructions). Implementation, tests, project-specific decisions, ADRs
scoped to the project.
Repo Roles and CLAUDE.md Patterns
Two roles, two different framings in CLAUDE.md.
Consumer repos (e.g. quicktask-vikunja)
The workflow is background guidance — conventions for commits, branching,
testing, etc.
markdown## Workflow context

This repo follows the personal dev workflow defined in `ai-instructions`
(repo: <https://github.com/freaxnx01/ai-instructions>, file:
`workflows/personal-dev-workflow.md`). A local snapshot may also be present
at `.ai/workflow-snapshot.md`.

Read it for conventions on commits, branching, testing, etc.
Implementer/meta repos (e.g. agent-pipeline, bridge, ideas-lab)
These repos implement part of the workflow. The workflow doc is design input,
not background context. Changes to the repo may require updates to the workflow.
markdown## Role in the personal dev workflow

This repo IMPLEMENTS part of the personal dev workflow. It is not a consumer —
it is workflow infrastructure.

**Design source:**
- Workflow doc: `ai-instructions` repo, file
  `workflows/personal-dev-workflow.md`
  (<https://github.com/freaxnx01/ai-instructions/blob/main/workflows/personal-dev-workflow.md>)
- `designs/<this-repo-design>.md` — this repo's specific design (if present)

**Read both before non-trivial changes.** Changes here may require corresponding
updates to the workflow doc in `ai-instructions`.
Design doc placement rule
When an implementer repo has a substantial design doc, the doc lives with the
implementation, not in ai-instructions. Example: agent-pipeline-design.md
lives in agent-pipeline/designs/, not in ai-instructions/designs/. The
workflow doc references it.
ai-instructions/designs/ holds only cross-cutting designs that don't have a
single implementing repo (yet).
Distributing the Workflow to Other Repos
For consumer repos that need the workflow as background context, two mechanisms
working together:

CLAUDE.md repo-relative reference — primary mechanism. Names the
ai-instructions repo and the file path inside it
(workflows/personal-dev-workflow.md) without hardcoding a local
filesystem path. CC can resolve "look in my sibling ai-instructions
repo" from the local checkout layout.
Snapshot sync via /sync-ai-instr — extend the existing skill-sync command
to also pull a snapshot of the current workflow into a per-repo
.ai/workflow-snapshot.md. Handles offline / new-machine / CI cases. Pick up
workflow updates by running sync.

For implementer repos, the same CLAUDE.md reference applies, but with the
"implements" framing — and they may also need to write back to the workflow
doc as their behavior evolves.
Path Conventions
To keep committed docs portable across machines and avoid hardcoding any
user's specific filesystem layout:

Sibling repo references — use repo-name + path-within-repo (e.g.
"ai-instructions repo, file workflows/personal-dev-workflow.md").
Don't write ~/repos/ai-instructions/... or
~/projects/repos/github/<user>/public/ai-instructions/... — both
hardcode a specific layout.
GitHub URLs are fine for human-readable references in prose
(<https://github.com/freaxnx01/ai-instructions/blob/main/...>).
In-repo paths — use plain relative paths from the repo root
(workflows/personal-dev-workflow.md, designs/foo.md). The repo
root is the natural anchor.
External resources (vault, $HOME) — use absolute paths
(/mnt/c/Users/<user>/Documents/Obsidian/homelab/) since there's
no portable alternative. These should be rare in committed docs.

Rationale: the actual disk layout on freaxnx01's machine is
~/projects/repos/github/freaxnx01/{public,private}/<repo> — that's
not portable and shouldn't appear in committed docs. Repo-relative
references (ai-instructions repo, file X) survive any layout change
and read naturally to humans.
The Brainstorm → Concrete Handoff
The friction this workflow is designed to solve.
Pattern

Brainstorm in Claude App until the idea has enough shape to write down.
Produce a seed file — Claude App generates a markdown document
capturing: decisions made, open questions, next steps, key context.
Place the seed file in the appropriate repo based on the model above:

Nascent / no clear home → ideas-lab/ideas/
Workflow / conventions / publishable → ai-instructions/workflows/ or
ai-instructions/designs/
Scoped to existing project → that project's docs/ or designs/ folder


cd into the repo, start CC CLI session. First prompt points CC at the
seed file:

"Read <path> — it's a seed from a Claude App brainstorm. Help me
develop it. Start by asking what's underspecified."


CC takes over with full repo context, file-writing ability, Git
tracking. The seed file is the handoff mechanism.

Why this works

No tooling magic needed — markdown file + cd + Git
Seed file forces Claude App to produce a structured artifact, not just a
conversation
CC CLI inherits full context immediately via the seed file plus repo CLAUDE.md
Iteration history lives in Git from the moment CC starts working

Open question: reverse handoff (CC CLI → Claude App)
When CC CLI gets stuck or needs broader thinking, how do I efficiently bring
context back to Claude App? Options to explore:

Have CC produce a "context dump" markdown summarizing where it is, then paste
into Claude App
Use conversation_search to find prior Claude App threads on the topic
Treat it as a fresh Claude App brainstorm referencing the seed file

Repo Inventory (current state, for reference)
RepoVisibilityRoleNotesai-instructionspublicImplementerAI tooling, CLAUDE.md/SKILL.md, multi-stack. Hosts this workflow doc. CLI alias aii.homelab vaultprivate (separate, Git-backed, not on GitHub)n/a (vault, not workflow infra)Homelab infra notes only — correctly scoped. Lives at /mnt/c/Users/freax/Documents/Obsidian/homelab/.agent-pipeline (planned rename of claude-pipeline)privateImplementerGH Actions pipeline replicating Copilot Coding Agent. Hosts its own design doc. CLI alias agp.bridge (renamed from clrepo)privateImplementerPersonal dev cockpit: agent session launcher, dashboards for issues/PRs/Action runs. CLI alias brg.ideas-labprivateImplementerIdeas-before-projects incubator. CLI alias idl.quicktask-vikunja etc.variesConsumerReal projects. Follow workflow as background guidance.
Disk layout: repos are organized by visibility:
~/projects/repos/github/freaxnx01/{public,private}/<repo>.
CLI alias convention
Each meta repo gets a short shell alias for fast navigation, defined in shell
config (.bashrc / .zshrc). Paths reflect the actual layout
(~/projects/repos/github/freaxnx01/{public,private}/<repo>):
bashalias aii='cd ~/projects/repos/github/freaxnx01/public/ai-instructions'
alias agp='cd ~/projects/repos/github/freaxnx01/private/agent-pipeline'
alias brg='cd ~/projects/repos/github/freaxnx01/private/bridge'
alias idl='cd ~/projects/repos/github/freaxnx01/private/ideas-lab'
If the paths get tedious, define a $REPOS_GH env var pointing to
~/projects/repos/github/freaxnx01 and use it in the aliases:
bashexport REPOS_GH="$HOME/projects/repos/github/freaxnx01"
alias aii="cd $REPOS_GH/public/ai-instructions"
alias brg="cd $REPOS_GH/private/bridge"
# etc.
Naming rule for the aliases themselves:

Single-word repo → strip vowels, keep 3 consonants (bridge → brg)
Hyphenated repo → first letter of each word (agent-pipeline → agp,
ai-instructions → aii, ideas-lab → idl)

For bridge specifically, brg may eventually become the command name of
the bridge CLI tool itself (not just a cd alias) — e.g. brg <repo>
launches an agent session in that repo, brg status shows the dashboard.
Open Questions for CC CLI Session

Naming convention for seed files. Date prefix? Status header? Frontmatter?
Public/private companion pattern. When a workflows/ doc in
ai-instructions is abstract for public consumption, where does the
private version with real values live? Gitignored local/ folder? Companion
file in homelab vault?
ADR location. Per-repo docs/adr/ for project-scoped decisions, but
where do cross-cutting ADRs live? ai-instructions/decisions/?
Obsidian + non-vault repos. The homelab vault has Obsidian's full
feature set. ai-instructions and ideas-lab are plain markdown repos.
Do I open them in Obsidian too? If yes, how does that interact with Git
and CC CLI?
Reverse handoff (CC CLI → Claude App). When CC gets stuck or needs
broader thinking, what's the clean way to bring context back to Claude App?
Context-dump file? conversation_search? Fresh brainstorm referencing the
seed?
/sync-ai-instr extension. Extend to also sync workflow snapshots to
per-repo .ai/workflow-snapshot.md? Or keep workflow distribution as
CLAUDE.md path reference only?
Pruning / lifecycle. When does an ideas-lab entry get archived vs.
deleted? When does an ai-instructions/designs/ doc get retired?
Forgejo mirroring. Should ai-instructions and ideas-lab also live
on the homelab Forgejo instance, given the migration in progress?

Next Steps

Drop this seed file at ai-instructions/workflows/personal-dev-workflow.md.
Start CC CLI session in ai-instructions/, point it at this file.
Resolve open questions above; refine into a final workflow doc.
Update ai-instructions/CLAUDE.md and/or README.md to reference the
workflow doc and the broader repo scope.
Backfill bridge/CLAUDE.md with the implementer-role framing.
When renaming claude-pipeline → agent-pipeline, apply the same
framing to its CLAUDE.md.

Done so far:

bridge renamed from clrepo (commit + remote + local).
ideas-lab created and populated with role-aware CLAUDE.md and structure.
Path-portability lessons captured in this doc.
