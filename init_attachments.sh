#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
WATERMARK_DIR="watermarks"
TMP_ROOT=".tmp_render"
STAGING="$TMP_ROOT/.attachments"
WATERMARK="$WATERMARK_DIR/default.png"

rm -rf "$TMP_ROOT"
mkdir -p "$STAGING"

# -----------------------------
# 1. Process .wm.pdf files
# -----------------------------
find "$ATTACH_DIR" -type f -name "*.wm.pdf" | while read -r pdf; do

    base="$(basename "$pdf" .wm.pdf)"
    echo "Watermarking: $pdf"

    workdir="$STAGING/__tmp_${base}"
    mkdir -p "$workdir"

    # PDF -> images
    pdftoppm -png "$pdf" "$workdir/page"

    # apply watermark
    for img in "$workdir"/page-*.png; do
        convert "$img" "$WATERMARK" -gravity center -compose over -composite "$img"
    done

    # images -> pdf
    convert "$workdir"/page-*.png "$STAGING/${base}.pdf"

    rm -rf "$workdir"

done

# -----------------------------
# 2. Copy normal PDFs (not .wm.pdf)
# -----------------------------
find "$ATTACH_DIR" -type f -name "*.pdf" ! -name "*.wm.pdf" | while read -r pdf; do
    echo "Copying: $pdf"
    cp "$pdf" "$STAGING/"
done
