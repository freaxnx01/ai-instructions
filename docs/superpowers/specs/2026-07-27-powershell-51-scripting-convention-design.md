# Design — Scripting convention: Windows PowerShell 5.1 floor

**Date:** 2026-07-27
**Status:** Approved (design), pending implementation
**Repo:** `ai-instructions`

---

## Problem

Customers run scripts on **Windows PowerShell 5.1** (the in-box shell). PowerShell 7
(`pwsh`) is not installed on their machines. Agents writing PowerShell for these
projects reach for PS 7 syntax by default — `??`, ternary, `&&` — producing scripts
that fail at parse time on the customer's box.

There is currently **no scripting convention at all** in `base-instructions.md`, and
the repo contradicts itself on the PowerShell edition:

| Location | Says |
|---|---|
| `.ai/references/dotnet-fx48-legacy/gitlab-ci.md:19` | `powershell -ExecutionPolicy Bypass -File ./build.ps1` — PS 5.1 |
| `.ai/examples/dotnet/justfile:12` | `set windows-shell := ["pwsh", …]` — PS 7 |
| `.ai/references/dotnet/justfile-recipes.md:35` | documents `#!/usr/bin/env pwsh` as a **rule** |

Ten justfile recipes carry a `pwsh` shebang. `pwsh` does not exist on a 5.1-only host.

---

## Decisions

### 1. Scope — customer-delivered scripts only

The 5.1 floor binds any PowerShell that **runs on a customer machine**: `build.ps1`,
install / deploy / migration scripts, anything shipped in a release artifact.

**Dev-loop tooling is exempt.** `justfile` recipes and local helper scripts run only on
developer machines, which are ours, and may require `pwsh`. The justfile's
`set windows-shell := ["pwsh", …]` and its ten `pwsh` shebangs **stay as they are**.

This makes the split deliberate rather than accidental. `justfile-recipes.md` gains an
explicit sentence naming recipes as dev-loop tooling, so line 35 no longer reads as a
contradiction of the base rule.

The base rule is written with an escape hatch — *"target Windows PowerShell 5.1 unless
the project documents a PS 7+ floor"* — so the exemption is a stated property of the
rule, not a violation of it.

### 2. Placement — base, not an overlay

`base-instructions.md`, per the repo's own disjointness rule. PowerShell is not
.NET-specific: `go.md:131` already emits PowerShell shell completions, and any stack can
ship a Windows installer script.

### 3. Enforcement — prose plus a drop-in settings file, no gate

Ship the rule, the reference, and a ready-to-use `PSScriptAnalyzerSettings.psd1`. Wire
**no** pre-commit hook and **no** CI job in this repo.

Rationale: most projects consuming these overlays ship zero PowerShell. A hook that
installs a PowerShell module on every commit is pure cost for them. Projects that do
ship `.ps1` opt in by copying the settings file and the documented CI snippet.

Secondary rationale: there is **no maintained upstream pre-commit hook** for
PSScriptAnalyzer (PSScriptAnalyzer issue #1969, open since 2024-02-22; the only
candidate is a 0-star personal fork with no `.pre-commit-hooks.yaml`), and Microsoft's
PowerShell Docker images are deprecated in MCR. The only clean route would be a
`repo: local` hook shelling to `pwsh` — deferred, not adopted.

---

## Verified technical basis

All claims below were verified against the PSScriptAnalyzer rule source and Microsoft
Learn, not recalled.

### PSScriptAnalyzer catches the syntax breaks

`PSUseCompatibleSyntax` with `TargetVersions = @('5.1')` flags all PS 7-only operators.
Confirmed in `Rules/CompatibilityRules/UseCompatibleSyntax.cs`:

| Operator | Detection |
|---|---|
| `??` | `TokenKind.QuestionQuestion` → "null-coalescing operator" |
| `??=` | `TokenKind.QuestionQuestionEquals` |
| `? :` | `VisitTernaryExpression` |
| `&&` / `\|\|` | `VisitPipelineChain` → "pipeline chain" |
| `?.` / `?.()` | null-conditional access |

Two mechanics that matter for the reference doc:

- `TargetVersions` matches on **major version only** — `'5.1'` and `'5.1.14393.206'` land
  in the same bucket, and the rule cannot distinguish 5.0 from 5.1. Use `'5.1'`.
- The analyzer must **run under PS 7**. Under 5.1 it cannot parse newer syntax, so it
  cannot flag it.

### But syntax rules are not sufficient

The rules that actually bite fail **silently** — no parse error, wrong behavior:

| Trap | 5.1 | 7 |
|---|---|---|
| `$IsWindows` / `$IsLinux` / `$IsMacOS` | **undefined** → `$null` → falsy | defined |
| `Out-File`, `>`, `>>` | UTF-16LE + BOM | `utf8NoBOM` |
| `Set-Content` / `Add-Content` | ANSI code page | `utf8NoBOM` |
| `Export-Csv` | `Ascii` | `utf8NoBOM` |
| `ConvertTo-Json` default `-Depth` | 2, **silent** truncation | 2, warns since 7.1 |
| `ForEach-Object -Parallel` | does not exist | 7.0+ |
| `Sort-Object -Stable` | does not exist | 6.2+ |
| `-SslProtocol` on web cmdlets | does not exist | 6.0+ |

`$IsWindows` is the canonical example: `if ($IsWindows) { … }` takes the wrong branch on
5.1 with no error at all.

Encoding is the worst of these because 5.1's defaults are **not consistent across
cmdlets** — `Out-File` writes UTF-16LE while `Set-Content` writes ANSI in the same
script. Mitigation is a script-level pin:
`$PSDefaultParameterValues['*:Encoding'] = 'utf8'`.

### `-UseBasicParsing` is now mandatory

A security update for **CVE-2025-54100** (released 2025-12-09) changed Windows
PowerShell 5.1: `Invoke-WebRequest` now raises an interactive *"Security Warning: Script
Execution Risk"* prompt, and per Microsoft's own docs there is no way to bypass it
without `-UseBasicParsing`. On a patched 5.1 host, omitting it **hangs an unattended
script**. The parameter is a deprecated no-op in PS 7, so including it is safe in
cross-version scripts.

### TLS — deliberately not stated as a rule

The folk claim "5.1 defaults to TLS 1.0" is not accurate as written; .NET Framework
delegates to Schannel and the effective default depends on target framework version plus
registry values. The accurate cross-version statement is that **5.1 has no in-cmdlet
protocol control**, which is why 5.1-era scripts carry
`[Net.ServicePointManager]::SecurityProtocol = …::Tls12`. The reference will note that a
hardcoded `Tls12` line copied into a PS 7 script actively prevents TLS 1.3.

---

## Changes

| # | File | Change |
|---|---|---|
| 1 | `.ai/base-instructions.md` | **New** `## Scripting` section after `## CI/CD (generic outline)`. The rule, the escape hatch, the banned-construct list, the mandatory script header, link to the reference. Keep it short — detail lives in the reference. |
| 2 | `.ai/references/base/powershell-5.1.md` | **New.** PS 7-only syntax → 5.1 replacement table; the silent-trap table above; the script header idiom; the full `PSScriptAnalyzerSettings.psd1`; CI invocation. |
| 3 | `.ai/references/base/polyglot-lint.md` | Add a PSScriptAnalyzer entry, marked opt-in, with the "no upstream hook / analyzer must run under PS 7" caveats and a pointer to #2. |
| 4 | `templates/pre-commit/PSScriptAnalyzerSettings.psd1` | **New**, drop-in, unwired. `.pre-commit-config.yaml` is **not** modified. |
| 5 | `.ai/references/dotnet/justfile-recipes.md` | One sentence under *Cross-OS authoring rules*: recipes are dev-loop tooling and may assume `pwsh`; customer-delivered `.ps1` follows the base 5.1 floor. Resolves the line-35 contradiction. |
| 6 | `.ai/stacks/dotnet-fx48-legacy.md` | Pointer line near the Cake/`build.ps1` content — `build.ps1` is customer-facing, so the floor applies. |
| 7 | `.ai/examples/dotnet-blazor/{CLAUDE,copilot-instructions,SKILL}.md` | Re-inline the new base section into all three (they inline `base-instructions.md` verbatim; all three are 709 lines and identical in the base region). |

### Not changed

- `.ai/examples/dotnet/justfile` — `set windows-shell` and all ten `pwsh` shebangs stay.
- `templates/pre-commit/.pre-commit-config.yaml` — no hook added.
- `.ai/stacks/_partials/` and `_layers/` — untouched, so `build-stacks.sh` needs no
  regeneration. The drift check is still run to confirm.

---

## Verification

1. `./scripts/build-stacks.sh && git diff --exit-code .ai/stacks/dotnet-*.md` — clean.
2. `pre-commit run --all-files` — markdownlint and `typos` pass on the new Markdown.
3. Write a throwaway `.ps1` using `??` and a ternary; run
   `pwsh -c "Invoke-ScriptAnalyzer -Path <file> -Settings templates/pre-commit/PSScriptAnalyzerSettings.psd1"`
   and confirm it flags both. `pwsh` is available at `~/.dotnet/tools/pwsh`. This proves
   the shipped settings file works rather than assuming it.
4. Confirm the base section appears verbatim in all three
   `.ai/examples/dotnet-blazor/` files.

---

## Out of scope

Captured, not acted on:

- A `repo: local` PSScriptAnalyzer pre-commit hook, and a reusable CI workflow template.
  Revisit if a consuming project starts shipping PowerShell in volume.
- A general `## Scripting` policy for `bash`/`sh` beyond the existing `shellcheck` entry
  in the polyglot lint gate.
