#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' dir; do

    wm_txt="$dir/watermark.txt"
    wm_png="$dir/_watermark.png"

    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    tile="$dir/_wm_tile.png"

    # --------------------------------------------------
    # 1. draw text (NO transparency here)
    # --------------------------------------------------
    convert -size 600x300 xc:white \
        -gravity center \
        -font DejaVu-Sans-Bold \
        -pointsize 40 \
        -fill "gray30" \
        -annotate 45 "$wm_text" \
        "$tile"

    # --------------------------------------------------
    # 2. apply transparency safely
    # --------------------------------------------------
    convert "$tile" \
        -alpha set \
        -channel A \
        -evaluate set 20% \
        +channel \
        "$tile"

    # --------------------------------------------------
    # 3. tile across A4 safely
    # --------------------------------------------------
    convert -size 2480x3508 tile:"$tile" \
        -background white -flatten \
        "$wm_png"

done
