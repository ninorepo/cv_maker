#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" | while read -r dir; do
    svg="$dir/watermark.svg"
    attach_dir="$dir/attachment"

    # skip if missing
    [ -f "$svg" ] || continue
    [ -d "$attach_dir" ] || continue

    find "$attach_dir" -type f -name "*.wm.pdf" | while read -r pdf; do
        tmp="${pdf}.tmp.pdf"

        convert -density 300 \
            "$pdf" \
            "$svg" \
            -gravity center -composite \
            "$tmp"

        # replace original
        mv "$tmp" "$pdf"

        echo "Updated: $pdf"
    done
done

echo "Done."
