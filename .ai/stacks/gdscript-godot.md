[//]: # (Stack overlay — loaded together with .ai/base-instructions.md for Godot/GDScript projects)

# Godot / GDScript Stack Overlay

Applies on top of `.ai/base-instructions.md` for **Godot Engine games** written in
GDScript. Use it for repos like `civil-war-battlefield` (Godot 4.x tactics game) —
a `project.godot` at the repo root, `.gd` scripts paired with `.tscn` scenes, and a
deliverable that's an exported game binary/web build, not a service.

This overlay is calibrated against a single repo so far — treat it as a solid
starting default, not exhaustive. Widen it (test conventions, export pipeline,
addon usage) as more Godot projects accumulate.

---

## Tech Stack

Godot Engine **4.x** (pin the exact version in `project.godot`'s
`config/features`) · GDScript (typed) · Godot's built-in scene/node system —
no external ECS or ORM · export via Godot's built-in export presets
(`export_presets.cfg`) · `GUT` (Godot Unit Test) for scripted tests, when tests
exist · GitHub Actions with a Godot headless export step for CI builds.

---

## Project Structure

```text
project.godot           ← engine config, autoloads, input map
scenes/                 ← one subfolder per feature/screen, .tscn + paired .gd
  <feature>/
    <feature>.tscn
    <feature>.gd
scripts/                ← non-scene singletons/managers (autoloads point here)
units/ · entities/       ← game-object scenes, one .tscn + .gd pair each
addons/                 ← third-party plugins (vendored, not hand-edited)
assets/                 ← sprites, audio, fonts
export_presets.cfg      ← export targets (committed, no secrets)
```

- **Every scene (`.tscn`) that has behaviour gets a paired script (`.gd`) of the
  same base name**, attached at the scene root — don't scatter logic across
  unrelated scripts.
- Prefer **composition via scenes** (instance a `Unit.tscn` inside `Battlefield.tscn`)
  over deep inheritance chains of scripts.
- Autoloads (singletons registered in Project Settings → Autoload) are for
  genuinely global state (game manager, event bus) — don't autoload something
  that only one scene needs.

---

## GDScript Conventions

- **Static typing everywhere it's expressible**: `var health: int = 100`,
  `func take_damage(amount: int) -> void:`. Untyped `var`/`func` is a gap to
  close, not the default.
- `class_name` on any script meant to be referenced by type elsewhere
  (`class_name Unit extends CharacterBody2D`); scripts used only as a single
  scene's root script don't need one.
- Signals over polling: a node that needs to react to another node's state
  change connects to a `signal`, it doesn't `_process()`-poll a property.
- `@onready var` for node references resolved at `_ready()`; never assume a
  child node exists before `_ready()` has run.
- Constants (`const`) for magic numbers/strings that recur (`const MAX_UNITS = 20`),
  not inline literals scattered across scripts.
- Group related exported tunables under `@export_group` so the Inspector stays
  navigable as a script grows.

---

## Input & Game Loop

- Input actions are defined in the Input Map (`project.godot`), never
  hardcoded key checks (`Input.is_action_pressed("move_up")`, not
  `Input.is_key_pressed(KEY_W)`) — this is what makes remapping and
  controller support possible later without touching gameplay code.
- Physics-affecting logic goes in `_physics_process(delta)`; visual-only /
  input-polling logic goes in `_process(delta)`. Don't move a
  `CharacterBody2D`/`RigidBody2D` from `_process`.
- AI/controller scripts (see `ai_controller.gd`-style patterns) drive the same
  input/action surface a player would — don't give AI a separate privileged
  code path into unit state.

---

## Testing

Base TDD rules (tests first, never modify a test to make it green, full suite
after implementation) apply where testable logic exists. In practice:

- **Pure logic** (damage calculation, pathing cost, turn resolution) that
  doesn't need the scene tree is the highest-value thing to unit test — extract
  it into a plain `RefCounted`/static-method class so it's testable without
  instancing a scene.
- Use **GUT** (`gut/`) for scripted tests when a project has enough pure logic
  to justify it; don't add it speculatively to a project that's still mostly
  scene wiring.
- Manual playtest is the primary gate for scene/input/game-feel behaviour that
  doesn't reduce to a pure function — this is a deliberate deviation from
  base's TDD-first mandate, same rationale as the `browser-game` stack.

Manual verification checklist before every push/release:

- [ ] Project opens in the Godot editor with no script errors in the Output panel
- [ ] The game runs (F5) and the core loop responds to input
- [ ] No warnings about missing node references / unconnected signals for
      code paths touched by the change
- [ ] Exported build (if the change touches export config) launches standalone

---

## Versioning (stack binding)

Base SemVer/Conventional-Commits/`git-cliff` rules apply. The git tag `vX.Y.Z`
on `main` is the single source of truth. If the project displays a version
in-game (menu/HUD), mirror it the same way `browser-game`'s `version.js` does —
a hand-bumped display constant that must equal the latest tag, never a second
independent version source.

---

## Build & Export

- Export presets (`export_presets.cfg`) are committed — they define target
  platforms (Windows/Linux/macOS/Web/etc.) and are not secret.
- CI export runs Godot **headless**: `godot --headless --export-release
  "<preset>" <output-path>` (or `--export-debug` for dev builds), using the
  matching Godot version pinned for the project.
- Don't commit exported binaries/build artifacts — `.gitignore` covers
  `.godot/` (editor cache/import data), export output directories, and
  platform-specific build junk.

---

## Agent Guardrails (this stack)

In addition to the base guardrails:

- Do not upgrade the Godot engine version (`config/features` in
  `project.godot`) without asking — it can silently change scene/script
  compatibility.
- Do not add a third-party addon under `addons/` without asking; treat vendored
  addon code as read-only (fix forks upstream, don't hand-patch in-tree).
- Do not switch a scene's root node type without confirming — it can break
  every script that assumes the old base class's API.
- Do not hardcode input handling (`Input.is_key_pressed`) — go through the
  Input Map action system.
- Keep AI/controller code going through the same action surface as player
  input; don't give it a shortcut into internal state.

### Never generate (this stack)

- Untyped `var`/`func` declarations where a type is knowable
- Direct key/button checks bypassing the Input Map action system
- Physics-body movement from `_process()` instead of `_physics_process()`
- A scene (`.tscn`) with real behaviour and no paired script, or vice versa
- A second, hand-rolled version display disconnected from the git tag
- Exported build artifacts or `.godot/` cache committed to git
