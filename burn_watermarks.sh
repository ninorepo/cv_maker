#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

echo "Scanning root: $TMP_ROOT"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" | while read -r dir; do
    echo "DIR: $dir"

    svg="$dir/watermark.svg"
    attach_dir="$dir/attachments"

    if [ ! -f "$svg" ]; then
        echo "  skip: no watermark.svg"
        continue
    fi

    if [ ! -d "$attach_dir" ]; then
        echo "  skip: no attachments/"
        continue
    fi

    echo "  scanning PDFs in: $attach_dir"

    found=0

    find "$attach_dir" -type f -name "*.wm.pdf" | while read -r pdf; do
        found=1
        echo "  found: $pdf"

        tmp="${pdf}.tmp.pdf"

        convert -density 300 \
            "$pdf" \
            "$svg" \
            -gravity center -composite \
            "$tmp"

        mv "$tmp" "$pdf"

        echo "  updated: $pdf"
    done

    if [ "$found" -eq 0 ]; then
        echo "  no *.wm.pdf found"
    fi
done

echo "Done."
