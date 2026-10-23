---
name: powershell-5.1
globs: ["**/*.ps1", "**/*.psm1"]
---

## Scripting

**PowerShell — customer-delivered scripts target Windows PowerShell 5.1.** Anything a customer runs (`build.ps1`, install/deploy scripts, release artifacts) must run on 5.1 unless the project documents a PS 7+ floor; `pwsh` is not installed there.

- **Never** use `??`, `??=`, ternary `? :`, `?.`, `&&` / `||` chains — *parse* errors on 5.1, so the script dies before its first line — nor `ForEach-Object -Parallel`, `Sort-Object -Stable`, `-SslProtocol`
- `$IsWindows` / `$IsLinux` / `$IsMacOS` **do not exist** on 5.1 — they are `$null`, so the branch is silently skipped. Use `$env:OS -eq 'Windows_NT'`
- Pass `-Depth` to `ConvertTo-Json` (defaults to 2, truncates silently) and `-UseBasicParsing` to the web cmdlets (a patched host prompts and hangs)
- Start with `#requires -Version 5.1`, pin encoding, verify with PSScriptAnalyzer
- **Exempt:** dev-loop tooling (`justfile` recipes) may require `pwsh`

Full rules: [`powershell-5.1.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/powershell-5.1.md)
