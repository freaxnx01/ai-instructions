# Go — tech stack

| Layer | Technology |
|---|---|
| Language / toolchain | Go (latest stable), pinned in `go.mod` (`go 1.x`); Go modules only — no `GOPATH` or vendoring unless required |
| CLI framework | [`spf13/cobra`](https://github.com/spf13/cobra) — command tree, flags, shell completion |
| TUI | [Charm](https://github.com/charmbracelet) stack: `bubbletea` (Model-Update-View), `bubbles` (widgets), `lipgloss` (styling) |
| HTTP services | Standard library `net/http` with the Go 1.22+ `ServeMux` (method + path patterns); a router (`chi`) only when middleware warrants it |
| Logging | `log/slog` (structured) for diagnostics; `fmt.Fprintln(os.Stderr, …)` for user-facing CLI notices |
| Configuration | Env vars (12-factor) + Cobra flags, folded into one config struct |
| Testing | Standard library `testing`: table-driven tests, `t.Run` subtests, hand-rolled fakes. **No** `testify`, `mockery`, or `gomock` |
| Lint / format | `golangci-lint` with a committed `.golangci.yml` (bundles `gofmt`/`goimports`, `go vet`, `staticcheck`, `errcheck`, …) |
| Vulnerability scan | `govulncheck` (golang.org/x/vuln) in CI |
| Build orchestration | [`just`](https://github.com/casey/just) recipes driving `go build` with `-ldflags` version injection; CI via GitHub Actions |
| Release (optional) | `goreleaser` — only when multi-platform release artifacts are actually shipped, and only when the user asks |

## Project layout

```text
cmd/
  <binary>/              ← one dir per binary; main package + Cobra root wiring only
    main.go
    root.go
internal/                ← all non-public library code (the default home for logic)
  <pkg>/                 ← cohesive packages, one responsibility each
pkg/                     ← ONLY for code deliberately exported for external import
tool/                    ← build/release helper scripts (build.sh, cross-compile, etc.)
go.mod  go.sum
.golangci.yml
justfile
```
