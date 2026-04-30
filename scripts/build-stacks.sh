#!/usr/bin/env bash
# Compose .ai/stacks/_partials/dotnet-core.md + .ai/stacks/_layers/dotnet-<layer>.md
# into the flat .ai/stacks/dotnet-<layer>.md files that consumers fetch.
#
# CI runs this and fails the build if `git diff --exit-code .ai/stacks/dotnet-*.md`
# shows changes — preventing direct edits to the generated files.
set -euo pipefail

cd "$(dirname "$0")/.."

PARTIAL=".ai/stacks/_partials/dotnet-core.md"
LAYERS_DIR=".ai/stacks/_layers"
STACKS_DIR=".ai/stacks"

if [[ ! -f "$PARTIAL" ]]; then
    echo "ERROR: missing partial: $PARTIAL" >&2
    exit 1
fi

shopt -s nullglob
layers=( "$LAYERS_DIR"/dotnet-*.md )
if (( ${#layers[@]} == 0 )); then
    echo "ERROR: no layer files found under $LAYERS_DIR/dotnet-*.md" >&2
    exit 1
fi

for layer in "${layers[@]}"; do
    layer_name=$(basename "$layer" .md)        # e.g. dotnet-blazor
    out="$STACKS_DIR/$layer_name.md"

    {
        echo "[//]: # (GENERATED FILE — do not edit directly. Source: $PARTIAL + $layer. Run scripts/build-stacks.sh to regenerate.)"
        echo
        cat "$PARTIAL"
        echo
        echo "---"
        echo
        cat "$layer"
    } > "$out"

    echo "wrote $out"
done
