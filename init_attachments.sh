#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
WATERMARK_DIR="watermarks"
TMP_ROOT=".tmp_render"
STAGING="$TMP_ROOT/_attachments"
WATERMARK="$WATERMARK_DIR/default.png"

echo "==> Preparing attachments..."

# --------------------------------------------------
# 1. Process WATERMARKED PDFs (*.wm.pdf)
# --------------------------------------------------
find "$ATTACH_DIR" -type f -name "*.wm.pdf" | while read -r pdf; do

    filename="$(basename "$pdf")"
    base="${filename%.wm.pdf}"

    echo "Watermark processing: $filename"

    workdir="$TMP_ROOT/.tmp_${base}"
    mkdir -p "$workdir"

    # PDF → PNG pages
    pdftoppm -png "$pdf" "$workdir/page"

    # apply watermark on each page
    for img in "$workdir"/page-*.png; do
        convert "$img" "$WATERMARK" \
            -gravity center \
            -compose over \
            -composite \
            "$img"
    done

    # PNG → PDF (SAFE, no ImageMagick PDF handling)
    img2pdf "$workdir"/page-*.png -o "$STAGING/$filename"

    # cleanup temp images
    rm -rf "$workdir"

done

# --------------------------------------------------
# 2. Copy NORMAL PDFs (unchanged filenames)
# --------------------------------------------------
find "$ATTACH_DIR" -type f -name "*.pdf" ! -name "*.wm.pdf" | while read -r pdf; do

    filename="$(basename "$pdf")"

    echo "Copying: $filename"

    cp "$pdf" "$STAGING/$filename"

done

echo "==> Attachment staging complete:"
echo "    $STAGING"
