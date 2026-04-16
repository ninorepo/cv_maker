#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

echo "==> Starting watermark burn process..."

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' rowdir; do

    echo "Row: $(basename "$rowdir")"

    WATERMARK="$rowdir/_watermark.png"
    ATTACH_DIR="$rowdir/attachments"

    # skip if watermark or attachments missing
    [[ -f "$WATERMARK" ]] || continue
    [[ -d "$ATTACH_DIR" ]] || continue

    # process ONLY wm.pdf inside attachments folder
    find "$ATTACH_DIR" -maxdepth 1 -type f -name "*.wm.pdf" -print0 |
    while IFS= read -r -d '' pdf; do

        filename="$(basename "$pdf")"
        echo "  Burning: $filename"

        workdir="$ATTACH_DIR/.work_${filename%.wm.pdf}"
        mkdir -p "$workdir"

        # PDF → images
        pdftoppm -png "$pdf" "$workdir/page"

        # apply watermark per page
        for img in "$workdir"/page-*.png; do
            convert "$img" "$WATERMARK" \
                -gravity center \
                -compose over \
                -composite \
                "$img"
        done

        # images → PDF (overwrite original wm.pdf)
        img2pdf "$workdir"/page-*.png -o "$pdf"

        # cleanup
        rm -rf "$workdir"

    done

done

echo "==> Watermark burn complete"
