# TODO

Cross-cutting follow-up work that came out of the workflow brainstorm
sessions (2026-05-25 through 2026-05-27). Items that span multiple repos
or sessions land here; in-repo work goes to GitHub Issues.

For context, see `workflows/personal-dev-workflow.md` Decisions section —
many entries below trace back to a specific Decision.

## Open questions (not yet decisions)

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
- [ ] **First real product repo adoption** (`quicktask-vikunja`):
      sync done. PROJECT-OVERVIEW.md drafted; AGENT-NOTES.md to be
      migrated from existing `CLAUDE.project.md`. Pending the cross-
      repo commit step. Validation step — surfaces any remaining gaps.
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

## Stack overlays

- [ ] **`dotnet-fx48-legacy`: add a Web API 2 / OWIN reference scaffold.**
      The overlay's deep scaffolding is Nancy-only (derived from a Nancy
      service), but most net48 REST estates run ASP.NET Web API 2
      (`System.Web.Http`) — IIS via `System.Web.Http.WebHost` or self-host
      via `Microsoft.AspNet.WebApi.OwinSelfHost`. Add
      `.ai/references/dotnet-fx48-legacy/webapi2-owin-host.md` (ApiController
      + attribute routing, OWIN `Startup` + `HttpConfiguration`, self-host
      vs IIS split, `IExceptionHandler`/`IExceptionLogger` error shaping,
      `IDependencyResolver` DI, Newtonsoft formatter config) and promote the
      overlay's one-line "alternative flavour" mention to a short two-flavour
      framing. Makes the existing "detect Nancy vs `ApiController`" guardrail
      actionable. Only worth doing if Web API 2 appears in the estate, or to
      make the overlay reusable for the general net48 case. Keep the
      scrub/size/drift gates. (From PR #7 follow-up.)

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
- [x] Decision #14 — `PROJECT-OVERVIEW.md` pattern (2026-05-27).
- [x] Decision #15 — `AGENT-NOTES.md` pattern for operational/agent-facing
      project context (2026-05-27).
