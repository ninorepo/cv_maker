#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

find "$TMP_ROOT" -maxdepth 1 -type d -name ".*" | while read -r dir; do

    wm_txt="$dir/watermark.txt"
    wm_png="$dir/_watermark.png"

    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    # escape for shell safety
    wm_text="${wm_text//\"/\\\"}"

    tile="$dir/_wm_tile.png"

    # create tile
    convert -size 600x300 xc:none \
        -gravity center \
        -fill 'rgba(128,128,128,0.15)' \
        -font DejaVu-Sans-Bold \
        -pointsize 40 \
        -annotate 45 "$wm_text" \
        "$tile"

    # tile across A4
    convert -size 2480x3508 tile:"$tile" "$wm_png"

done
