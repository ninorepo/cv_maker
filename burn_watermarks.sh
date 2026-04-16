#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

echo "==> Starting watermark burn process..."

# loop each row folder
find "$TMP_ROOT" -maxdepth 1 -type d -name ".*" | while read -r rowdir; do

    echo "Row: $(basename "$rowdir")"

    WATERMARK="$rowdir/_watermark.png"

    # skip if watermark missing
    [[ -f "$WATERMARK" ]] || continue

    # process only wm.pdf files in this row
    find "$rowdir" -maxdepth 1 -type f -name "*.wm.pdf" | while read -r pdf; do

        filename="$(basename "$pdf")"
        echo "  Burning: $filename"

        workdir="$rowdir/.work_${filename%.wm.pdf}"
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

        # images → PDF (overwrite original)
        img2pdf "$workdir"/page-*.png -o "$pdf"

        # cleanup
        rm -rf "$workdir"

    done

done

echo "==> Watermark burn complete"
