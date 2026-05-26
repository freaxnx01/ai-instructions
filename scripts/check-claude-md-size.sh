#!/usr/bin/env bash
# Verify that the CLAUDE.md a target project would assemble (base + one stack
# overlay + sync header) stays under Claude Code's performance budget.
#
# Claude Code prints "Large CLAUDE.md will impact performance (>40k chars)"
# once the file exceeds 40,000 bytes. We enforce a 39,000-byte ceiling here
# so that small additions to base or any stack do not silently push consumers
# over the line.
#
# Override the budget by exporting MAX_ASSEMBLED_BYTES.
set -euo pipefail

cd "$(dirname "$0")/.."

MAX_ASSEMBLED_BYTES="${MAX_ASSEMBLED_BYTES:-39000}"
BASE=".ai/base-instructions.md"
STACKS_DIR=".ai/stacks"

if [[ ! -f "$BASE" ]]; then
    echo "ERROR: missing $BASE" >&2
    exit 1
fi

# Header inserted by /sync-ai-instructions when writing CLAUDE.md.
# Must stay in sync with the sync-ai-instructions skill (Step 4).
read -r -d '' SYNC_HEADER <<'EOF' || true
[//]: # (Source of truth: .ai/base-instructions.md + .ai/stacks/<stack>.md — update those, then regenerate this file by re-running /sync-ai-instructions)

# CLAUDE.md

Agent context for Claude Code. Read this before taking any action in this repository.

EOF

shopt -s nullglob
stacks=( "$STACKS_DIR"/*.md )
if (( ${#stacks[@]} == 0 )); then
    echo "ERROR: no stack files found under $STACKS_DIR/*.md" >&2
    exit 1
fi

base_bytes=$(wc -c < "$BASE")
header_bytes=$(printf '%s' "$SYNC_HEADER" | wc -c)
fail=0

printf '%-20s %10s %12s %s\n' "stack" "stack(B)" "assembled(B)" "status"
printf '%-20s %10s %12s %s\n' "--------------------" "----------" "------------" "------"

for stack_file in "${stacks[@]}"; do
    name=$(basename "$stack_file" .md)
    stack_bytes=$(wc -c < "$stack_file")
    # Assembled = header + base + "\n" + stack (matches sync skill assembly).
    assembled=$(( header_bytes + base_bytes + 1 + stack_bytes ))

    if (( assembled > MAX_ASSEMBLED_BYTES )); then
        status="FAIL (>$MAX_ASSEMBLED_BYTES)"
        fail=1
    else
        status="ok"
    fi

    printf '%-20s %10d %12d %s\n' "$name" "$stack_bytes" "$assembled" "$status"
done

if (( fail != 0 )); then
    echo
    echo "ERROR: one or more assembled CLAUDE.md files exceed $MAX_ASSEMBLED_BYTES bytes." >&2
    echo "Trim the offending stack file under $STACKS_DIR/_layers/ or _partials/," >&2
    echo "or reduce $BASE; then re-run scripts/build-stacks.sh and this check." >&2
    exit 1
fi
