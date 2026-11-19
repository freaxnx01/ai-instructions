# Milestone conventions

Milestones are the portable, cross-forge unit for grouping Issues into a
**manual-test batch**. A milestone is a *scope-triggered closure boundary*: it
is done when its scope is done, not when a date arrives. This note keeps
milestones consistent across GitHub and Forgejo so Bridge can derive milestone
state identically on both.

## Every open issue has a milestone

Every open issue carries **exactly one** milestone. "No milestone" is not a valid
state — it is the gap this rule closes, not a synonym for "not scheduled".

- Scheduled work sits in a `vX.Y · <goal>` (or `MNN · <goal>`) milestone.
- Everything else sits in **`backlog`** — the default whenever nothing else fits.

### The `backlog` milestone

Each repo has one standing milestone named exactly `backlog`: the home for
unscheduled, parked and roadmap issues.

- **Never active.** It is not a manual-test batch, so the scoping rules below do
  not apply to it and its progress percentage means nothing.
- **Never closed.** It is a standing collector, not a closure boundary.
- **No due date.**
- **Exempt from the naming rule** — the literal `backlog`, no version prefix.

Moving an issue out of `backlog` into a versioned milestone is how it gets
scheduled; moving it back (when it is parked or deferred) is how it gets
unscheduled. Neither step ever leaves it milestone-less.

### Labels carry the reason, not the milestone

The `parked` and `roadmap` labels say **why** an issue is in `backlog` (blocked /
on hold vs. deliberately deferred). They no longer stand in for a missing
milestone: a parked or roadmap issue still has `backlog` as its milestone.

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

The only name outside this scheme is `backlog` (see above).

### Legacy names — migrate, don't extend

Two older names don't conform and are **deprecated**:

- **`next`** — rename it to `backlog`. It already plays that role.
- **`general-<month>-<year>`** (e.g. `general-october-2026`) — move its open
  issues to `backlog` (or into a versioned milestone if they are genuinely
  scheduled), then close it. Don't create new ones: new issues default to
  `backlog`.

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
   opening the next. A future versioned milestone may exist but is not *active*
   until the current is closed. Unscheduled work goes in `backlog`, not in a
   future versioned milestone.
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

The rules apply in two tiers:

- **Every repo** (incl. `agent-workflow`, `ai-instructions`, `ideas-lab`): every
  open issue has a milestone, `backlog` exists as the default, and new milestones
  follow the naming rule. This is cheap, and it makes "unscheduled" an explicit,
  queryable state everywhere.
- **Repos with a surface you manually exercise** (`flowhub`, `bridge`):
  additionally the manual-test-batch rules — scoping rules, description as
  acceptance, completion and failure. Repos whose gate is CI or consumption
  (`agent-workflow`, `ai-instructions`) or that are deliberately low-ceremony
  (`ideas-lab`) use versioned milestones for grouping only; closing one there is
  not a manual-test sign-off.

### Azure DevOps

Employer DMS/HYPARCHIV work stays in Azure DevOps with its native iterations. The
same shape maps onto them: the **root iteration** plays the role of `backlog`
(unscheduled work sits there), and sprint/release iterations play the role of
versioned milestones.
