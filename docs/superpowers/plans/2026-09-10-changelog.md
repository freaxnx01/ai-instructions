# CHANGELOG.md for `ai-instructions` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `git-cliff`-generated, date-sectioned, tagless `CHANGELOG.md` whose entries are grouped by consumer impact, so a consuming project can decide whether to re-run `/sync-ai-instructions`.

**Architecture:** Two new root files — `cliff.toml` (the generation config, where the scope→consumer-impact mapping lives) and `CHANGELOG.md` (generated, then committed). No git tags: `git-cliff --tag <date>` names a dated section without creating one. Incremental regeneration is anchored by a watermark comment inside `CHANGELOG.md`, because with no tags `--unreleased` means all history.

**Tech Stack:** `git-cliff` 2.10.1 (already installed at `/home/admin/.local/bin/git-cliff`), Conventional Commits, Keep a Changelog, Tera templates (git-cliff's template language).

**Spec:** [`docs/superpowers/specs/2026-09-10-changelog-design.md`](../specs/2026-09-10-changelog-design.md)

## Global Constraints

- **This is a content repo, not an application.** There is no compiler, package manager, or test runner. "Tests" here are `git-cliff` runs and `grep`/`awk` assertions over its output.
- **Never create a git tag.** `git tag -l` must be empty when this plan finishes. The dated section comes from `--tag <date>`, which does not write a tag.
- **Do not edit** `.ai/stacks/dotnet-blazor.md` or `.ai/stacks/dotnet-webapi.md` — they are generated. This plan does not touch them.
- **Byte budget:** `./scripts/check-claude-md-size.sh` must still report all ten stacks `ok`. Neither new file is inlined into an assembled `CLAUDE.md`, so the numbers should not move at all. The pre-commit hook runs this and **rejects** a commit that breaks it.
- **Never use `--no-verify`.** The pre-commit hook is a required gate.
- **`main` is protected** (required check: `pre-commit`, no required reviews). Work on a branch and open a PR; do not push to `main`.
- Commit messages follow Conventional Commits, scoped by area: `docs(changelog): …`.
- The exact date string `2026-09-10` appears in the backfill section heading. If implementing on a later date, use that later date consistently everywhere — but the watermark SHA must still be the real `HEAD` at generation time.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `cliff.toml` (create, root) | Generation config: the changelog template and the scope→group `commit_parsers` mapping. The single place the grouping model lives. |
| `CHANGELOG.md` (create, root) | The generated, committed artifact. Carries the Keep a Changelog header, the watermark comment, the coverage note, and dated sections newest-first. |
| `CLAUDE.md` (modify, "Essential Commands" section) | Documents the regeneration procedure alongside `build-stacks.sh` and `check-claude-md-size.sh`. Without this the watermark ritual is undiscoverable. |

Three tasks, one per file, in that order — each is independently reviewable and the later ones consume the earlier ones' output.

---

## Task 1: Create `cliff.toml` with the consumer-impact mapping

**Files:**
- Create: `cliff.toml`

**Interfaces:**
- Produces: a `cliff.toml` that `git-cliff --config cliff.toml` accepts, rendering exactly six group headings in this order: `Base — affects every stack`, `Stack overlays`, `Stack overlays (unspecified)`, `Shared skills & commands`, `Unscoped or unmapped — see the commit`, `Repo only — no re-sync needed`.
- Produces: the entry format Task 2's tripwire depends on — scoped entries render as `- **scope** — subject`, unscoped ones as `- subject`.

- [ ] **Step 1: Write the failing test**

There is no test framework here, so the test is a shell script. Create `/tmp/changelog-test.sh`:

```bash
#!/usr/bin/env bash
# Verifies cliff.toml renders the six consumer-impact groups, in order,
# with no scoped commit leaking into the catch-all group.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

out=$(mktemp)
if ! git-cliff --config cliff.toml --unreleased --tag 2026-09-10 >"$out" 2>/tmp/cliff-err.txt; then
  echo "FAIL: git-cliff errored"; cat /tmp/cliff-err.txt; exit 1
fi

expected="Base — affects every stack
Stack overlays
Stack overlays (unspecified)
Shared skills & commands
Unscoped or unmapped — see the commit
Repo only — no re-sync needed"

actual=$(grep '^### ' "$out" | sed 's/^### //')
if [ "$actual" != "$expected" ]; then
  echo "FAIL: group headings wrong or out of order"
  diff <(echo "$expected") <(echo "$actual")
  exit 1
fi

# Tripwire: a scoped entry inside the catch-all means the mapping has a gap.
leak=$(awk '/^### Unscoped or unmapped/{f=1;next} /^### /{f=0} f&&/^- \*\*/' "$out")
if [ -n "$leak" ]; then
  echo "FAIL: scoped commits leaked into the catch-all group:"; echo "$leak"; exit 1
fi

# The ci trap, both directions.
bare_ci=$(awk '/^### /{h=$0} /enforce assembled CLAUDE.md size budget/{print h}' "$out")
[ "$bare_ci" = "### Repo only — no re-sync needed" ] || { echo "FAIL: bare 'ci:' not in Repo only (got: $bare_ci)"; exit 1; }
scoped_ci=$(awk '/^### /{h=$0} /add .gitignore entry to the scaffold checklist/{print h}' "$out")
[ "$scoped_ci" = "### Stack overlays" ] || { echo "FAIL: 'docs(ci)' not in Stack overlays (got: $scoped_ci)"; exit 1; }

# Determinism.
out2=$(mktemp)
git-cliff --config cliff.toml --unreleased --tag 2026-09-10 >"$out2" 2>/dev/null
cmp -s "$out" "$out2" || { echo "FAIL: output not deterministic"; exit 1; }

# No tags may exist.
[ "$(git tag -l | wc -l)" -eq 0 ] || { echo "FAIL: git tags exist"; exit 1; }

echo "PASS"
```

Make it executable: `chmod +x /tmp/changelog-test.sh`

- [ ] **Step 2: Run it to verify it fails**

Run: `/tmp/changelog-test.sh`

Expected: `FAIL: git-cliff errored` — `cliff.toml` does not exist yet.

- [ ] **Step 3: Write `cliff.toml`**

This exact content is verified working against this repo's history with git-cliff 2.10.1. Note the em dashes (`—`) inside the group names — they must be preserved, since the test compares heading strings exactly.

```toml
# git-cliff configuration for ai-instructions.
#
# Entries are grouped by CONSUMER IMPACT, not by Conventional Commits type,
# because the audience is a consuming project asking "should I re-sync, and
# was it my overlay?". A `docs(base)` commit is a *feature* to that reader.
#
# The `<!-- N -->` prefixes only order the groups; `striptags` removes them
# from the rendered heading.
#
# See docs/superpowers/specs/2026-09-10-changelog-design.md for the rationale,
# including why three scopes classify opposite to how they read.

[changelog]
header = "# Changelog\n\n"
body = """
## {{ version | default(value="Unreleased") }}
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim }}
{% for commit in commits %}
- {% if commit.scope %}**{{ commit.scope }}** — {% endif %}{{ commit.message }}
{% endfor %}
{% endfor %}
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  # Bare `ci:` is this repo's own Actions/hooks — NOT the `ci` stack overlay,
  # which arrives as a *scope* and is matched further down. This rule must stay
  # above the scope rules so the two never collide.
  { message = "^ci(\\([^)]*\\))?: ", group = "<!-- 5 -->Repo only — no re-sync needed" },
  { message = "^chore", group = "<!-- 5 -->Repo only — no re-sync needed" },

  # `lint` and `ai` are Base: both modify .ai/base-instructions.md itself.
  { field = "scope", pattern = "^(base|scaffold|lint|ai)$", group = "<!-- 0 -->Base — affects every stack" },

  # `ci-overlay` is an alias for the ci overlay; `quality-gates` is .NET content.
  { field = "scope", pattern = "^(browser-game|go|flutter|dotnet|dotnet-webapi|dotnet-blazor|dotnet-library|dotnet-fx48-legacy|ci|ci-overlay|quality-gates|shell-scripts|gdscript-godot)$", group = "<!-- 1 -->Stack overlays" },

  # Generic scope spanning several overlays at once — cannot be resolved.
  { field = "scope", pattern = "^stacks$", group = "<!-- 2 -->Stack overlays (unspecified)" },

  { field = "scope", pattern = "^skills$", group = "<!-- 3 -->Shared skills & commands" },

  # `conventions` is repo-only: it touches conventions/, which sync never copies.
  { field = "scope", pattern = "^(readme|repo|workflow|agent-workflow|conventions|changelog)$", group = "<!-- 5 -->Repo only — no re-sync needed" },

  # Catch-all. Holds the 16 scope-less commits, and any future unmapped scope.
  # A `field = "scope", pattern = ".+"` tripwire does NOT work here: git-cliff
  # 2.10.1 matches `.+` against a missing scope too. The tripwire is the
  # template instead — see the spec.
  { message = ".*", group = "<!-- 4 -->Unscoped or unmapped — see the commit" },
]
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `/tmp/changelog-test.sh`

Expected: `PASS`

If it reports wrong headings, check that the em dashes survived copy-paste. If it reports a leak, a scope is missing from the mapping — add it to the appropriate `pattern` and re-run.

- [ ] **Step 5: Commit**

```bash
git add cliff.toml
git commit -m "docs(changelog): add cliff.toml with consumer-impact grouping"
```

---

## Task 2: Generate and commit `CHANGELOG.md`

**Files:**
- Create: `CHANGELOG.md`

**Interfaces:**
- Consumes: `cliff.toml` from Task 1, and its `- **scope** — subject` entry format.
- Produces: `CHANGELOG.md` containing the watermark comment `<!-- changelog-covers-through: <sha> -->`, which Task 3's documented procedure reads.

- [ ] **Step 1: Write the failing test**

Create `/tmp/changelog-file-test.sh`:

```bash
#!/usr/bin/env bash
# Verifies the committed CHANGELOG.md is well-formed.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

[ -f CHANGELOG.md ] || { echo "FAIL: CHANGELOG.md missing"; exit 1; }

head -1 CHANGELOG.md | grep -q '^# Changelog$' \
  || { echo "FAIL: first line is not '# Changelog'"; exit 1; }

# Watermark present and naming a real commit.
sha=$(grep -oP '(?<=<!-- changelog-covers-through: )[0-9a-f]{7,40}(?= -->)' CHANGELOG.md | head -1)
[ -n "$sha" ] || { echo "FAIL: watermark comment missing or malformed"; exit 1; }
git cat-file -e "${sha}^{commit}" 2>/dev/null \
  || { echo "FAIL: watermark $sha is not a commit in this repo"; exit 1; }

# The coverage caveat must be stated, not implied.
grep -qi 'non-conventional' CHANGELOG.md \
  || { echo "FAIL: file does not state that non-conventional commits are excluded"; exit 1; }

# At least one dated section heading, YYYY-MM-DD.
grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md \
  || { echo "FAIL: no dated '## YYYY-MM-DD' section"; exit 1; }

# Tripwire on the committed file.
leak=$(awk '/^### Unscoped or unmapped/{f=1;next} /^### /{f=0} f&&/^- \*\*/' CHANGELOG.md)
[ -z "$leak" ] || { echo "FAIL: scoped commits in the catch-all:"; echo "$leak"; exit 1; }

# Still no tags.
[ "$(git tag -l | wc -l)" -eq 0 ] || { echo "FAIL: git tags exist"; exit 1; }

echo "PASS"
```

`chmod +x /tmp/changelog-file-test.sh`

- [ ] **Step 2: Run it to verify it fails**

Run: `/tmp/changelog-file-test.sh`

Expected: `FAIL: CHANGELOG.md missing`

- [ ] **Step 3: Generate the body**

```bash
git-cliff --config cliff.toml --unreleased --tag "$(date +%F)" > /tmp/changelog-body.md
```

Inspect it — `head -40 /tmp/changelog-body.md`. Expect `# Changelog`, then `## <today>`, then the six group headings with ~61 entries.

- [ ] **Step 4: Assemble `CHANGELOG.md` with the header block**

`git-cliff` emits `# Changelog` plus the dated section. The watermark and the caveat have to be inserted between them, so build the file rather than using the raw output:

```bash
SHA=$(git rev-parse --short HEAD)
BODY_TAIL=$(tail -n +2 /tmp/changelog-body.md)   # everything after '# Changelog'

cat > CHANGELOG.md <<EOF
# Changelog

<!-- changelog-covers-through: ${SHA} -->

All notable changes to \`ai-instructions\` are documented here, following
[Keep a Changelog](https://keepachangelog.com). Sections are dated rather than
versioned: this repo carries no tags or releases.

**Who this is for.** You sync \`base-instructions.md\` + one stack overlay into your own
project. This file answers one question: *has anything changed that means you should
re-run \`/sync-ai-instructions\`, and was it your overlay?* Groups are ordered by that —
\`Base\` affects everyone, \`Stack overlays\` is where you look for your own, and
\`Repo only\` never needs a re-sync.

To find what is new for you, compare against the date of your last sync commit
(\`git log -1 --format=%ad -- .ai/base-instructions.md\` in your project).

Entries are generated from Conventional Commits with \`git-cliff\`. Commits predating that
convention — 17 of them, in the earliest history — are **not** included; see \`git log\` for
those. Files under \`.ai/references/\` are linked by the overlays rather than inlined, so
changes there reach you without a re-sync.
${BODY_TAIL}
EOF
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `/tmp/changelog-file-test.sh`

Expected: `PASS`

- [ ] **Step 6: Confirm the byte budget did not move**

Run: `./scripts/check-claude-md-size.sh`

Expected: all ten stacks `ok`. Neither new file is inlined into an assembled `CLAUDE.md`, so every number should be unchanged from before this plan started.

- [ ] **Step 7: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): add CHANGELOG.md, backfilled to 2026-03-11"
```

---

## Task 3: Document the regeneration procedure in `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` — the `## Essential Commands` section

**Interfaces:**
- Consumes: the watermark comment written by Task 2.

- [ ] **Step 1: Write the failing test**

Create `/tmp/changelog-docs-test.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

grep -q 'changelog-covers-through' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md does not mention the watermark"; exit 1; }
grep -q 'git-cliff' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md does not mention git-cliff"; exit 1; }
grep -q 'There is no compiler, package manager, or test runner in this repo' CLAUDE.md \
  || { echo "FAIL: the existing closing line of Essential Commands was lost"; exit 1; }
echo "PASS"
```

`chmod +x /tmp/changelog-docs-test.sh`

- [ ] **Step 2: Run it to verify it fails**

Run: `/tmp/changelog-docs-test.sh`

Expected: `FAIL: CLAUDE.md does not mention the watermark`

- [ ] **Step 3: Add the block to `## Essential Commands`**

In `CLAUDE.md`, the `## Essential Commands` section ends with a fenced block followed by the line `There is no compiler, package manager, or test runner in this repo.` Insert this **immediately before** that line, keeping it:

````markdown
```bash
# Regenerate CHANGELOG.md after new commits land on main.
# The repo has no tags, so `--unreleased` would mean ALL history — the
# watermark comment in CHANGELOG.md is what bounds the range instead.
SHA=$(grep -oP '(?<=<!-- changelog-covers-through: )[0-9a-f]+' CHANGELOG.md)
git-cliff --config cliff.toml "${SHA}..HEAD" --tag "$(date +%F)" --prepend CHANGELOG.md
# then update the watermark to the new HEAD:
sed -i "s/changelog-covers-through: ${SHA}/changelog-covers-through: $(git rev-parse --short HEAD)/" CHANGELOG.md
```

Review the prepended section before committing — edit any entry whose commit subject
reads poorly for a consumer. Generation produces the draft; the committed file is allowed
to be better than its commit subjects.

If the watermark is missing or unreadable, **stop and ask** — regenerating all history
over the existing file silently duplicates every entry.
````

- [ ] **Step 4: Run the test to verify it passes**

Run: `/tmp/changelog-docs-test.sh`

Expected: `PASS`

- [ ] **Step 5: Verify the incremental path actually works**

This is the one step that exercises the documented procedure end-to-end. Run it on a
throwaway copy so a mistake cannot corrupt the committed file:

```bash
cp CHANGELOG.md /tmp/CHANGELOG.backup
SHA=$(grep -oP '(?<=<!-- changelog-covers-through: )[0-9a-f]+' CHANGELOG.md)
git-cliff --config cliff.toml "${SHA}..HEAD" --tag "$(date +%F)" --prepend CHANGELOG.md
grep -c '^- ' CHANGELOG.md   # compare to the backup's count
diff /tmp/CHANGELOG.backup CHANGELOG.md
```

Expected: the diff shows **only** newly added entries for commits after the watermark
(the Task 1 and Task 2 commits), with no duplication of the backfilled entries. Then
restore, since the watermark is still correct for the committed state:

```bash
cp /tmp/CHANGELOG.backup CHANGELOG.md
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(changelog): document the regeneration procedure"
```

---

## Task 4: Open the PR

**Files:** none (git/GitHub operations)

- [ ] **Step 1: Confirm the full suite passes**

```bash
/tmp/changelog-test.sh && /tmp/changelog-file-test.sh && /tmp/changelog-docs-test.sh
./scripts/check-claude-md-size.sh
git tag -l | wc -l    # must be 0
```

Expected: three `PASS` lines, ten `ok` rows, and `0`.

- [ ] **Step 2: Push and open the PR**

```bash
git push -u origin HEAD
gh pr create --base main \
  --title "docs(changelog): add a consumer-facing CHANGELOG.md" \
  --body "Closes #31. See docs/superpowers/specs/2026-09-10-changelog-design.md for the design."
```

- [ ] **Step 3: Verify checks pass**

```bash
gh pr checks --watch
```

Expected: `check-drift` and `pre-commit` both pass. Do **not** merge without asking.

---

## Notes for the executor

- **The em dashes matter.** Group names in `cliff.toml` contain `—` (U+2014), and the tests compare heading strings exactly. A copy-paste that mangles them fails Task 1 Step 4 with a heading diff.
- **Do not "fix" the `Unscoped or unmapped` group by inventing scopes** for the 16 historical commits. Rewriting history is out of scope; the group existing is the designed outcome.
- **Do not add a `field = "scope", pattern = ".+"` parser** as a tripwire. It looks correct and is not — git-cliff 2.10.1 matches `.+` against a missing scope, so it swallows the unscoped commits. The template-based tripwire in the tests is the working substitute.
- **`--tag` does not create a tag.** If you find yourself running `git tag`, stop — a Global Constraint is being violated.
- If `git-cliff` is not on `PATH`, it is at `/home/admin/.local/bin/git-cliff`.
