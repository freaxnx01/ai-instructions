# .NET Quality Gates

We gate agent-generated .NET PRs on **four independent quality signals** plus a
vulnerable-package scan and a diff-scope guard. They are independent on purpose:
each catches a failure the others miss.

## The four signals

| Signal | Rule / tool | What it catches that the others don't |
|---|---|---|
| Cyclomatic complexity | analyzer **CA1502** | a single method with too many branches — hard to test exhaustively, easy to hide a bug in |
| Class coupling | analyzer **CA1506** | a type/method wired to too many other types — fragile, hard to change in isolation |
| Method length | Code Metrics + `check-method-size.py` | sprawling methods doing too much (no analyzer measures raw executable lines) |
| Mutation score | **Stryker.NET** | tests that *run* the code but assert nothing meaningful — coverage theatre |

Complexity and coupling are structural; method length is size; mutation score is
*test quality*. A PR can pass all the others and still be untested — that's why
mutation is in the set.

## Thresholds live in config, not prose

The numeric thresholds are **not** restated here. They live in exactly one place
each, under [`templates/dotnet/`](https://github.com/freaxnx01/ai-instructions/tree/main/templates/dotnet):

- complexity / coupling → `CodeMetricsConfig.txt`
- mutation break score → `stryker-config.json`
- method length / added-C#-lines → the caller workflow `quality.yml` inputs

To change a threshold, edit that one file — never duplicate the number into a
second config or into this document.

## Warnings-as-errors + legacy carve-out

`Directory.Build.props` sets `TreatWarningsAsErrors`: an agent-introduced
warning fails the build. Adopt it on an existing codebase **incrementally** via
`WarningsNotAsErrors` (each entry carrying a `# debt:` note and a tracked
follow-up), not by turning the policy off.

Legacy **.NET Framework 4.8** trees cannot satisfy the modern analyzers; they
opt out by setting `<QualityGatesOptOut>true</QualityGatesOptOut>`, so the strict
props never point at legacy code.

## Gates must be demonstrated failing

A gate that has never been seen go red is indistinguishable from a no-op. The
mechanism ships with a self-validating test suite that feeds each gate a
known-bad fixture and asserts it returns non-zero — see agent-pipeline
[`gate-tests/`](https://github.com/freaxnx01/agent-pipeline/tree/main/gate-tests)
and `gate-selftest.yml`. Hold consumer adoption to the same bar (e.g. FlowHub's
`make verify-gates`).

## Mechanism

The gates run via the central composite action
[`freaxnx01/agent-pipeline/.github/actions/dotnet-quality`](https://github.com/freaxnx01/agent-pipeline/tree/main/.github/actions/dotnet-quality).
Its README is the single home for the caller snippet — the seeded
`templates/dotnet/quality.yml` is a ready-to-fill copy. Don't duplicate the
snippet here.

## What lives where

| Concern | Repo | Files |
|---|---|---|
| Policy / standard / rationale | ai-instructions | this file (`.ai/references/dotnet/quality-gates.md`) |
| Mechanism (gates run here) | agent-pipeline | `.github/actions/dotnet-quality/` |
| Gate self-tests (proof gates fire) | agent-pipeline | `gate-tests/`, `gate-selftest.yml` |
| Threshold values (source of truth) | ai-instructions | `templates/dotnet/*` |
| Per-project config (seeded copy) | each project (e.g. FlowHub) | repo root |
| Caller workflow | each project | `.github/workflows/quality.yml` |
