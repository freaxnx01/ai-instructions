# Role in the personal dev workflow

This repo IMPLEMENTS the personal dev workflow AND consumes it for its own
day-to-day work. The implementer role is additive: it follows all workflow
conventions like any consumer, and additionally treats the workflow doc as
design input.

Special status: this is the **home repo** of the workflow itself. The workflow
doc is hosted here, so changes here are often the *source* of workflow
changes, not just downstream consequences of them.

**Design source:**
- Workflow doc (this repo): `workflows/personal-dev-workflow.md`
- Per-stack overlays: `.ai/stacks/` (source of truth for downstream consumer
  projects)

**Read before non-trivial changes.** Edits to `workflows/personal-dev-workflow.md`,
`.ai/base-instructions.md`, or any stack overlay are workflow changes — they
propagate to every consumer that runs `/sync-ai-instructions`.

Routing thoughts in this repo follows the implementer-repo addendum
(see `workflows/personal-dev-workflow.md`, Routing Daily Thoughts section):
- Changes to how AI instructions are structured here → this repo
- Changes to the workflow doc itself → this repo (it lives here)
- Skill ideas / brainstorms-before-implementation → `ideas-lab`
