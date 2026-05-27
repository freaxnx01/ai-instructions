# TODO

Cross-cutting follow-up work that came out of the workflow brainstorm
sessions (2026-05-25 through 2026-05-27). Items that span multiple repos
or sessions land here; in-repo work goes to GitHub Issues.

For context, see `workflows/personal-dev-workflow.md` Decisions section —
many entries below trace back to a specific Decision.

## Open questions (not yet decisions)

- [ ] **CLAUDE.md for a real product repo.** How does Decision #13's
      `WORKFLOW-ROLE.md` pattern interact with a real product repo
      (e.g. `quicktask-vikunja`) that uses `/sync-ai-instructions` and
      may need bespoke per-project content (architecture, domain
      context, deployment notes) beyond what base+stack provides?
      Is a similar separate-file pattern needed for project-specific
      overview content, or does it live in the regenerated CLAUDE.md
      via some other mechanism? Promote to Open Question #14 in the
      workflow doc when explored.

- [ ] **Workflow skill chain: Idea → Issue → PR → Review → Merge.**
      Expand Decision #9's CC Skills candidate list to cover the full
      implementation lifecycle, not just idea-to-spec and idea-to-Issue.
      Skills to design: PR creation from completed work, code review
      delegation, merge-and-cleanup. Compose with Superpowers'
      `requesting-code-review` / `receiving-code-review` per Decision
      #10's boundary (routing/skill decides location; Superpowers
      produces content).

## Cross-repo follow-ups (separate sessions)

- [ ] **agent-pipeline**: create `WORKFLOW-ROLE.md` at repo root per
      Decision #13. No edits to CLAUDE.md needed (it's regenerated).
- [ ] **ideas-lab**: add `.obsidian/` to `.gitignore`; create
      `WORKFLOW-ROLE.md`; open the local clone as an Obsidian vault
      per Decision #4.
- [ ] **ai-instructions root regen**: run `/sync-ai-instructions
      dotnet-blazor` to refresh root `CLAUDE.md` / `SKILL.md` /
      `.github/copilot-instructions.md` with the new
      `base-instructions.md` reference line from Decision #13.

## Skill development (freaxnx01/agent-skills marketplace)

Per Decision #9 ordering, expanded per the second open question above.

- [ ] #1 — ideas-lab review pass (highest priority, unblocked).
- [ ] #4 — seed file handoff from Claude App.
- [ ] #2 — brainstorm idea → spec (wrapper around Superpowers'
      brainstorming).
- [ ] #3 — promote idea → feature Issue.
- [ ] PR creation from completed work *(new — from skill-chain question)*.
- [ ] Code review delegation *(new)*.
- [ ] Merge-and-cleanup *(new)*.
- [ ] #5 — path-portability audit (deferred until next new-repo
      bootstrap).

## Infrastructure

- [ ] Forgejo: set up pull-mirrors for `ai-instructions`, `ideas-lab`,
      `bridge`, `agent-pipeline` per Decision #8.

## Done

- [x] Place workflow doc at `workflows/personal-dev-workflow.md`
      (2026-05-25, commit `a3e4896`).
- [x] Resolve seed open questions 1-10 (2026-05-25, commit `dd1c972`).
- [x] Drop seed preamble — doc graduated (2026-05-25, commit `2295595`).
- [x] Add Routing Daily Thoughts + CC Skills sections (2026-05-25,
      commit `d51231a`).
- [x] Decision #11 — implementer repos are also consumers (2026-05-26).
- [x] Decision #12 — CLAUDE.md snippet placement (2026-05-26).
- [x] Decision #13 — `WORKFLOW-ROLE.md` pattern (2026-05-27).
- [x] Backfill `bridge/CLAUDE.md` with implementer-role framing
      (2026-05-27, bridge commit `4c844c5`).
- [x] Create `WORKFLOW-ROLE.md` for this repo (2026-05-27, commit
      `e022b4f`).
