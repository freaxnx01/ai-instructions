# PSScriptAnalyzer settings — Windows PowerShell 5.1 compatibility gate.
#
# Copy to the repo root next to .pre-commit-config.yaml. Not wired into the
# template pre-commit config: most repos ship no PowerShell, so the hook is
# opt-in. See .ai/references/base/polyglot-lint.md for the repo:local hook and
# .ai/references/base/powershell-5.1.md for the rules this enforces.
#
# Run the analyzer under PowerShell 7 (pwsh). Under 5.1 the parser cannot
# represent PS 7 syntax, so PSUseCompatibleSyntax silently reports nothing.
#
#   Invoke-ScriptAnalyzer -Path . -Recurse `
#       -Settings ./PSScriptAnalyzerSettings.psd1 `
#       -Severity Error,Warning -ReportSummary -EnableExit
#
# -Severity Error,Warning is required: only PSUseCompatibleSyntax is Error
# severity, so the profile-based rules would not fail the build on their own.
# -EnableExit returns a *count* of error records — never compare it against 1.

@{
    Rules = @{

        # Parse-level PS 7-only syntax: ?? ??= ternary ?. and && / || chains.
        # TargetVersions matches on MAJOR version only, so '5.1' and
        # '5.1.14393.206' are equivalent; the rule cannot distinguish 5.0 from 5.1.
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1')
        }

        # Commands and their parameters absent from Windows PowerShell 5.1
        # (ForEach-Object -Parallel, Sort-Object -Stable, -SslProtocol, ...).
        # Profile: Windows 10 / .NET 4.8 / WinPS 5.1. Alternatives shipped with
        # the module:
        #   win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework  (Server 2019)
        #   win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework (Server 2016)
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            )
            IgnoreCommands = @()
        }

        # .NET types, type accelerators and members absent from the 5.1 profile.
        PSUseCompatibleTypes = @{
            Enable         = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            )
            IgnoreTypes    = @()
        }
    }

    # PSUseCompatibleCmdlets is a different, older, name-only rule that is
    # ALWAYS enabled whether configured or not, and overlaps heavily with
    # PSUseCompatibleCommands above. Excluded to avoid duplicate findings —
    # drop this line if you want the coarser check as well.
    ExcludeRules = @('PSUseCompatibleCmdlets')
}
