#!/usr/bin/env bash
# Fixture tests for scripts/check-rules.sh.
#
# Each case under tests/fixtures/rules/<case>/ is a miniature repo root: it
# holds a .ai/rules/ tree (and, where the case needs one, a .ai/stacks/ file).
# The validator is run against that root and its exit code plus its stderr are
# asserted — so every documented failure mode has to name the offending file
# and say why, not merely exit non-zero.
#
# Exit codes: 0 all cases pass, 1 one or more cases failed.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-rules.sh"
FIXTURES="$SCRIPT_DIR/fixtures/rules"

failures=0
cases=0

# assert_case <fixture-dir-or-path> <expected-exit> [expected-stderr-substring...]
#
# The first argument is resolved relative to the fixture directory, so a
# deliberately absent root can be passed as a name that does not exist.
assert_case() {
    local case_name="$1" expected_exit="$2"
    shift 2

    local root="$FIXTURES/$case_name"
    local stderr rc=0
    cases=$((cases + 1))

    # Keep stderr only: the assertions are about the diagnostics, not the
    # informational stdout.
    stderr="$(bash "$CHECK" "$root" 2>&1 1>/dev/null)" || rc=$?

    if [[ "$rc" -ne "$expected_exit" ]]; then
        printf 'FAIL %s: expected exit %s, got %s\n' "$case_name" "$expected_exit" "$rc" >&2
        printf '     stderr: %s\n' "$stderr" >&2
        failures=$((failures + 1))
        return 0
    fi

    local needle
    for needle in "$@"; do
        if [[ "$stderr" != *"$needle"* ]]; then
            printf 'FAIL %s: stderr does not mention %q\n' "$case_name" "$needle" >&2
            printf '     stderr: %s\n' "$stderr" >&2
            failures=$((failures + 1))
            return 0
        fi
    done

    printf 'ok   %s\n' "$case_name"
}

# A well-formed tree — one base rule and one stack rule — must pass clean.
assert_case valid 0

# Windows line endings must not change the verdict: the same valid content
# with \r\n endings still parses.
assert_case crlf 0

# A rule with no glob has no reason to be a rule; that content belongs in base
# or the overlay.
assert_case missing-globs 1 '.ai/rules/base/no-globs.md' 'globs'
assert_case empty-globs 1 '.ai/rules/base/empty.md' 'globs'

# `name` is the identity the sync skill installs under; a stem mismatch would
# silently install under the wrong name.
assert_case name-mismatch 1 '.ai/rules/base/mismatch.md' 'name'

# A Markdown file with no frontmatter at all must fail, not be skipped.
assert_case no-frontmatter 1 '.ai/rules/base/bare.md' 'frontmatter'

# A stack folder with no matching overlay (a typo like `dotnet-webap`) would
# mean sync never installs the rule for any stack.
assert_case unknown-stack 1 '.ai/rules/dotnet-webap/typo.md' 'no .ai/stacks/'

# base/ applies to every stack, so a stack folder repeating a base name would
# load the name twice.
assert_case duplicate-name 1 '.ai/rules/ci/shared.md' 'duplicate'

# A rule outside the two-folder model (dropped straight into .ai/rules/) would
# never be installed by sync.
assert_case misplaced 1 '.ai/rules/loose.md' 'not at .ai/rules/'

# Frontmatter that opens but never closes must fail, not swallow the body.
assert_case unterminated 1 '.ai/rules/base/open.md' 'unterminated'

# A root that does not exist is a usage error, not a validation failure.
assert_case does-not-exist 2

if [[ "$failures" -gt 0 ]]; then
    printf '\n%s of %s cases failed\n' "$failures" "$cases" >&2
    exit 1
fi

printf '\nall %s cases passed\n' "$cases"
