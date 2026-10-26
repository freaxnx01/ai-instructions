---
name: bash-conventions
globs: ["**/*.sh"]
---

## Bash Conventions

Every script starts with the same prelude:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e` — fail on any command error
- `set -u` — fail on unset variables
- `set -o pipefail` — fail when any command in a pipeline errors
- Restricted `IFS` — prevents word-splitting surprises with filenames containing spaces

Conventions:

- **Quote every variable expansion** — `"$var"`, `"${arr[@]}"`. Unquoted is a bug.
- **`[[ ... ]]` over `[ ... ]`** — only POSIX `sh` warrants `[ ... ]`.
- **`$(...)` over backticks** — backticks don't nest cleanly.
- **Functions over inline blocks** — anything reused twice goes into `lib/`.
- **Exit codes are part of the API** — `0` success, `1` generic error, `2` usage error, `64+` task-specific. Document them.
- **Env-driven, not flag-driven, for CI scripts** — workflows pass values via `env:`. Reserve flags for human-invoked tools.
- **No `eval`** — ever. If you think you need it, you need a different design.
- **Use `mktemp` for temp files** and clean them up with `trap '... ' EXIT`.
- **`printf` over `echo` for anything with formatting** — `echo` semantics differ across shells.
- **Strict on unset config**: `: "${REQUIRED_VAR:?REQUIRED_VAR must be set}"` at the top of the script.
