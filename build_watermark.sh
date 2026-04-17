#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' dir; do

    wm_txt="$dir/watermark.txt"
    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    tile="$dir/_wm_tile.png"
    wm_png="$dir/_watermark.png"

    # --------------------------------------------------
    # 1. FORCE TEXT RENDER (MOST STABLE IM PATH)
    # --------------------------------------------------
    convert -background white \
        -fill black \
        -font "$FONT" \
        -pointsize 40 \
        label:"$wm_text" \
        "$tile"

    # --------------------------------------------------
    # 2. ENSURE IMAGE EXISTS (DEBUG STEP)
    # --------------------------------------------------
    identify "$tile" || {
        echo "ERROR: tile not created"
        exit 1
    }

    # --------------------------------------------------
    # 3. ROTATE (SAFE)
    # --------------------------------------------------
    convert "$tile" -rotate 45 "$tile"

    # --------------------------------------------------
    # 4. TILE TO A4
    # --------------------------------------------------
    convert -size 2480x3508 tile:"$tile" \
        -background white -flatten \
        "$wm_png"

done
