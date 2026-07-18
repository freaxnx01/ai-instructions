# Design — `browser-game` stack overlay

**Date:** 2026-07-18
**Status:** Approved (brainstorm) — pending implementation plan
**Repo:** `freaxnx01/ai-instructions`

## Problem

The `game-*` repos (23 live browser games served as static GitHub Pages under
`https://github.freaxnx01.ch/game-<name>/`) have **no AI-agent instructions** —
none carry a `CLAUDE.md`, `CHANGELOG.md`, or any version marker. The user wants
these projects brought into the personal AI-instructions workflow, and in
particular wants **Semantic Versioning** and a **changelog** to apply to game
projects the same way they do to the .NET / Go / Flutter stacks.

`ai-instructions` already provides base + per-stack overlays, but there is no
overlay for buildless vanilla HTML/CSS/JS browser games. This design adds one.

## Goals

- A single-file stack overlay `browser-game` that binds the stack-agnostic base
  rules (SemVer, Conventional Commits, git-cliff, Keep a Changelog, GitHub Flow,
  i18n, security) to the reality of buildless browser games.
- A concrete, low-ceremony **versioning + changelog** story that works without a
  build step: git tag is authoritative, a `version.js` const mirrors it and is
  shown in-game.
- Codify the house conventions the existing games already share (canvas game
  loop, manual-WebRTC P2P, hub-card + screenshot integration).
- Prove the end-to-end story by piloting the overlay into **one** game repo.

## Non-goals

- Not a general "vanilla web" overlay — this is games-specific. A separate
  `vanilla-web` overlay can be added later if a non-game static-site need arises.
- Not introducing a bundler, framework, `package.json`, or committed
  `node_modules` to the games. They stay buildless to ship.
- Not rolling out to all 23 repos in this task — pilot one, the user rolls out
  the rest later.

## Decisions (from brainstorm)

| Question | Decision |
|---|---|
| Scope | Games-specific overlay (not general vanilla web) |
| Slug | `browser-game` → `.ai/stacks/browser-game.md`, `/sync-ai-instructions browser-game` |
| Version surface | Git tag `vX.Y.Z` = **single source of truth**; `version.js` exports a `VERSION` const that **mirrors** the tag, rendered as a small `vX.Y.Z` badge in menu/footer/about |
| Changelog / commits | Adopt base as-is: Conventional Commits + `cliff.toml` → `git-cliff` → `CHANGELOG.md` (Keep a Changelog); tag on `main` at release |
| Tooling | Zero-dep, buildless; manual in-browser playtest is the test gate; optional `npx prettier` / `npx eslint` on demand (nothing committed) |
| Rollout | Write + commit overlay, then pilot into **`game-stack-duel`** (hand-authored, has P2P) |

## Overlay structure (`.ai/stacks/browser-game.md`)

Mirrors the shape of `go.md` / `flutter.md`. Each section **binds base to the
stack** and must not repeat base content. Target size: **< 22 KB** so that
base (~14 KB) + overlay stays under the **39 KB** assembled-`CLAUDE.md` budget
(`scripts/check-claude-md-size.sh`).

1. **Header comment + intro** — `[//]: #` provenance line; what the stack is,
   which repos it applies to (`game-*`), and the "served as static GitHub Pages
   under `github.freaxnx01.ch/game-<name>/`" framing.
2. **Tech Stack** table — HTML5, modern CSS, ES-module vanilla JS, `<canvas>` +
   `requestAnimationFrame`; **no framework, no bundler required to ship**;
   Web Audio / `<audio>`; manual WebRTC for P2P; GitHub Pages hosting; git-cliff
   for changelog; `npx`-only optional lint/format.
3. **Project Structure** — document the realistic spread rather than forcing one
   layout: minimal (`index.html` only) → richer (`source/` + built `index.html`
   + `vendor/` + `README.md` + `LICENSE` + `version.js` + `CHANGELOG.md` +
   `cliff.toml`). Note that a few games are bundled (a `source/` build emits
   `index.html`) and where `version.js` lives in that case (in source, flowing
   into the bundle).
4. **JavaScript Conventions** — ES modules (`type="module"`), `const`/`let`,
   strict-ish patterns, no leaking onto `window`, small pure update functions,
   game state separated from rendering, no framework reach.
5. **Game Loop** — fixed-timestep update + rAF render, `deltaTime`, accumulator
   pattern; pause/resume on `visibilitychange`; input layer abstracted from
   simulation; deterministic simulation where P2P needs it.
6. **P2P Multiplayer (house pattern)** — manual WebRTC `RTCPeerConnection` with
   copy-paste offer/answer signaling; **no signaling server, no PeerJS, no
   Firebase**; host-authoritative or lockstep state; validate all data-channel
   input; graceful disconnect / rematch. This matches the existing P2P games.
7. **Versioning (stack binding)** — the core of the user ask:
   - Git tag `vX.Y.Z` on `main` is the **single source of truth** (satisfies
     base's "declared in exactly one place" — the const is a *display mirror*,
     not an independent source).
   - `version.js` exports `export const VERSION = "X.Y.Z";` updated at release to
     equal the tag; rendered as an unobtrusive `vX.Y.Z` badge (menu/footer/about).
   - Release flow: bump `version.js` → `chore(release): vX.Y.Z` commit → tag
     `vX.Y.Z` → `git-cliff` regenerates `CHANGELOG.md`.
8. **Changelog** — adopt base: `cliff.toml` (Conventional Commits preset),
   `CHANGELOG.md` with `[Unreleased]`; optional `git-cliff` GitHub Action for
   release notes.
9. **Tooling & Testing** — buildless; **manual in-browser playtest is the gate**
   (state what to verify: loads with no console errors, canvas renders, core
   loop + input work, P2P connects both ends). Optional `npx prettier` /
   `npx eslint` — no committed config/deps required. No TDD harness is mandated
   here (deviation from base's test-first default is called out explicitly, with
   the rationale that these are buildless, manually-verified games).
10. **Localization (i18n)** — base's de/en rule applies to games with meaningful
    UI text; give a lightweight vanilla pattern (a `strings` object keyed by
    locale + `navigator.language` detection + a switcher). Pure-arcade games with
    negligible text may defer — stated explicitly so it doesn't read as a
    loophole for text-heavy games (e.g. quizzes).
11. **Games Hub Integration** — each game gets a card in
    `freaxnx01.github.io/games/index.html`; screenshots generated by that repo's
    `scripts/capture_screenshots.py`; `NEW` tag convention. Cross-repo note:
    hub lives in the site repo, not the game repo.
12. **Security** — client JS is fully public → never embed secrets/keys; validate
    WebRTC data-channel and `postMessage` input; external resources (fonts, CDNs)
    over HTTPS only; no eval of remote content.
13. **Essential Commands** — buildless serve/preview (`python3 -m http.server`,
    open `index.html`), the release sequence (bump/commit/tag/git-cliff),
    optional `npx` lint/format, screenshot regeneration pointer.
14. **Project Scaffold Checklist (browser-game)** — `index.html`; `version.js`
    with `VERSION`; version badge wired into the UI; `CHANGELOG.md` with
    `[Unreleased]`; `cliff.toml`; `.gitignore` (incl. `.worktrees/`); `README.md`;
    `LICENSE`; hub card added in the site repo; `CLAUDE.md`/`SKILL.md`/
    `copilot-instructions.md` synced from base + this overlay.
15. **Agent Guardrails (stack-specific)** — don't add a framework/bundler/npm
    deps without asking; don't introduce a signaling server or P2P library; keep
    the game shippable as static files; keep `version.js` in sync with the tag;
    don't hand-edit a bundled `index.html` (edit `source/`).
16. **Never generate (this stack)** — framework imports (React/Vue/etc.); a
    bundler config; `package.json`/`node_modules` committed to a game; secrets in
    client JS; a second version source (a `<meta>`/JSON that competes with the
    tag+const); PeerJS/Firebase signaling; commented-out code.

## Repo wiring (in `ai-instructions`)

- Add a row to the **Supported stacks** table in `README.md` for `browser-game`.
- No `build-stacks.sh` change — this is a single-file overlay (like `flutter`/
  `go`), so the `build-stacks-drift` check stays green with no `_layers` entry.
- Confirm the assembled size check passes: base + `browser-game.md` < 39 KB.

## Pilot (in `game-stack-duel`)

After the overlay is committed:

1. From `game-stack-duel`, run `/sync-ai-instructions browser-game` (writes
   `CLAUDE.md`, `.github/copilot-instructions.md`, `SKILL.md`,
   `.ai/base-instructions.md`, `.ai/stacks/browser-game.md`).
2. Seed `CHANGELOG.md` (`[Unreleased]` + an initial released version matching the
   current state), `cliff.toml`, and `version.js` with `VERSION`.
3. Wire the `vX.Y.Z` badge into the existing UI (menu/footer/about).
4. Verify: assembled `CLAUDE.md` < 39 KB; the game still loads and plays; the
   badge shows the version; P2P still connects.
5. Commit on a branch in that repo; PR. (Full 23-repo rollout is a later,
   user-driven follow-up.)

## Acceptance criteria

- [ ] `.ai/stacks/browser-game.md` exists, follows the `go.md`/`flutter.md`
      shape, and is < 22 KB.
- [ ] Base + `browser-game.md` assembled size < 39 KB (`check-claude-md-size.sh`).
- [ ] `README.md` Supported-stacks table lists `browser-game`.
- [ ] `build-stacks-drift` / lint CI stays green (single-file overlay, no
      `_layers`).
- [ ] Overlay codifies: buildless serve model, canvas game loop, manual-WebRTC
      P2P, git-tag-authoritative versioning with a `version.js` display mirror,
      base changelog adoption, buildless test gate, hub integration.
- [ ] Pilot `game-stack-duel` ends up with synced `CLAUDE.md` + `CHANGELOG.md` +
      `cliff.toml` + `version.js` + a visible version badge, still playable.

## Open follow-ups (out of scope here)

- Roll the overlay out to the remaining 22 `game-*` repos.
- Decide whether a shared `p2p.js` helper is worth extracting across games.
- Optional: a `game-*` scaffold template repo seeded with this stack.
