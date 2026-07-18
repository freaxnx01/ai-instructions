# browser-game Stack Overlay — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `browser-game` stack overlay to `ai-instructions` that binds base (SemVer, Conventional Commits, git-cliff, changelog, i18n, security) to buildless vanilla HTML/CSS/JS browser games, then pilot it into `game-kick-fury`.

**Architecture:** Single-file overlay `.ai/stacks/browser-game.md` (like `go.md`/`flutter.md` — no `_partials`/`_layers`, untouched by `build-stacks.sh`), wired into the README stacks table. Consumed via `/sync-ai-instructions browser-game`. Versioning is git-tag-authoritative with a `version.js` display mirror shown as an in-game badge. Pilot proves the end-to-end story in one hand-authored game.

**Tech Stack:** Markdown (overlay + docs), Bash (repo's `check-claude-md-size.sh`, `markdownlint-cli2` via pre-commit), vanilla HTML/CSS/JS (the pilot game), git-cliff (changelog).

## Global Constraints

- Overlay file: `.ai/stacks/browser-game.md`, single self-contained file — **no** `_layers/browser-game.md` or `_partials/` entry (else `build-stacks.sh` would try to own it).
- Assembled size ceiling: **base (~14 KB) + overlay < 39,000 bytes**, enforced by `scripts/check-claude-md-size.sh`. Keep the overlay **< 22 KB**.
- Overlay must **bind base to the stack, never repeat base content** (no re-stating SemVer/Conventional-Commits/branching/12-factor prose — reference it).
- Follow the section shape and tone of `.ai/stacks/go.md`.
- Markdown must pass this repo's `.markdownlint-cli2.yaml` (MD013/MD033/MD041 already relaxed there).
- Version single-source-of-truth: **git tag `vX.Y.Z` is authoritative**; `version.js` is a display mirror, not a competing source.
- Conventional Commits for every commit (`feat`/`fix`/`docs`/`chore`(scope): summary).
- Work on branches, PR to `main`; never `git commit --no-verify`.
- ai-instructions work happens on existing branch `feat/browser-game-stack` (spec already committed there). Pilot work happens on a new branch in the `game-kick-fury` repo.

---

## Task 1: Write the `browser-game` overlay

**Files:**

- Create: `ai-instructions/.ai/stacks/browser-game.md`

**Interfaces:**

- Produces: the overlay consumed by `/sync-ai-instructions browser-game` and by Task 2 (README row) and Tasks 3–5 (pilot follows its conventions).

Author the overlay following `.ai/stacks/go.md`'s shape. Each section below lists the **required coverage**; write concise prose (this is a house-style doc, not a tutorial). Concrete artifacts that MUST appear verbatim are given in full.

- [ ] **Step 1: Provenance header + intro**

First line, exactly:

```markdown
[//]: # (Stack overlay — loaded together with .ai/base-instructions.md for buildless browser-game projects)

# Browser Game Stack Overlay
```

Intro (2 short paragraphs): applies on top of `.ai/base-instructions.md` for the `game-*` repos — vanilla HTML/CSS/JS games shipped as **static GitHub Pages** under `https://github.freaxnx01.ch/game-<name>/`, no build step required to ship. Name example repos (`game-space-invaders`, `game-kick-fury`, `game-tank-toys`).

- [ ] **Step 2: `## Tech Stack` table**

Rows (Layer | Technology): Language — vanilla ES-module or classic-script JS (no framework); Markup — semantic HTML5; Styling — modern CSS (custom properties, grid/flex), no CSS framework required; Rendering — `<canvas>` 2D/WebGL + `requestAnimationFrame` (DOM/SVG for non-canvas games); Audio — Web Audio API / `<audio>`; Multiplayer — manual WebRTC (`RTCPeerConnection` + data channel), **no signaling server / PeerJS / Firebase**; Persistence — `localStorage` for scores/settings; Hosting — GitHub Pages (static, served from repo root `index.html`); Build — **none required**; a few games use a source→`index.html` bundler (dc-tool), noted below; Versioning — git tag + `version.js` mirror; Changelog — `git-cliff` + `cliff.toml`; Lint/format (optional) — `npx prettier` / `npx eslint`, nothing committed.

- [ ] **Step 3: `## Project Structure`**

Document the realistic spread (do not force one layout):

```text
# Minimal (most games)
index.html              ← the whole game (inline <style> + <script>)
README.md  LICENSE

# Richer / P2P game
index.html              ← markup + boot
game.js  (or *-game.js) ← game logic (classic script or ES module)
version.js              ← VERSION mirror (see Versioning)
style.css               ← if split out
assets/                 ← sprites, audio
vendor/                 ← third-party libs vendored (no npm)
CHANGELOG.md  cliff.toml  README.md  LICENSE

# Bundled game (dc-tool)
source/ or *.dc.html    ← EDIT THIS
index.html  support.js  ← GENERATED — do not hand-edit
```

State the rule: **for bundled games (`data-dc-script` / `type="text/x-dc"` marker in `index.html`), edit the source and re-bundle — never hand-edit the generated `index.html`/`support.js`.**

- [ ] **Step 4: `## JavaScript Conventions`**

Cover: prefer ES modules (`<script type="module">`) for multi-file games; a single-file game may use one inline `<script>`. `const`/`let` only. No leaking game internals onto `window` (the deliberate exception is the `version.js` global for non-module games). Separate **state** from **render** from **input**. Small pure update functions (base Clean Code applies — reference it, don't restate). No framework, no jQuery.

- [ ] **Step 5: `## Game Loop`**

Cover: fixed-timestep simulation + `requestAnimationFrame` render; accumulator pattern with `deltaTime`; pause/resume on `document.visibilitychange`; input sampled into a state object, never mutating simulation directly from event handlers; simulation must be **deterministic** when P2P lockstep is used.

- [ ] **Step 6: `## P2P Multiplayer (house pattern)`**

Cover: manual WebRTC — one peer creates an offer, the other an answer, **copy-pasted** by players (or shown as codes); no signaling server, no PeerJS, no Firebase. One data channel for game messages. **Validate every inbound data-channel message** before applying (never `eval`, never trust peer for authority-critical state — use host-authoritative or lockstep). Handle `connectionstatechange` for graceful disconnect + rematch. This matches `game-tank-toys`, `game-kick-fury`, etc.

- [ ] **Step 7: `## Versioning (stack binding)`** — the core section

Cover, verbatim intent: git tag `vX.Y.Z` on `main` is the **single source of truth**; `version.js` **mirrors** it and is bumped at release; rendered as a small `vX.Y.Z` badge (menu/footer/about). Include **both** forms:

```js
// version.js — ES-module game
export const VERSION = "1.0.0"; // must equal the latest git tag vX.Y.Z

// version.js — classic-script game (no modules); load BEFORE the game script
window.GAME_VERSION = "1.0.0";  // must equal the latest git tag vX.Y.Z
```

Release flow (show as a block):

```bash
# 1. bump version.js to the new X.Y.Z
# 2. commit
git commit -am "chore(release): v1.2.0"
# 3. tag on main (authoritative)
git tag v1.2.0
# 4. regenerate changelog from Conventional Commits
git cliff --tag v1.2.0 -o CHANGELOG.md
git commit -am "docs(changelog): v1.2.0"
git push --follow-tags
```

State explicitly: **do not** add a second version source (no `<meta name="version">` + JSON + const all at once) — tag is truth, `version.js` mirrors it.

- [ ] **Step 8: `## Changelog`**

Adopt base (reference it). `CHANGELOG.md` (Keep a Changelog) with `[Unreleased]`; `cliff.toml` using the Conventional Commits preset; optional `orhun/git-cliff-action` for GitHub Release notes. Provide the minimal `cliff.toml` used by the pilot (see Task 5, Step 3) as the canonical starting point.

- [ ] **Step 9: `## Tooling & Testing`**

Cover: buildless — **manual in-browser playtest is the test gate**. Checklist of what to verify manually: page loads with an empty console, canvas/DOM renders, core loop + input respond, `localStorage` persists, P2P connects both ends and survives a disconnect. Optional `npx prettier --write .` / `npx eslint .` on demand — no committed `package.json`/`node_modules`. **Explicit deviation note:** base mandates TDD-first; buildless games substitute disciplined manual verification because there is no build/test toolchain to ship — state this so it is a deliberate, documented deviation, not an oversight.

- [ ] **Step 10: `## Localization (i18n)`**

Base's de/en rule applies to games with meaningful UI text. Give the lightweight vanilla pattern: a `strings` object keyed by locale, `navigator.language` detection, a switcher, choice persisted in `localStorage`. State the carve-out: pure-arcade games with negligible text may defer; text-heavy games (quizzes) must comply.

- [ ] **Step 11: `## Games Hub Integration`**

Cross-repo: each game gets a card in `freaxnx01.github.io/games/index.html`; screenshots via that repo's `scripts/capture_screenshots.py`; the `NEW` tag convention. Note the hub lives in the **site repo**, not the game repo — adding/updating a card is a change over there.

- [ ] **Step 12: `## Security`**

Client JS is fully public → never embed secrets/API keys. Validate WebRTC data-channel + `postMessage` input at the boundary (base rule, bound to this stack). External resources (fonts, CDNs, GitHub buttons) over HTTPS only. Never `eval`/`new Function` on remote or peer content.

- [ ] **Step 13: `## Essential Commands`**

```bash
# Serve locally (buildless)
python3 -m http.server 8000        # then open http://localhost:8000/
# or just open index.html in a browser

# Optional lint/format (nothing committed)
npx prettier --write .
npx eslint .

# Release (see Versioning)
git tag v1.2.0 && git cliff --tag v1.2.0 -o CHANGELOG.md

# Regenerate hub screenshot (run in the freaxnx01.github.io repo)
python3 scripts/capture_screenshots.py
```

- [ ] **Step 14: `## Project Scaffold Checklist (browser-game)`**

Checklist items: `index.html` served at repo root; `version.js` with the version constant/global; version badge wired into the UI; `CHANGELOG.md` with `[Unreleased]`; `cliff.toml`; `.gitignore` including `.worktrees/`; `README.md`; `LICENSE`; hub card added in `freaxnx01.github.io/games/index.html`; `CLAUDE.md`/`SKILL.md`/`.github/copilot-instructions.md` synced from base + this overlay; branch protection on `main`.

- [ ] **Step 15: `## Agent Guardrails (stack-specific)` + `### Never generate (this stack)`**

Guardrails (additions to base): don't add a framework, bundler, `package.json`, or committed `node_modules` without asking; don't introduce a signaling server or P2P library; keep the game shippable as static files; keep `version.js` equal to the latest tag; **never hand-edit a bundled `index.html`/`support.js` — edit the source**; don't embed secrets in client JS.

Never generate: framework imports (React/Vue/Angular/Svelte/jQuery); a bundler/`package.json`/`node_modules` committed into a game; secrets/keys in client JS; a second competing version source; PeerJS/Firebase/signaling-server P2P; `eval`/`new Function` on peer/remote input; commented-out code blocks; a hand-edited generated bundle.

- [ ] **Step 16: Verify markdownlint passes**

Run (from `ai-instructions/`):

```bash
npx --yes markdownlint-cli2 ".ai/stacks/browser-game.md"
```

Expected: `Linting: 1 file(s)` … `Summary: 0 error(s)`. Fix any reported rule violations in the file until zero errors.

- [ ] **Step 17: Verify assembled size is under budget**

Run (from `ai-instructions/`):

```bash
./scripts/check-claude-md-size.sh
```

Expected: a table row `browser-game  <bytes>  <assembled>  ok` and overall exit 0. If it prints `FAIL (>39000)`, trim the overlay (target overlay < 22 KB) and re-run. Confirm the overlay's own size:

```bash
wc -c .ai/stacks/browser-game.md   # expect < 22000
```

- [ ] **Step 18: Commit**

```bash
cd ai-instructions
git add .ai/stacks/browser-game.md
git commit -m "feat(stacks): add browser-game overlay

Buildless vanilla HTML/CSS/JS browser games served as static GitHub
Pages. Binds base SemVer/Conventional-Commits/git-cliff to the stack via
a git-tag-authoritative version with a version.js display mirror; adds
canvas game-loop, manual-WebRTC P2P, i18n, and hub-integration rules."
```

---

## Task 2: Wire `browser-game` into the README

**Files:**

- Modify: `ai-instructions/README.md` (Supported stacks table ~line 124-131; single-file-overlay mention ~line 10 and ~line 85)

**Interfaces:**

- Consumes: the overlay file from Task 1.
- Produces: discoverable stack listing; no code interface.

- [ ] **Step 1: Add the Supported-stacks table row**

In the `## Supported stacks` table, add after the `ci` row:

```markdown
| `browser-game` | `.ai/stacks/browser-game.md` | Vanilla HTML/CSS/JS browser games · static GitHub Pages · `<canvas>` + rAF game loop · manual-WebRTC P2P · git-tag + `version.js` versioning · git-cliff changelog · buildless (manual playtest gate) |
```

- [ ] **Step 2: Add to the single-file-overlays mention**

In the TL;DR bullet that lists single-file overlays (`flutter.md`, `go.md`, `ci.md`, `dotnet-fx48-legacy.md`), append `browser-game.md` to that list. Do the same in the repository-layout section if it enumerates single-file overlays.

- [ ] **Step 3: Verify markdownlint passes**

```bash
cd ai-instructions && npx --yes markdownlint-cli2 "README.md"
```

Expected: `Summary: 0 error(s)`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): list browser-game stack"
```

---

## Task 3: Pilot — sync instructions into `game-kick-fury`

**Files:**

- Create (via sync): `game-kick-fury/CLAUDE.md`, `game-kick-fury/.github/copilot-instructions.md`, `game-kick-fury/SKILL.md`, `game-kick-fury/.ai/base-instructions.md`, `game-kick-fury/.ai/stacks/browser-game.md`

**Interfaces:**

- Consumes: the `browser-game` overlay (Task 1). The sync skill fetches from `ai-instructions` `main` by default — since the overlay is not yet merged, run the sync against the local working copy, or merge Task 1–2 first (see Task 6 note). If the skill supports a local source, point it at the `ai-instructions` checkout; otherwise land the ai-instructions PR first, then sync.
- Produces: the synced instruction files consumed by later human/agent sessions.

- [ ] **Step 1: Branch**

```bash
cd game-kick-fury
git checkout main && git pull
git checkout -b feat/adopt-browser-game-instructions
```

- [ ] **Step 2: Run the sync skill**

From inside `game-kick-fury`, invoke `/sync-ai-instructions browser-game`. When it lists the source commit SHA, record it in the PR later.

- [ ] **Step 3: Verify files exist and CLAUDE.md is under budget**

```bash
ls CLAUDE.md SKILL.md .github/copilot-instructions.md .ai/stacks/browser-game.md
wc -c CLAUDE.md            # expect < 39000
```

Expected: all files present; `CLAUDE.md` under 39,000 bytes. Open `CLAUDE.md` and confirm it reads as a browser-game project (canvas/P2P/versioning sections present, no .NET/Go content).

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md SKILL.md .github/copilot-instructions.md .ai/
git commit -m "chore(ai): sync browser-game agent instructions"
```

---

## Task 4: Pilot — add `version.js` + in-game version badge

**Files:**

- Create: `game-kick-fury/version.js`
- Modify: `game-kick-fury/index.html` (add `<script src="./version.js"></script>` before the inline game `<script>` at line ~73; render the badge in the existing footer nav)

**Interfaces:**

- Consumes: nothing.
- Produces: `window.GAME_VERSION` global read by the badge renderer. (kick-fury uses a single inline non-module `<script>`, so the classic-script form is correct here.)

- [ ] **Step 1: Create `version.js`**

```js
// version.js — display mirror of the authoritative git tag vX.Y.Z.
// Bump this to match the tag at release time (see CHANGELOG.md / release flow).
window.GAME_VERSION = "1.0.0";
```

- [ ] **Step 2: Load it before the game script**

In `index.html`, immediately before the opening inline `<script>` (around line 73), add:

```html
<script src="./version.js"></script>
```

- [ ] **Step 3: Render the badge in the footer nav**

In the existing footer nav markup, add a version element:

```html
<span class="version-badge" id="version-badge"></span>
```

And in the inline game script (near boot), populate it:

```js
document.getElementById('version-badge').textContent =
  'v' + (window.GAME_VERSION || '0.0.0');
```

Add a minimal, unobtrusive style near the game's other CSS (small, muted):

```css
.version-badge { font-size: 0.75rem; opacity: 0.6; margin-left: 0.5rem; }
```

- [ ] **Step 4: Verify in a browser (the test gate)**

```bash
cd game-kick-fury && python3 -m http.server 8000
```

Open `http://localhost:8000/`. Confirm: the footer shows `v1.0.0`; the browser console is empty (no errors); the game still starts and responds to input. Stop the server (Ctrl-C). If a headless check is preferred, load the page with the site repo's Playwright setup and assert `#version-badge` text is `v1.0.0` and `console` had no errors.

- [ ] **Step 5: Commit**

```bash
git add version.js index.html
git commit -m "feat(version): show v1.0.0 badge from version.js"
```

---

## Task 5: Pilot — add `CHANGELOG.md`, `cliff.toml`, and establish v1.0.0

**Files:**

- Create: `game-kick-fury/CHANGELOG.md`, `game-kick-fury/cliff.toml`
- Modify: `game-kick-fury/.gitignore` (create if absent; add `.worktrees/`)

**Interfaces:**

- Consumes: `version.js` version (`1.0.0`) from Task 4 — the changelog's first released version must match.
- Produces: the release scaffolding for future `git-cliff` runs.

- [ ] **Step 1: Create `CHANGELOG.md`**

```markdown
# Changelog

All notable changes to this project are documented here, following
[Keep a Changelog](https://keepachangelog.com) and
[Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.0.0] - 2026-07-18

### Added
- Initial versioned release of Kick Fury (retro Amiga-style kickboxing:
  1P vs CPU, local, and manual-WebRTC P2P).
- In-game version badge sourced from `version.js`.
```

- [ ] **Step 2: Create `cliff.toml`**

```toml
# git-cliff configuration — Conventional Commits -> Keep a Changelog.
[changelog]
header = "# Changelog\n\n"
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
{% endfor %}
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  { message = "^feat", group = "Added" },
  { message = "^fix", group = "Fixed" },
  { message = "^perf", group = "Changed" },
  { message = "^refactor", group = "Changed" },
  { message = "^docs", group = "Documentation" },
  { message = "^chore\\(release\\)", skip = true },
  { message = "^chore", skip = true },
  { message = "^ci", skip = true },
  { message = "^test", skip = true },
]
tag_pattern = "v[0-9]*"
```

- [ ] **Step 3: Ensure `.gitignore` ignores worktrees**

Create or append to `game-kick-fury/.gitignore`:

```gitignore
.worktrees/
```

- [ ] **Step 4: Verify git-cliff parses (if installed)**

```bash
cd game-kick-fury
command -v git-cliff && git cliff --unreleased || echo "git-cliff not installed — skipping (config is still valid)"
```

Expected: either a rendered `[Unreleased]` section (or "no unreleased commits") with no config error, or the skip message. A config **error** is a failure — fix `cliff.toml`.

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md cliff.toml .gitignore
git commit -m "docs(changelog): add CHANGELOG + cliff.toml, baseline v1.0.0"
```

---

## Task 6: Open PRs and verify CI

**Files:** none (git/GitHub operations)

**Interfaces:**

- Consumes: branches from Tasks 1–2 (`ai-instructions`) and Tasks 3–5 (`game-kick-fury`).

- [ ] **Step 1: Push and PR the overlay (ai-instructions)**

```bash
cd ai-instructions
git push -u origin feat/browser-game-stack
gh pr create --fill --title "feat(stacks): add browser-game overlay"
```

- [ ] **Step 2: Verify ai-instructions CI is green**

```bash
gh pr checks --watch
```

Expected: `build-stacks-drift` (runs `check-claude-md-size.sh`) and `lint` both pass. If size fails, return to Task 1 Step 17 and trim.

- [ ] **Step 3: Push and PR the pilot (game-kick-fury)**

Note: if `/sync-ai-instructions` in Task 3 required the overlay to be on `main`, merge the ai-instructions PR first, then re-run the sync so the synced files reference the merged SHA.

```bash
cd game-kick-fury
git push -u origin feat/adopt-browser-game-instructions
gh pr create --fill --title "chore: adopt browser-game instructions + versioning"
```

- [ ] **Step 4: Verify the pilot loads once more**

Re-run the browser check from Task 4 Step 4 against the branch tip; confirm badge `v1.0.0`, empty console, game plays. Record the result in the PR body.

- [ ] **Step 5: Post-merge release tag (documented, do after merge)**

After the pilot PR merges to `main`:

```bash
cd game-kick-fury && git checkout main && git pull
git tag v1.0.0 && git push --tags
```

This makes the tag (authoritative source) match `version.js` and the `CHANGELOG.md` `[1.0.0]` entry.

---

## Notes for the executor

- The overlay task (Task 1) is a single large deliverable with one review gate — the two verification commands (markdownlint, size check) are its gates. Do not split it into per-section commits.
- `game-kick-fury` is intentionally the pilot because it is a single hand-authored `index.html` with an inline non-module script — hence `version.js` uses the `window.GAME_VERSION` global, not an ES-module `export`. Do not convert kick-fury to modules; keep the change surgical.
- Never hand-edit a generated bundle in any game; kick-fury is not bundled, so this does not bite here, but the overlay must still say it.
