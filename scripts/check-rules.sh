#!/usr/bin/env bash
# Validate the path-scoped rule tier under .ai/rules/.
#
# A rule is a Markdown file with `name` + `globs` frontmatter, living at
#
#   .ai/rules/base/<name>.md      — loaded by every stack
#   .ai/rules/<stack>/<name>.md   — loaded by that stack only
#
# and `<stack>` must name a real overlay (.ai/stacks/<stack>.md), otherwise the
# sync skill would silently never install the rule. A rule without a glob is
# invalid by construction: unscoped content belongs in base-instructions.md or
# in the overlay, not here.
#
# Line endings are normalised before parsing, so a rule authored on Windows is
# judged on its content rather than on its \r bytes.
#
# Usage: check-rules.sh [ROOT]        ROOT defaults to the repo root.
# Exit:  0 ok · 1 validation failure · 2 usage error
set -euo pipefail
IFS=$'\n\t'

usage() {
    printf 'usage: %s [ROOT]\n' "${0##*/}" >&2
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 2
fi

if [[ "$#" -gt 1 ]]; then
    printf 'ERROR: too many arguments\n' >&2
    usage
    exit 2
fi

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ ! -d "$ROOT" ]]; then
    printf 'ERROR: %s: not a directory\n' "$ROOT" >&2
    usage
    exit 2
fi

RULES_DIR="$ROOT/.ai/rules"

if [[ ! -d "$RULES_DIR" ]]; then
    echo "No rules — skipping."
    exit 0
fi

# A glob list is a non-empty YAML flow sequence of quoted strings:
#   ["**/*.sh"]   or   [".github/workflows/**", ".github/actions/**"]
# `[]` deliberately does not match — see the header.
GLOBS_RE='^\[ *".+" *(, *".+" *)*\]$'

violations=0

fail() {
    # fail <path-relative-to-root> <reason>
    printf 'ERROR: %s: %s\n' "$1" "$2" >&2
    violations=$((violations + 1))
}

# Names already seen, keyed by name, valued by the folder that claimed it.
declare -A base_names=()

mapfile -t rule_files < <(find "$RULES_DIR" -type f -name '*.md' | sort)

# Base rules first, so that a stack rule colliding with a base name is reported
# against the stack file — the one that has to be renamed or removed.
for pass in base stack; do
    for file in "${rule_files[@]:-}"; do
        [[ -n "$file" ]] || continue

        rel="${file#"$ROOT"/}"
        stem="$(basename "$file" .md)"
        folder="$(basename "$(dirname "$file")")"

        # Reject anything that is not exactly .ai/rules/<folder>/<name>.md —
        # a rule dropped straight into .ai/rules/ or nested a level deeper
        # would be invisible to the sync skill's two-folder model.
        if [[ "$rel" != ".ai/rules/$folder/$stem.md" ]]; then
            [[ "$pass" == base ]] || continue
            fail "$rel" "not at .ai/rules/<base|stack>/<name>.md"
            continue
        fi

        if [[ "$folder" == base ]]; then
            [[ "$pass" == base ]] || continue
        else
            [[ "$pass" == stack ]] || continue
            if [[ ! -f "$ROOT/.ai/stacks/$folder.md" ]]; then
                fail "$rel" "rule folder '$folder' has no .ai/stacks/$folder.md overlay"
                continue
            fi
        fi

        mapfile -t lines < <(tr -d '\r' < "$file")

        if [[ "${#lines[@]}" -eq 0 || "${lines[0]}" != "---" ]]; then
            fail "$rel" "no YAML frontmatter — must start with a '---' line"
            continue
        fi

        # Frontmatter is everything between the first two '---' lines.
        close=0
        for ((i = 1; i < ${#lines[@]}; i++)); do
            if [[ "${lines[i]}" == "---" ]]; then
                close="$i"
                break
            fi
        done

        if [[ "$close" -eq 0 ]]; then
            fail "$rel" "unterminated YAML frontmatter — no closing '---' line"
            continue
        fi

        name=""
        globs=""
        for ((i = 1; i < close; i++)); do
            case "${lines[i]}" in
                name:*)  name="${lines[i]#name:}" ;;
                globs:*) globs="${lines[i]#globs:}" ;;
            esac
        done
        # Trim the surrounding whitespace YAML allows after the colon.
        name="${name#"${name%%[![:space:]]*}"}"
        name="${name%"${name##*[![:space:]]}"}"
        globs="${globs#"${globs%%[![:space:]]*}"}"
        globs="${globs%"${globs##*[![:space:]]}"}"

        ok=1

        if [[ -z "$name" ]]; then
            fail "$rel" "frontmatter has no 'name' key"
            ok=0
        elif [[ "$name" != "$stem" ]]; then
            fail "$rel" "frontmatter name '$name' does not match the filename stem '$stem'"
            ok=0
        fi

        if [[ -z "$globs" ]]; then
            fail "$rel" "frontmatter has no 'globs' key — a rule without a glob belongs in base or the overlay"
            ok=0
        elif [[ ! "$globs" =~ $GLOBS_RE ]]; then
            fail "$rel" "globs must be a non-empty list of quoted patterns, e.g. globs: [\"**/*.sh\"] — got: $globs"
            ok=0
        fi

        [[ "$ok" -eq 1 ]] || continue

        if [[ "$folder" == base ]]; then
            base_names["$name"]="$rel"
        elif [[ -n "${base_names[$name]:-}" ]]; then
            fail "$rel" "duplicate rule name '$name' — already defined by ${base_names[$name]}"
        fi
    done
done

if [[ "$violations" -gt 0 ]]; then
    printf '%s rule violation(s) found.\n' "$violations" >&2
    exit 1
fi

printf 'Validated %s rule file(s).\n' "${#rule_files[@]}"
