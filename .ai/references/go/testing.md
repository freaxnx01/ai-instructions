# Go — testing

Base TDD rules (tests first, never modify a test to pass, never stub logic to go green,
run the full suite after changes, stop after 3 failed attempts) live in
`base-instructions.md`. This file covers the Go-specific detail.

## Layout & style

- Tests are `*_test.go` next to the code, in the **same package** for white-box tests or
  `<pkg>_test` for black-box/example tests. Prefer black-box for public API tests.
- **Hand-rolled fakes only.** Define a small interface at the consumer and pass a fake
  struct in tests. Do **not** add `testify`, `mockery`, `gomock`, or any codegen mocking
  framework.
- Use `t.TempDir()`, `t.Setenv()`, and `t.Cleanup()` — never leak files, env state, or
  goroutines between tests. Scrub ambient env (e.g. `TMUX`, `$HOME`-derived state) that
  would make a test environment-dependent.
- **Golden files** for large expected outputs: store under `testdata/`, refresh with an
  `-update` flag guard (`if *update { os.WriteFile(golden, got) }`).
- `t.Parallel()` for independent tests, but only when they share no mutable state;
  combine with `-race`.
- Test naming follows the base idiom adapted to Go:
  `TestFunc_StateUnderTest_ExpectedBehavior` (subtest names describe the case).

## Table-driven shape (the default)

```go
func TestResolve_CaseInsensitivePrefix_ReturnsCanonical(t *testing.T) {
    tests := []struct {
        name, input, want string
    }{
        {"exact", "FlowHub", "FlowHub"},
        {"lowercased", "flowhub", "FlowHub"},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Resolve(tt.input)
            if err != nil {
                t.Fatalf("Resolve(%q): %v", tt.input, err)
            }
            if got != tt.want {
                t.Errorf("Resolve(%q) = %q, want %q", tt.input, got, tt.want)
            }
        })
    }
}
```

## TUI testing — two tiers

Test TUIs at both levels; both gate CI.

### Tier 1 — in-process `Model` (fast, the default)

Use Charm's `teatest` (`github.com/charmbracelet/x/exp/teatest`) — first-party to the TUI
stack, not a mocking/assertion framework, so it's the one sanctioned test helper beyond
stdlib. Drive the program with `tm.Send(...)` (keys/msgs), assert on the final model, and
golden-file the rendered frames via `teatest.RequireEqualOutput` (refresh with `-update`).
Most `Update`/`View` behaviour is covered here without a terminal.

### Tier 2 — real PTY via tmux (true rendering)

Launch the built binary in a detached, isolated tmux session, `send-keys` to interact,
`capture-pane` to "screenshot" the rendered screen.

- **Never launch in the foreground.** A Bubble Tea TUI runs in alt-screen/raw mode and
  only exits on a quit key — a non-detached launch (`new-session` without `-d`, or running
  the binary directly) blocks the turn forever. Always `new-session -d`; every command
  returns instantly; guarantee teardown with `trap '… kill-server' EXIT`.
- **Isolate the socket** (`tmux -L <socket>`) so tests never touch ambient/real tmux
  sessions; scrub `$TMUX` (base test rules). Nothing leaks.
- **Size the pane** (`-x`/`-y`) for the layout — too small renders the fallback and you
  "screenshot" the wrong thing.
- **Wait for renders and `tea.Cmd`s** — sleep after launch and after each send-keys;
  capturing too early grabs a half-painted frame.
- **Drive with knowledge of the UI** — keys only do what the current state allows (e.g.
  Enter-on-filter that opens only when one item matches needs a *unique* filter). Point the
  binary at a fixture (`--base`).
- **Deterministic fixtures beat real state** — build the world the UI reads (e.g. a bare
  remote + worktrees in known states) so every cell is reproducible and offline.
  Time/network-dependent sequences only verify if you construct the conditions.

```bash
S=tuitest; trap "tmux -L $S kill-server 2>/dev/null" EXIT   # guaranteed cleanup
tmux -L $S new-session -d -s t -x 215 -y 50 './bin/app --base "$FIXTURE"'
sleep 1.5
tmux -L $S capture-pane -p -t t                 # "screenshot" the live screen
tmux -L $S send-keys -t t 'uniquefilter' Enter; sleep 0.5
tmux -L $S capture-pane -p -t t                 # assert on snapshot
tmux -L $S send-keys -t t 'q'                   # quit cleanly
```

## Required after every change

- `gofmt -l .` produces no output
- `go vet ./...` clean
- `golangci-lint run` clean
- `go test -race ./...` passes the **full** suite, not just the new test
