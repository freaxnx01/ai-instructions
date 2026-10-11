# Browser-game changelog — full rules

Elaboration for the `Changelog` section of `.ai/stacks/browser-game.md`. The
overlay carries the operative rules; this file carries the reasons and the
detail.

## Who reads it

A game's `CHANGELOG.md` is read by the person playing it — the version badge in
the game links straight to it. So the entries are written by hand, and they are
the deliverable: an entry says what changed *in the game* („Die Turmhöhe ist
jetzt wählbar…"), not what changed in the repo. Each PR appends its entry under
`[Unreleased]` in that voice.

## Entry format

```markdown
- `2026-10-10 22:32` Press <kbd>U</kbd> and the pontoniers lay a **floating bridge** across the Rhine, bay by bay.
- `2026-10-09 19:20` Press <kbd>X</kbd> to take a **photo**: the current view is saved as a PNG.
```

### Timestamp

Every entry leads with the date and time the change was made, as a code span:
`YYYY-MM-DD HH:MM`. A player coming back after two days can then see what is new
since their last visit without reading every line — a release date alone cannot
do that while weeks of changes pile up under `[Unreleased]`.

- **Local time, not UTC.** The reader is a player in Switzerland, not a server.
  Take it from `TZ=Europe/Zurich date '+%F %H:%M'` — never from a bare `date`:
  a CI runner's clock is UTC and would stamp every entry one or two hours early.
- **No second UTC time and no offset.** It doubles the noise on every line for a
  reader who does not need it. The file states the zone once, in its intro:
  *"Every entry carries the date and time it went live, in Swiss local time
  (Europe/Zurich)."*
- **Rewording an entry keeps its timestamp.** The time says when the change
  arrived, not when the sentence was last polished.
- **Cutting a release keeps the timestamps.** They stay on the entries under the
  new `## [X.Y.Z] - YYYY-MM-DD` heading.
- **Backfilling a changelog that has none:** take each entry's time from the
  commit that first introduced the line (`git log --reverse --format=%cI -S'<a
  distinctive phrase>' -- CHANGELOG.md | head -1`), converted to local time.

### Order

Newest first within each section (`Added`, `Changed`, `Fixed`, …), so a new
entry goes at the top of its section.

### Bold keywords

Bold **one to three keywords** per entry — the thing the entry is about, so the
changelog can be skimmed by its bold words alone: **pontoon bridge**,
**rear-view mirror**, **Bahnhof Sisseln**. A keyword is a noun phrase of a few
words, never a whole sentence, and never more than three per entry — bolding
everything bolds nothing.

### Keys and buttons

Keys the player presses go in `<kbd>` — `<kbd>J</kbd>`, `<kbd>F3</kbd>`,
`<kbd>Tab</kbd>` — which GitHub renders as key caps. Do **not** bold them:
a controls-heavy entry easily names five keys, and five bold keys drown the
keywords. On-screen labels that are not the subject of the entry go in plain
quotes.

## Never regenerate the file

**Never run `git cliff -o CHANGELOG.md`.** It rewrites the whole file from
commit subjects and deletes the player-facing prose of every earlier release —
confirmed the hard way while cutting `game-wipfelkratzer` v0.6.0 (2026-09-17).
Cutting a release is therefore an edit, not a command: rename `## [Unreleased]`
to `## [X.Y.Z] - YYYY-MM-DD` and open a fresh empty `[Unreleased]` above it.

`cliff.toml` stays in the repo and `git-cliff` stays useful for *reading* the
Conventional Commits since the last tag (`git cliff --unreleased` to stdout) —
as a source to write from, never as a generator that overwrites the file.
`orhun/git-cliff-action` in CI is likewise fine for GitHub **Release notes**,
which are separate from `CHANGELOG.md`; the release body can also just be the
hand-written section for that version.
