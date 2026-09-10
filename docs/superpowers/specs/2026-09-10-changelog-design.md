# Design — `CHANGELOG.md` for `ai-instructions`

Issue: [#31](https://github.com/freaxnx01/ai-instructions/issues/31)
Date: 2026-09-10

A `git-cliff`-generated, date-sectioned, tagless changelog whose entries are grouped by
**consumer impact** — base / your overlay / shared skills / repo-only — with a recorded
"last covered" SHA so incremental regeneration works without tags.

---

## Problem

`ai-instructions` has no `CHANGELOG.md`. A consuming project syncs **base + exactly one
stack overlay** into its own repo via `/sync-ai-instructions`, and today has no way to
answer the only question it ever asks of this repo:

> Did anything change that means I should re-sync — and was it *my* overlay?

The repo's own baseline scaffold checklist lists both `CHANGELOG.md` and `cliff.toml`.
Note this is **not** why the file is being added: base and the overlays are content
published *to consuming projects*, not a description of this repo, so that checklist does
not bind here. The changelog is being added on its own merits, for the audience above.

### What the repo looks like today

Measured 2026-09-10 at `e7dbd26`:

| Fact | Value |
| --- | --- |
| Commits | 77, back to 2026-03-11 |
| Git tags | **0** |
| GitHub releases | **0** |
| Conventional commits | 60 |
| Non-conventional commits | 17 (the early pre-convention era) |
| Distinct commit scopes | 19 |
| `git-cliff` available | yes, 2.10.1 |

---

## Goals

- A consumer can decide **re-sync or not** from this file alone, without reading commits.
- A consumer can find **their** overlay's changes without wading through nine others.
- Generation is reproducible and cheap enough that it actually stays current.
- No new release ritual — the repo has shipped 77 commits with zero tags and keeps that.

## Non-goals

- Versioning, tagging, or GitHub Releases for `ai-instructions`.
- Changing `/sync-ai-instructions` (a **different repo** — see *Open follow-ups*).
- Backfilling the 17 non-conventional early commits.
- A consumer-facing contract about what a "breaking" instruction change means.

---

## Decisions (from brainstorm)

| # | Decision | Rationale |
| --- | --- | --- |
| D1 | Audience is **consumers deciding when to re-sync** | Chosen over "repo history for me" — it is the only question this repo is asked from outside. |
| D2 | **Date sections, no tags** (`## 2026-09-10`) | Consumers already have an anchor (see D3). Tagging would add a release ritual the repo does not have. |
| D3 | Consumers anchor on **their own sync-commit history** | Verified against a real consumer, `BI-ArchiveUploader`: it keeps `.ai/base-instructions.md` and `.ai/stacks/`, and its 7 sync commits are dated — the newest is `docs(ai): sync agent instructions to ai-instructions d5dfd54`, recording the upstream SHA. |
| D4 | Group by **consumer impact**, not commit type | `docs(base)` is a *feature* to a consumer. Keep a Changelog's Added/Fixed/Changed axis answers a question nobody asks here. |
| D5 | Generate with `git-cliff` + `cliff.toml` | Reproducible, already installed, and the config is the place the D4 mapping lives. |
| D6 | **Backfill conventional history only** | 60 commits back to 2026-03-11; the 17 non-conventional ones predate the convention and are mostly workflow-doc scaffolding, not overlay content. |
| D7 | Record a **watermark SHA** in the file | Without tags, `--unreleased` means all history. The watermark makes incremental regeneration possible. |
| D8 | Keep a **"repo only"** group rather than skipping those commits | "Nothing here for me" is more useful to a consumer as a positive signal than as an absence. |

---

## The grouping model

This is the heart of the design. Groups are ordered by how urgently they answer
*"should I re-sync?"*.

| Group | Matches | Why a consumer cares |
| --- | --- | --- |
| `Base — affects every stack` | scopes `base`, `scaffold`, `lint`, `ai` | Every consumer is affected, whatever overlay they run. |
| `Stack overlays` | scopes `browser-game`, `go`, `flutter`, `dotnet`, `dotnet-webapi`, `dotnet-blazor`, `dotnet-library`, `dotnet-fx48-legacy`, `ci`, `ci-overlay`, `quality-gates`, `shell-scripts`, `gdscript-godot` | Scan for your own overlay; ignore the rest. |
| `Stack overlays (unspecified)` | scope `stacks` | 13 commits use this generic scope and some span three overlays at once — it cannot be resolved to one overlay automatically. |
| `Shared skills & commands` | scope `skills` | Consumer-facing: these bodies are copied into the consumer's `.ai/skills/`. |
| `Repo only — no re-sync needed` | bare `ci:` type, scopes `readme`, `repo`, `workflow`, `agent-workflow`, `conventions`, plus `chore:` | Explicitly listed so the reader can confirm nothing applies to them. |
| `Uncategorised` | anything else | Catch-all. A future scope must never vanish silently; entries landing here are a signal to extend the mapping. |

### Scope assignments that are not obvious

Every scope above was checked against the files its commits actually touch, because
three of them classify the opposite of how they read:

- **`lint` is Base, not repo tooling.** `feat(lint): polyglot pre-commit standard +
  template` modifies `.ai/base-instructions.md` itself, plus `.ai/references/base/` and
  `templates/pre-commit/` — and sync seeds that template into the consumer.
- **`conventions` is repo-only, not Base.** It touches `conventions/milestones.md`, a
  top-level directory that sync never copies.
- **`quality-gates` is overlay content, not repo tooling.** It touches
  `.ai/references/dotnet/` and `templates/dotnet/`, both reachable from the .NET overlays.
- **`ci-overlay` is an alias for the `ci` overlay** — same overlay, different scope
  spelling.
- **`ai` is Base** — `refactor(ai): split instructions into stack-agnostic base + stack
  overlays` is the original structural split.

A note on `.ai/references/`: overlays **link** to those files on GitHub rather than
inlining them, so a references change reaches consumers *without* a re-sync. Such entries
still belong in their content group, but the changelog should not imply a re-sync is
required to pick them up.

### The `ci` trap

`ci` means two different things in this history, and grouping on scope alone gets it
wrong:

- **`ci:` as a bare type** — this repo's GitHub Actions and hooks. *No consumer impact.*
  Examples: `ci: enforce assembled CLAUDE.md size budget per stack`,
  `ci: auto-add new issues to freaxnx01 Backlog project`.
- **`(ci)` as a scope** — the **`ci` stack overlay**, which consumers sync.
  Example: `docs(ci): add .gitignore entry to the scaffold checklist (#30)`.

So `commit_parsers` must key on **type and scope together**, and the bare-`ci:` rule must
be ordered *before* any generic fallback.

### Deliberately not carried over from the prior art

`docs/superpowers/plans/2026-07-18-browser-game-stack-overlay.md` Task 5 contains a
`cliff.toml` for a *pilot game repo*. Two of its rules are actively wrong here and are
not reused:

- `{ message = "^chore", skip = true }` and `{ message = "^ci", skip = true }` — these
  drop commits that D8 wants listed under *Repo only*.
- `{ message = "^docs", group = "Documentation" }` — in this repo `docs:` **is** the
  product. Filing it under "Documentation" buries every content change.

---

## Incremental regeneration

With no tags, `git-cliff --unreleased` covers all history, so the file records its own
watermark as the first line after the header:

```markdown
<!-- changelog-covers-through: e7dbd26 -->
```

The regeneration procedure:

1. Read the watermark SHA from `CHANGELOG.md`.
2. `git-cliff <sha>..HEAD --tag $(date +%F) --prepend CHANGELOG.md`
3. Rewrite the watermark to the new `HEAD`.
4. Review the prepended section — edit any entry whose commit subject reads poorly for a
   consumer. Generation produces the draft; the committed file is allowed to be better
   than its commit subjects.

**Verified:** `git-cliff --tag 2026-09-10` renders a `## 2026-09-10` heading and creates
**no git tag** (`git tag -l` stayed empty). This is what makes D2 work with the tool
rather than against it.

If the watermark is missing or unreadable, stop and ask — do **not** fall back to
regenerating all history over an existing file, which silently duplicates every entry.

---

## Backfill

One dated section covering the 60 conventional commits from 2026-03-11 to the watermark.

The 17 non-conventional commits are dropped by `filter_unconventional = true`. The file
says so explicitly, once, near the top — a silent gap would read as "nothing happened
before March".

---

## Verification

- `git-cliff --config cliff.toml` exits clean. A config **error** is a failure, not a
  warning to note.
- Running the regeneration procedure twice in a row produces no duplicate entries
  (idempotence — the watermark is what makes this true).
- Every group in the table above is reachable by at least one real commit in history;
  a group that matches nothing is a mapping bug.
- **Every one of the 19 scopes in history lands in a named group** — nothing falls through
  to `Uncategorised` on the backfill. Anything that does is a mapping gap to fix before
  the file is committed, not after.
- The `ci` trap is covered both ways: a bare `ci:` commit lands in *Repo only*, and a
  `docs(ci)` commit lands under the `ci` overlay.
- `git tag -l` is still empty afterwards.
- `./scripts/check-claude-md-size.sh` is unaffected — neither new file is inlined into
  any assembled `CLAUDE.md`, so the byte budget does not move.

---

## Acceptance criteria

- [ ] `CHANGELOG.md` exists at the repo root with a Keep a Changelog header and
      newest-first date sections.
- [ ] `cliff.toml` exists at the repo root and `git-cliff --config cliff.toml` renders
      without error.
- [ ] Entries are grouped by consumer impact per the grouping model, not by commit type.
- [ ] A bare `ci:` commit appears under *Repo only*; a `docs(ci)` commit appears under the
      `ci` overlay.
- [ ] Backfill covers the conventional history back to 2026-03-11, and the file states
      that non-conventional early commits are not included.
- [ ] The watermark comment is present and names the newest covered commit.
- [ ] No git tags are created — `git tag -l` is empty.
- [ ] Re-running the regeneration procedure produces no duplicate entries.
- [ ] The regeneration procedure is documented in the repo (`CLAUDE.md` Essential
      Commands, alongside `build-stacks.sh` and `check-claude-md-size.sh`).

---

## Open follow-ups (out of scope here)

- **Stamp a version or SHA into the sync header.** `/sync-ai-instructions` prints the
  upstream SHA to the terminal but writes it into no file, so the anchor depends on the
  consumer's commit-message discipline. Fixing that means editing the
  `sync-ai-instructions` plugin — a **different repo** (`freax-agent-skills`
  marketplace) — so it is not folded in here. Not required for this design: D3 shows the
  anchor already exists.
- **Commit-scope hygiene.** Prefer a specific overlay name over the generic `stacks`
  scope going forward, which would shrink the *Stack overlays (unspecified)* group toward
  empty. Convention change, not a code change.
- **`docs:` vs `feat:` for content changes.** History uses both for overlay content
  (`feat(stacks): add Go stack overlay`, `docs(base): add …`). Harmless under this design
  because grouping keys on scope, but worth settling if the changelog ever needs an
  Added/Changed axis.
