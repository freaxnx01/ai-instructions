# Windows PowerShell 5.1 compatibility

Customer machines run the **in-box Windows PowerShell 5.1**. `pwsh` (PowerShell 7+) is
not installed there. Every script we ship — `build.ps1`, install / deploy / migration
scripts, anything inside a release artifact — must run on 5.1.

**Dev-loop tooling is exempt.** `justfile` recipes and local helper scripts run only on
developer machines and may require `pwsh`. See
[`justfile-recipes.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/justfile-recipes.md).

A project may raise its floor to PS 7 — but it must say so in its README, and it must
then also ship `pwsh` to the customer or document it as a prerequisite.

---

## Script header

Every customer-delivered script starts with:

```powershell
#requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'   # 5.1 defaults differ per cmdlet
```

`#requires -Version 5.1` is a floor assertion, not a ceiling — the script still runs on
PS 7. It documents intent and fails fast on PowerShell 2/3/4 hosts.

`$PSDefaultParameterValues['*:Encoding'] = 'utf8'` is the single most valuable line in
the header; see [Encoding](#encoding-the-worst-trap) below.

---

## Syntax that does not parse on 5.1

These are **parse** errors, not runtime errors — the script dies before executing its
first statement, so no amount of testing the happy path on a dev box catches them.

| PS 7 | 5.1-compatible |
|---|---|
| `$x = $a ?? $b` | `$x = if ($null -eq $a) { $b } else { $a }` |
| `$a ??= $b` | `if ($null -eq $a) { $a = $b }` |
| `$x = $c ? $a : $b` | `$x = if ($c) { $a } else { $b }` |
| `cmd1 && cmd2` | `cmd1; if ($LASTEXITCODE -ne 0) { throw }; cmd2` |
| `cmd1 \|\| cmd2` | `cmd1; if ($LASTEXITCODE -ne 0) { cmd2 }` |
| `$obj?.Prop` | `if ($null -ne $obj) { $obj.Prop }` |
| `$obj?.Method()` | `if ($null -ne $obj) { $obj.Method() }` |

`&&` / `||` deserve care: the PS 7 operators chain on **success**, and `$LASTEXITCODE`
only reflects native executables. For a chain of cmdlets, `$ErrorActionPreference =
'Stop'` plus plain sequencing is the better translation.

---

## Cmdlets and parameters absent from 5.1

| PS 7 | 5.1 approach |
|---|---|
| `ForEach-Object -Parallel` | Sequential `ForEach-Object`, or `Start-Job` / runspaces if throughput genuinely matters |
| `Sort-Object -Stable` | No equivalent — add an explicit tie-breaker key to make the order deterministic |
| `Invoke-WebRequest -SslProtocol Tls12` | `[Net.ServicePointManager]::SecurityProtocol` (see [TLS](#tls-do-not-cargo-cult-the-tls12-line)) |
| `Get-Error` | `$Error[0] \| Format-List -Force` |
| `Test-Json` | `try { ConvertFrom-Json … } catch { }` |
| `Join-String` | `-join` operator |
| `ConvertFrom-Json -AsHashtable` | Walk the `PSCustomObject`, or use `[Web.Script.Serialization.JavaScriptSerializer]` |

---

## Traps that fail silently

These produce **no error at all** on 5.1 — the script completes and the result is wrong.
They are the reason a syntax linter alone is not sufficient.

### `$IsWindows` and friends are undefined

`$IsWindows`, `$IsLinux`, `$IsMacOS`, and `$IsCoreCLR` were introduced in PowerShell
Core. On 5.1 they are simply **undefined**, which means `$null`, which is falsy:

```powershell
if ($IsWindows) { Install-WindowsThing }    # never runs on 5.1. No error.
```

Under `Set-StrictMode -Version 2.0` this at least throws on the undefined variable —
another reason the header matters. Portable test:

```powershell
$onWindows = $env:OS -eq 'Windows_NT'
```

### Encoding (the worst trap)

Windows PowerShell's default encoding is **not consistent across cmdlets**. In a single
script, without a single warning:

| Cmdlet | 5.1 default | PS 7 default |
|---|---|---|
| `Out-File`, `>`, `>>` | UTF-16LE **with BOM** | `utf8NoBOM` |
| `Set-Content` / `Add-Content` | ANSI (system code page) | `utf8NoBOM` |
| `Export-Csv` | ASCII | `utf8NoBOM` |
| `Get-Content` (BOM-less input) | ANSI | UTF-8 |

Symptoms: a generated `.json` or `.yml` that no other tool can read, mangled non-ASCII
characters, a config file that grows a BOM and breaks a parser. Fix it once in the
header with `$PSDefaultParameterValues['*:Encoding'] = 'utf8'`, or pass `-Encoding`
explicitly on every write.

Note that in 5.1 `utf8` means **UTF-8 with BOM**. Where a BOM-less file is required,
use `[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))`.

### `ConvertTo-Json` truncates at depth 2

`-Depth` defaults to **2** in both editions, but PS 7.1+ emits a warning when the input
is deeper. **5.1 truncates silently** — nested objects become
`System.Collections.Hashtable` strings in the output. Always pass `-Depth` explicitly:

```powershell
$obj | ConvertTo-Json -Depth 10
```

### `-UseBasicParsing` is mandatory, not stylistic

Historically `-UseBasicParsing` was only needed where Internet Explorer was absent
(Server Core). A security update for **CVE-2025-54100**, released **2025-12-09**, changed
that: `Invoke-WebRequest` on a patched 5.1 host now raises an interactive *"Security
Warning: Script Execution Risk"* confirmation, and per Microsoft there is no way to
suppress it other than `-UseBasicParsing`.

An unattended script that omits it **hangs**. The parameter is a deprecated no-op on
PS 7, so it is always safe to include:

```powershell
Invoke-RestMethod -Uri $url -UseBasicParsing
```

### TLS (do not cargo-cult the `Tls12` line)

The widespread claim that "5.1 defaults to TLS 1.0" is not accurate as stated: .NET
Framework delegates to Schannel, so the effective default depends on the targeted
framework version plus the `SchUseStrongCrypto` and `SystemDefaultTlsVersions` registry
values, which do not exist by default.

What *is* true: **5.1 has no in-cmdlet protocol control**, which is why 5.1-era scripts
carry a line like:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

Two rules:

- Add it only when you have actually observed a handshake failure, and scope it to the
  script. It is process-global state.
- **Never copy it into a PS 7 script.** PS 7 allows every protocol the OS supports;
  pinning `Tls12` there actively *prevents* TLS 1.3.

---

## Verifying with PSScriptAnalyzer

Drop this in as `PSScriptAnalyzerSettings.psd1` — it ships ready-made at
[`templates/pre-commit/PSScriptAnalyzerSettings.psd1`](https://github.com/freaxnx01/ai-instructions/blob/main/templates/pre-commit/PSScriptAnalyzerSettings.psd1):

```powershell
@{
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1')
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @('win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework')
        }
        PSUseCompatibleTypes = @{
            Enable         = $true
            TargetProfiles = @('win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework')
        }
    }
}
```

Run it:

```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

Invoke-ScriptAnalyzer -Path . -Recurse `
    -Settings ./PSScriptAnalyzerSettings.psd1 `
    -Severity Error,Warning `
    -ReportSummary -EnableExit
```

### Four things that will bite you

- **Run the analyzer under PowerShell 7.** Under 5.1 the parser cannot represent PS 7
  syntax, so it cannot report it — the rule silently finds nothing. This is the one case
  where `pwsh` is required to check 5.1 compatibility.

- **`-EnableExit` returns a count of error records**, not `0`/`1`. Use it for
  pass/fail (`if` semantics are fine); never compare the exit code against `1`.

- **`-Severity Error,Warning` is required.** Only `PSUseCompatibleSyntax` is
  Error-severity; the profile-based rules emit Warnings and would not fail the build on
  their own.

- **The three rules above are opt-in** (disabled unless enabled in settings), but
  `PSUseCompatibleCmdlets` — a different, older, name-only rule — is **always enabled**
  and will run whether you configure it or not. Add it to `ExcludeRules` if its output is
  noise.

`TargetVersions` matches on **major version only**, so `'5.1'` and `'5.1.14393.206'` are
equivalent and the rule cannot distinguish 5.0 from 5.1. Use `'5.1'`.

For pre-commit integration, see
[`polyglot-lint.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/polyglot-lint.md).
