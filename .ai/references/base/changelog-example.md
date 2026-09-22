# CHANGELOG.md — Keep a Changelog example

Reference shape for `CHANGELOG.md` at the repo root.

```markdown
# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-06-01
### Added
- Order cancellation endpoint

### Fixed
- Token refresh edge case on expiry boundary

### Issues
- #42 — feat(orders): allow cancelling a pending order
- #57 — fix(auth): token refresh fails on the expiry boundary

## [1.0.0] - 2025-04-15
### Added
- Initial release
```

**Sections per release:** `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

---

## The `### Issues` list

Every released version ends with an `### Issues` section listing the issues that
release closed, one per line as `#<n> — <title>`. It is the index a reader scans to
answer "is my ticket in this version" without reading the prose.

**Derive it from the tracker's API, not from the commit text.** Two traps:

- A squash-merged subject carries the **pull request** number, not the issue:
  `fix(x): ... (#544)` is PR 544 closing issue 542. Listing `#544` points at the wrong
  thing. Resolve each referenced number through the API (GitHub GraphQL:
  `issueOrPullRequest`, then a PR's `closingIssuesReferences`) and keep only what is
  genuinely an issue.
- A `Closes #<n>` footer survives inconsistently through squash merges, so it cannot be
  the only source. Collect candidates from **both** subjects and bodies, then classify.

Filter to issues that are actually **closed** — a referenced-but-open issue was
discussed, not delivered.

**git-cliff cannot generate this.** It reads commits and never calls the tracker API, so
it has no titles. The block is therefore a **post-generation step**, and because
`git-cliff --output CHANGELOG.md` rebuilds the whole file, a hand-written block is
deleted by the next release. Regenerate it from the API as part of the release recipe,
after git-cliff runs — do not hand-write it and hope.

---

## `RELEASENOTES.md` — the user-facing companion

`CHANGELOG.md` is developer-facing and auto-generated. `RELEASENOTES.md` is the
plain-language companion for the people who install the release, grouped as
*New Features* / *Improvements* / *Bug Fixes*.

**Open every version with a `**TL;DR:**` paragraph** stating the outcomes a reader needs
if they read nothing else — the headline capabilities, any security gap closed, and any
defect that silently lost or corrupted data. Not a topic sentence; the conclusion.

Keep customer and tenant names out of it — those belong in `CHANGELOG.md`.
