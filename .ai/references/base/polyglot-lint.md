# Polyglot Lint Standard (pre-commit)

Most repos are mostly **not** C# — they are GitHub Actions YAML, shell, Markdown,
JSON, Dockerfiles, and Python. The .NET quality gates only cover C#; this
standard lints everything else. A single [`pre-commit`](https://pre-commit.com)
configuration runs the hooks as a local git hook **and** in CI, so problems are
caught before a PR opens.

The canonical config lives in [`templates/pre-commit/`](https://github.com/freaxnx01/ai-instructions/tree/main/templates/pre-commit)
in the `ai-instructions` repo and is seeded into a project root by
`/sync-ai-instructions`. Pin every hook `rev` with `pre-commit autoupdate` —
never leave a floating ref.

## What each hook catches

| Hook | Catches |
|---|---|
| `actionlint` | Broken workflow YAML — `${{ }}` typos, bad `uses:` refs, undefined `needs:` |
| `yamllint` | YAML style/structure (tuned via `.yamllint` so it does not fight Actions `on:` keys) |
| `shellcheck` | Shell bugs in scripts and `run:` blocks |
| `ruff` (+ `ruff-format`) | Python lint and formatting |
| `markdownlint-cli2` | Markdown structure (tuned via `.markdownlint-cli2.yaml`; generated files excluded) |
| `hadolint` | Dockerfile issues |
| `typos` | Misspellings in code and docs |
| `gitleaks` | Secrets about to be committed |
| `pre-commit-hooks` | Whitespace, end-of-file, merge-conflict markers, oversized files, mixed line endings |

## PowerShell (opt-in, not wired by default)

The template config does **not** include a PowerShell hook — most repos ship zero `.ps1`,
and the hook would cost a module install on every commit for nothing. Repos that do ship
PowerShell add it themselves.

There is no maintained upstream pre-commit hook for PSScriptAnalyzer (the request is
still open as PSScriptAnalyzer issue #1969), so use a `repo: local` hook:

```yaml
  - repo: local
    hooks:
      - id: psscriptanalyzer
        name: PSScriptAnalyzer (Windows PowerShell 5.1 compat)
        entry: pwsh -NoProfile -Command Invoke-ScriptAnalyzer -EnableExit -Severity Error,Warning -Settings ./PSScriptAnalyzerSettings.psd1 -Path
        language: system
        files: \.ps1$
        require_serial: true
```

Copy [`templates/pre-commit/PSScriptAnalyzerSettings.psd1`](https://github.com/freaxnx01/ai-instructions/blob/main/templates/pre-commit/PSScriptAnalyzerSettings.psd1)
to the repo root alongside it. Two caveats: the hook needs `pwsh` on `PATH` (PowerShell 7
— the analyzer cannot detect PS 7 syntax when run *under* 5.1), and PSScriptAnalyzer must
be installed (`Install-Module PSScriptAnalyzer`), which pre-commit will not do for you.
CI-only enforcement is the lower-friction alternative.

Rules, settings, and the compatibility gotchas: [`powershell-5.1.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/powershell-5.1.md).

## Docker caveat

`actionlint-docker` and `hadolint-docker` run their linters via Docker, so a
Docker daemon must be available. On hosts without Docker, swap them for the
self-contained hook variants (`actionlint`, `hadolint`), which use a downloaded
binary instead.

## Config companions

- `.yamllint` — relaxes the rules that fight GitHub Actions YAML (`truthy` on
  `on:`, long lines, document-start).
- `.markdownlint-cli2.yaml` — disables purely stylistic rules (line length,
  inline HTML, table-pipe padding) and ignores generated files (`CLAUDE.md`,
  `SKILL.md`, `.github/copilot-instructions.md`, and any generated stack files).

## CI invocation

Run the whole gate with:

```bash
pre-commit run --all-files
```

or use the [`pre-commit/action`](https://github.com/pre-commit/action) GitHub
Action. Adopting the standard on an existing repo will surface pre-existing
findings; fix them, or scope-suppress with a noted follow-up.
