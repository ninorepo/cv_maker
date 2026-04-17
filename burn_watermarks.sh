#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

echo "==> Starting VECTOR watermark burn process..."

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' rowdir; do

    echo "Row: $(basename "$rowdir")"

    WATERMARK_SVG="$rowdir/watermark.svg"
    WATERMARK_PDF="$rowdir/watermark.pdf"
    ATTACH_DIR="$rowdir/attachments"

    [[ -f "$WATERMARK_SVG" ]] || continue
    [[ -d "$ATTACH_DIR" ]] || continue

    # --------------------------------------------------
    # 1. SVG → PDF (VECTOR WATERMARK)
    # --------------------------------------------------
    rsvg-convert "$WATERMARK_SVG" \
        -f pdf \
        -o "$WATERMARK_PDF"

    # --------------------------------------------------
    # 2. APPLY TO EACH PDF
    # --------------------------------------------------
    find "$ATTACH_DIR" -maxdepth 1 -type f -name "*.wm.pdf" -print0 |
    while IFS= read -r -d '' pdf; do

        filename="$(basename "$pdf")"
        echo "  Burning: $filename"

        output_pdf="${pdf%.wm.pdf}.pdf"

        # --------------------------------------------------
        # 3. VECTOR OVERLAY (NO RASTERIZATION)
        # --------------------------------------------------
        pdftk "$pdf" \
            background "$WATERMARK_PDF" \
            output "$output_pdf"

    done

done

echo "==> VECTOR watermark burn complete"
