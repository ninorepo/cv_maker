#!/usr/bin/env bash
set -euo pipefail

ROOT="$global_path/.tmp_render"

# compile every .tex file found under ROOT
find "$ROOT" -type f -name "*.tex" | while read -r tex; do
    dir="$(dirname "$tex")"

    echo "Compiling: $tex"

    (
        cd "$dir"
        pdflatex -interaction=nonstopmode "$(basename "$tex")" > /dev/null 2>&1
    )
done

# cleanup LaTeX temporary files
find "$ROOT" -type f \( -name "*.aux" -o -name "*.log" -o -name "*.out" \) -delete
