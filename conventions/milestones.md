# Milestone conventions

Milestones are the portable, cross-forge unit for grouping Issues into a
**manual-test batch**. A milestone is a *scope-triggered closure boundary*: it
is done when its scope is done, not when a date arrives. This note keeps
milestones consistent across GitHub and Forgejo so Bridge can derive milestone
state identically on both.

## Portability rule (load-bearing)

Use **plain milestones only** — the one grouping primitive GitHub and Forgejo
implement identically (per-repo, optional due date, progress = closed/total).

- Do **not** use GitHub Projects iteration fields or GitHub-native epic/sub-issue
  types for grouping that must mirror across forges — Forgejo has no equivalent,
  and it creates split-brain.
- "Epic" = a **tracking Issue** (design context + child checklist), not a forge
  feature. Milestone = *when it ships together*; tracking Issue = *what it
  belongs to*. They coexist and cut across each other.

## Naming

`vX.Y · <goal>`

- `vX.Y` — the SemVer minor line this milestone completes toward. Sortable,
  ties to the changelog/release, identical string on both forges.
- `<goal>` — short, lowercase, ≤5 words. The deliverable, not a category.
- Example: `v0.3 · cross-forge milestone view`

Fallback for repos that don't cut versioned releases: `MNN · <goal>` with a
zero-padded ordinal (`M01`, `M02`) so it still sorts.

## Scoping rules

These keep "progress = 100%" meaning **"ready for me to test"** — the signal
Bridge's *awaiting manual test* state depends on. Break them and the gate
becomes noise.

1. **One milestone = one manual-test batch.** Everything you intend to verify in
   a single testing pass — and nothing more.
2. **Only genuinely-in-batch Issues.** No aspirational or "someday" Issues parked
   in an active milestone. A stray open Issue keeps progress below 100% forever
   and the completion event never fires.
3. **Cap it to one sitting.** If it's too large to test in one pass, split into
   two milestones. (This is the pull principle applied to verification.)
4. **One active milestone per repo.** Finish and verify the current one before
   opening the next. A future milestone may exist as a backlog collector but is
   not *active* until the current is closed.
5. **Due dates are advisory only** — never the completion trigger. Leave empty
   unless there's a real external deadline (e.g. a CAS submission date).

## Description field = manual-test acceptance

Put the human-test acceptance in the milestone **description**, forge-agnostic:

> Verified when: <the steps you click through before closing>

This is what you check before closing the milestone, and Bridge can surface it
alongside the state.

## Completion and failure

- **Complete:** all child Issues closed → milestone sits *open at 100%* →
  Bridge surfaces "awaiting manual test."
- **Pass:** you close the milestone. Closing **is** the verification sign-off.
- **Fail:** add fix Issue(s) to the **same** milestone — progress drops, Bridge
  re-derives *active*. Do **not** open a new milestone for fixes, and do not
  reopen a closed one (it was never closed).

## Where this applies

Repos with a surface **you** manually exercise: `flowhub`, `bridge`.

Not `agent-pipeline` (gate is CI/consumption), `ai-instructions` (no runtime
surface), or `ideas-lab` (deliberately low-ceremony). Employer DMS/HYPARCHIV
work stays in Azure DevOps with its native iterations — out of scope here.
