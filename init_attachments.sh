#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
WATERMARK_DIR="watermarks"
TMP_ROOT=".tmp_render"
STAGING="$TMP_ROOT/_attachments"
WATERMARK="$WATERMARK_DIR/default.png"

rm -rf "$TMP_ROOT"
mkdir -p "$STAGING"

# ---------------------------------------
# 1. Process .wm.pdf (KEEP ORIGINAL NAME)
# ---------------------------------------
find "$ATTACH_DIR" -type f -name "*.wm.pdf" | while read -r pdf; do

    filename="$(basename "$pdf")"
    base="${filename%.wm.pdf}"

    echo "Watermarking: $filename"

    workdir="$STAGING/.tmp_${base}"
    mkdir -p "$workdir"

    # PDF -> PNG pages
    pdftoppm -png "$pdf" "$workdir/page"

    # apply watermark
    for img in "$workdir"/page-*.png; do
        convert "$img" "$WATERMARK" -gravity center -compose over -composite "$img"
    done

    # PNG -> PDF (KEEP SAME NAME AS ORIGINAL FILE)
    convert "$workdir"/page-*.png "$STAGING/$filename"

    rm -rf "$workdir"

done

# ---------------------------------------
# 2. Copy normal PDFs (UNCHANGED NAMES)
# ---------------------------------------
find "$ATTACH_DIR" -type f -name "*.pdf" ! -name "*.wm.pdf" | while read -r pdf; do
    filename="$(basename "$pdf")"
    echo "Copying: $filename"
    cp "$pdf" "$STAGING/$filename"
done
