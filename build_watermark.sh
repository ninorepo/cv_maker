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
    # 1. FORCE text rendering (no annotate bug)
    # --------------------------------------------------
    convert -background white \
        -fill "rgba(0,0,0,0.15)" \
        -font DejaVu-Sans-Bold \
        -pointsize 40 \
        -gravity center \
        -size 600x300 \
        caption:"$wm_text" \
        "$tile"

    # --------------------------------------------------
    # 2. rotate AFTER rendering (safe step)
    # --------------------------------------------------
    convert "$tile" -rotate 45 "$tile"

    # --------------------------------------------------
    # 3. tile safely
    # --------------------------------------------------
    convert -size 2480x3508 tile:"$tile" \
        -background white -flatten \
        "$wm_png"

done
