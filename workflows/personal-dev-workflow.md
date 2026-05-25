Personal Development Workflow

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
ideas-lab (private GitHub repo)
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

Routing Daily Thoughts
The content placement model above answers structural questions ("where
do designs live?"). This section answers the higher-frequency, smaller-
grained question: "I just had a thought — where does it go right now?"

Principle
Capture close to the destination. Where the thought belongs when it's
done is also where it belongs when it's a half-formed sentence. This
avoids a central inbox that has to be drained.

Decision tree

```
Is this about an existing, concrete project?
├─ YES → that project's repo
│   ├─ Tracking-level thing (todo, bug, chore) → GitHub Issue
│   ├─ Recurring checklist (release prep, manual test pass) → docs/checklists/
│   ├─ Plan/design (>30 lines) → designs/ + Issue that references it
│   └─ Plan/design (<30 lines) → Issue body, no separate file
│
└─ NO → is this about how I work, or about a thing to build?
    ├─ How I work (workflow, convention)
    │   ├─ Cross-project pattern (mature) → ai-instructions/workflows/
    │   │                                or ai-instructions/designs/
    │   └─ Just an idea, not committed → ideas-lab/ideas/
    │
    └─ A thing to build, no repo yet → ideas-lab/ideas/
        └─ When matures → graduate to dedicated repo
```

Bucket-by-bucket guidance

Todos (manual testing, chores)
- One-off chores → GitHub Issue with `chore` label, on the relevant repo.
- Recurring checklists (release prep, deployment steps, manual test
  passes) → `docs/checklists/<name>.md` in the project repo. Issues
  close; checklists persist.
- Trivial reminders to self → still prefer an Issue. Personal todo
  files tend to rot.

Ideas (no project yet)
- `ideas-lab/ideas/<rough-name>.md`. Low-friction: a few bullets is
  enough at capture time.
- Frontmatter optional but useful as the idea matures: `status: idea
  | exploring | graduated | abandoned`, `created: YYYY-MM-DD`.

Spec / impl plan (existing project)
- Spec and impl plan are usually the same artifact at different
  fidelities — don't create two files.
- Lives at `<project>/designs/<feature>.md` or `<project>/docs/specs/<feature>.md`.
  Pick one convention per project.

Issue with impl plan
- For short plans (< ~30 lines): paste the plan into the Issue body.
  Issue becomes the canonical spec; PR closes the Issue. Clean and
  minimal.
- For longer plans: extract to `designs/<feature>.md`, reference from
  the Issue ("See `designs/<feature>.md` for the plan"). Avoids
  duplication; design doc survives in Git diff history.

PR
- Body references the Issue (`Closes #N`) and the design doc if any.
- PR body is for change description and reviewer context, not for the
  plan content itself.

Workflow idea → existing project
- Cross-project convention → `ai-instructions/workflows/` or `designs/`.
- Single-project change → that project's `docs/` or `docs/adr/`.
- Speculative, not yet committed → `ideas-lab/ideas/`.

Workflow idea → new project
- `ideas-lab/ideas/<name>.md`. Matures → graduation path (real repo
  created, idea moved to `archived/` with pointer).

Capture-timing rule
Different from the "where" — about when to capture:
- Rough keyword, two-line thought → capture immediately, at lowest
  fidelity it deserves. The dangerous middle is "I'll write it down
  later." You won't.
- Half-formed plan → capture in the right home, mark `Status: rough
  draft` at the top of the file.
- Concrete plan you're about to execute → capture in the right home,
  then create the Issue/PR/branch that operationalizes it.

Promotion (rough idea → spec → issue → PR) happens naturally once the
thought is in the system.

Boundary with Superpowers (per Decision #10)
Once a thought is routed, if the destination is creative work (a new
feature, a behavior change, a new component), Superpowers takes over
from there. Routing Daily Thoughts ends at capture; Superpowers handles
the lifecycle from refined intent to shipped code.

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
Decisions

1. Seed file naming convention (resolved 2026-05-25)
   Canonical folders (workflows/, designs/, project docs/): stable filename,
   two-line preamble at top of file:
       Status: seed
       Captured: YYYY-MM-DD (Claude App brainstorm)
   When the doc graduates, delete the preamble — filename stays the same so
   git history and external links survive.

   ideas-lab/ideas/: date-prefix filename (YYYY-MM-DD-<slug>.md).
   Chronological browsing matters more than stable names here; most entries
   won't graduate, and the ones that do get copied/moved into a real repo
   anyway.

2. Public/private companion pattern (resolved 2026-05-25)
   Private companions live in a gitignored top-level `local/` folder that
   mirrors the public structure:

       ai-instructions/
         workflows/personal-dev-workflow.md       ← public, sanitized
         local/
           workflows/personal-dev-workflow.md     ← private, concrete values

   Adjacency makes "sanitize and publish" natural: diff `local/X` against `X`,
   scrub the differences, commit only the public version. The homelab vault
   stays scoped to homelab content; no new repo needed.

   Portability/backup concern (the `local/` folder lives only on the current
   machine) is real but separable — solve later via symlink to a synced path,
   rsync target, or similar. Not part of this decision.

3. ADR location (resolved 2026-05-25)
   Per-repo ADRs continue to live in `<repo>/docs/adr/` (project-scoped
   decisions).

   Cross-cutting decisions use a hybrid model:
   - Lightweight resolutions stay as inline entries in the relevant workflow
     or design doc's `Decisions` section (like this one).
   - Substantive decisions get promoted to
     `ai-instructions/decisions/NNNN-slug.md` in standard ADR format
     (Context · Decision · Consequences · Alternatives).

   Promote to a full ADR when at least one is true:
   1. The decision affects how multiple repos behave (not just one doc).
   2. You expect to revisit or reverse it later.
   3. Future-you would need the context-and-tradeoffs to understand *why*,
      not just *what*.

   First likely candidate: the consumer vs. implementer repo role split —
   promote when the next substantive cross-cutting decision comes up.

4. Obsidian + non-vault repos (resolved 2026-05-25)
   - `ideas-lab` → opened as an Obsidian vault. `.obsidian/` gitignored
     (per-machine config, no plugin state in the repo).
   - `ai-instructions` → NOT an Obsidian vault. Public repo consumed via
     GitHub; wikilinks (`[[...]]`) render as broken plain text there. Stick
     to standard relative markdown links.
   - Code repos → never Obsidian vaults.
   - Homelab vault → stays the canonical vault (full Obsidian feature set,
     `.obsidian/` committed).

   Cross-vault/cross-repo links fall back to plain markdown links with
   relative paths or GitHub URLs. Lose the bidirectional backlink, keep the
   link.

   Concrete follow-up (separate session in the ideas-lab repo): add
   `.obsidian/` to `ideas-lab/.gitignore`.

5. Reverse handoff CC CLI → Claude App (resolved 2026-05-25)
   Default (A): ask CC to produce a handoff file with the structure
       - What we set out to do
       - What we decided
       - What's blocked or needs broader thinking
       - The specific question Claude App should help with
   Place at `docs/ai-notes/YYYY-MM-DD-handoff-<slug>.md` (commit or not, your
   call). Paste into Claude App as the opening prompt.

   When continuing a prior thread (B): use Claude App's `conversation_search`
   to find the original brainstorm, then attach the handoff file's
   "what I've learned since" delta into that thread.

   Fallback (C): no prior brainstorm, no CC state worth dumping → start fresh
   in Claude App referencing the seed file by name.

   Rationale: a written artifact (A) enforces the same discipline as the
   forward direction — Claude App can't read local files, so the dump has to
   exist in text form regardless. Making it a checkpoint in `docs/ai-notes/`
   keeps the handoff visible in git history.

6. /sync-ai-instructions extension for workflow snapshots (resolved 2026-05-25)
   No extension. Workflow distribution is reference-only: consumer repos
   name the workflow file in their CLAUDE.md ("ai-instructions repo, file
   workflows/personal-dev-workflow.md") and CC reads it from the sibling
   repo or fetches from GitHub when needed.

   Rationale: snapshots create coordination tax (every workflow update means
   re-sync in N consumer repos, or accept stale copies). Offline/CI scenarios
   are rare enough that copying the file in as a one-off — or just cloning
   `ai-instructions` alongside the consumer repo — beats baking
   snapshot logic into the sync skill.

   Revisit if a concrete need shows up (e.g. a CI workflow that genuinely
   needs the doc and can't reach `ai-instructions`).

7. Pruning / lifecycle (resolved 2026-05-25)
   Both `ideas-lab` and `ai-instructions/designs/` favor archive-with-status
   over delete. Use the same `Status:` preamble pattern from Decision #1.

   ideas-lab:
   - `ideas/<name>.md` — `Status: active`
   - `archived/<name>.md` — `Status: graduated YYYY-MM-DD → <repo-url>` or
     `Status: abandoned YYYY-MM-DD — <reason>`
   - Quarterly review pass: walk `ideas/`, bump or archive stale entries.
   - Never delete unless it's accidental scratch (duplicates, moved content).

   ai-instructions/designs/:
   - Status values: `living` · `implemented` · `superseded by <path>` ·
     `abandoned YYYY-MM-DD — <reason>`
   - No `archived/` subfolder — designs stay co-located so grep-by-topic
     keeps working. Never delete.

   Common principle: the reasoning behind a discarded idea or superseded
   design is often more valuable than the idea itself. Git history preserves
   deletions but no one searches it; keep the file, mark the status.

8. Forgejo mirroring (resolved 2026-05-25)
   GitHub stays primary/canonical for both `ai-instructions` and `ideas-lab`.
   Forgejo is a backup mirror.

   Mechanism: Forgejo pull-mirror (Forgejo pulls from GitHub on schedule).
   In Forgejo: New Migration → GitHub → check "This repository will be a
   mirror." Configured once, then forgotten.

   Rules:
   - One writable remote: GitHub. Don't push to Forgejo manually.
   - URLs in CLAUDE.md / workflow docs / cross-references stay
     `github.com/freaxnx01/...` — no churn, GitHub remains canonical.
   - `ai-instructions` on Forgejo: private mirror is enough (GitHub is the
     public distribution channel).
   - `ideas-lab` on Forgejo: private mirror.

   Covers: GitHub outage, account suspension, archival link rot.
   Doesn't cover: simultaneous loss of homelab + GitHub. If that's a
   concern, add a third leg (external drive, off-site remote) — out of
   scope here.

   Concrete follow-up (separate session): set up the two pull-mirrors in
   the Forgejo instance.

9. CC Skills for workflow steps — first targets and location (resolved 2026-05-25)
   Workflow skills live as standalone plugins in the
   `freaxnx01/agent-skills` marketplace, consistent with the
   `sync-ai-instructions` precedent. This repo (`ai-instructions`)
   documents what each skill does in the workflow doc; the implementation
   lives in the marketplace repo.

   Rejected locations:
   - `ai-instructions/skills/<step>/SKILL.md` and
     `ai-instructions/workflows/skills/<step>/SKILL.md` both conflate
     "skills *about* the workflow this repo documents" with
     "skills *distributed to consumers* of this repo." `.ai/skills/` is
     reserved for consumer-bound skills (commit, push, ui-*).

   First targets, in order:
   1. ideas-lab review pass — highest recurrence × low complexity ×
      independent of Open Question #10 × procedure already specified in
      Decision #7. The skill becomes the forcing function for the
      quarterly review.
   2. Seed file handoff from Claude App — short stable procedure,
      validated by repeated use in this session. Encodes the Routing
      Daily Thoughts decision tree at handoff time.

   Unblocked by Decision #10 (Routing vs. Superpowers boundary), to be
   built after #1 and #4:
   - Brainstorm idea → spec (wrapper that delegates to Superpowers'
     `brainstorming` with idea-lab→spec routing baked in)
   - Promote idea → feature Issue (applies the short-plan-in-body vs
     link-to-design-doc routing rule, optionally invokes Superpowers'
     `writing-plans` for substantial plans)

   Deferred until a concrete trigger:
   - Path-portability audit (waits for next new-repo bootstrap).

10. Routing Daily Thoughts vs. Superpowers boundary (resolved 2026-05-25)
    Routing Daily Thoughts owns capture-time placement. Superpowers owns
    the implementation lifecycle. They compose, not compete.

    Rule: routing happens first, every time. Superpowers activates when
    the captured artifact is creative work (features, behavior changes,
    new components). Many routed thoughts never see Superpowers at all
    (chore Issues, checklists, ideas-lab entries in `ideas/`, lifecycle
    bookkeeping per Decision #7, repo renames, ADR captures).

    Overlap zones:
    - Idea-lab graduation (idea → spec): routing decides spec location,
      Superpowers' `brainstorming` produces spec contents.
    - Feature Issue with plan: routing decides short-plan-in-body vs
      link-to-design-doc, Superpowers' `writing-plans` produces
      structured plans when substantial.

    Effect: routing wrappers can invoke Superpowers as a delegated
    sub-process. CC Skill candidates #2 (brainstorm-to-spec) and #3
    (idea-to-Issue) are now unblocked under this framing.

    Mnemonic: routing decides location; Superpowers produces content.

CC Skills for Workflow Steps
Some workflow steps recur often enough — and have stable enough shape —
that they're candidates to become CC Skills. Workflow skills live as
standalone plugins in the `freaxnx01/agent-skills` marketplace
(see Decision #9), not inside this repo.

What makes a workflow step a good skill candidate
- Recurring — you do it more than monthly.
- Stable shape — the steps are similar each time; what varies is the
  content, not the procedure.
- Decision-heavy in a predictable way — the same kinds of judgment
  calls come up each time, so a skill that encodes those calls saves
  thinking.
- Crosses tool boundaries — touches Git, GitHub, files, and conventions
  in a coordinated way. Skills earn their keep when the coordination
  is the tricky part.

Candidate workflow steps

Strong candidates:
1. "Go through `ideas-lab` ideas" — periodic review pass. Triage each
   idea: still relevant? promote to design? archive? Skill encodes the
   review questions, frontmatter conventions, archival pattern.
2. "Brainstorm an idea into a spec" — taking an idea from
   `ideas-lab/ideas/<name>.md` and producing either a design doc in
   `ideas-lab` itself (for refinement) or, when mature, a real repo
   with a starter spec. Skill encodes the structure of a good spec
   and the graduation path.
3. "Promote an idea to a feature Issue" — once a spec is solid enough,
   open a GitHub Issue on the right project repo with the plan, link
   back to the spec, set labels. Skill encodes the short-plan-in-body-
   vs-link-to-design-doc decision and labeling conventions.
4. "Seed file handoff from Claude App" — the brainstorm-to-CC-CLI
   handoff happens often enough that a skill could codify it: where
   to drop the seed, what the first CC prompt should look like, what
   to commit and when.
5. "Audit + rewrite paths for repo portability" — surfaced during the
   `ideas-lab` bootstrap. Skill encodes the path conventions (see Path
   Conventions section above) and the audit-then-apply pattern.

Weaker candidates (one-off enough that a doc is fine, no skill needed):
- Repo renames (rare, prompt-driven is fine)
- Creating a new implementer repo (uses existing seed pattern, well-
  covered by README templates)

First targets (per Decision #9): ideas-lab review pass (#1), then seed
file handoff (#4). Candidates #2 (brainstorm idea → spec) and #3 (idea →
feature Issue) are unblocked per Decision #10 and scoped as routing-
wrappers that delegate creative-work-process to Superpowers — implement
after the first two ship.

Open Questions for CC CLI Session

(All 10 questions resolved 2026-05-25. New questions land here as they
come up.)

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
