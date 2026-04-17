#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

FONT="DejaVu-Sans-Bold"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' dir; do

    wm_txt="$dir/watermark.txt"
    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    tile="$dir/_wm_tile.png"
    wm_png="$dir/_watermark.png"

    # --------------------------------------------------
    # 1. CREATE TILE (stable text rendering)
    # --------------------------------------------------
    convert -size 600x300 xc:white \
        -font "$FONT" \
        -pointsize 40 \
        -fill gray30 \
        -gravity center \
        -annotate 0 "$wm_text" \
        "$tile"

    # --------------------------------------------------
    # 2. ROTATE AFTER (safe, but separate file)
    # --------------------------------------------------
    convert "$tile" -rotate 45 "$tile"

    # --------------------------------------------------
    # 3. TILE TO A4
    # --------------------------------------------------
    convert -size 2480x3508 tile:"$tile" \
        -background white -flatten \
        "$wm_png"

done
