# Browser-game on/off toggles — sliding switch

Elaboration for the `UI Controls` section of `.ai/stacks/browser-game.md`.

## Why

A button whose text is the state ("Music: on") is ambiguous: the player cannot
tell whether the text is the current state or what a click will do. A sliding
switch answers both at once — the knob position and colour are the state, the
label names the setting and never changes.

## Markup

```html
<label class="switch">
  <span class="switch-label" data-i18n="setMusic">Music</span>
  <button id="setmusic" class="switch-track" type="button" role="switch" aria-checked="true">
    <span class="switch-knob" aria-hidden="true"></span>
  </button>
  <span class="switch-state" aria-hidden="true" data-i18n="setOn">on</span>
</label>
```

- `role="switch"` + `aria-checked` carry the state for screen readers; the
  button has **no state text inside it**.
- The optional `.switch-state` text next to the track reinforces the knob for
  colour-blind players. It is outside the button, so it reads as a status,
  never as an action.

## CSS

```css
.switch { display: flex; align-items: center; gap: .75rem; cursor: pointer; }
.switch-label { flex: 1; }
.switch-track {
  position: relative; width: 3.2em; height: 1.7em; padding: 0;
  border: 2px solid var(--ink, #222); border-radius: 999px;
  background: #5a6072; cursor: pointer; transition: background .15s;
}
.switch-knob {
  position: absolute; top: 50%; left: .15em; width: 1.3em; height: 1.3em;
  border-radius: 50%; background: #fff; transform: translateY(-50%);
  transition: left .15s;
}
.switch-track[aria-checked="true"] { background: #2e9e4f; }
.switch-track[aria-checked="true"] .switch-knob { left: calc(100% - 1.45em); }
.switch-track:focus-visible { outline: 3px solid var(--accent, #ffd400); outline-offset: 2px; }
@media (prefers-reduced-motion: reduce) { .switch-track, .switch-knob { transition: none; } }
```

## JS

```js
function renderSwitch(id, on) {
  const track = document.getElementById(id);
  track.setAttribute("aria-checked", String(on));
  track.parentElement.querySelector(".switch-state").textContent = t(on ? "setOn" : "setOff");
}

document.getElementById("setmusic").addEventListener("click", () => {
  settings.music = !settings.music;   // input writes state…
  renderSwitch("setmusic", settings.music);  // …render reads it
});
```

Keyboard: a `<button>` already toggles on <kbd>Space</kbd>/<kbd>Enter</kbd>;
for gamepad menus, A toggles the focused switch, left/right may set off/on.

## Compact bars (menu, HUD)

Where a full switch does not fit, use an icon button whose **symbol** shows the
state (♪ vs. struck-through ♪, dimmed), with `aria-pressed` and a fixed
`title`/`aria-label` naming the setting ("Music") — never "Music: on".

## Not covered

Multi-value settings (graphics style, difficulty) are not on/off: use a
segmented control (all options visible, active one filled) or a `<select>`,
not a button that cycles through values with its current value as text.
