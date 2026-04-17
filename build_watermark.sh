#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' dir; do

    wm_txt="$dir/watermark.txt"
    wm_png="$dir/_watermark.png"

    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    # --------------------------------------------------
    # 1. CREATE SVG (TEXT SOURCE)
    # --------------------------------------------------
    cat > "$dir/_wm.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="600" height="300">
  <text x="50%" y="50%"
        text-anchor="middle"
        dominant-baseline="middle"
        font-size="40"
        fill="black"
        opacity="0.15"
        transform="rotate(-45 300 150)">
    $wm_text
  </text>
</svg>
EOF

    # --------------------------------------------------
    # 2. SVG → PNG TILE (NO IMAGEMAGICK TEXT BUGS)
    # --------------------------------------------------
    rsvg-convert "$dir/_wm.svg" -w 600 -h 300 -o "$dir/_wm_tile.png"

    # --------------------------------------------------
    # 3. TILE INTO A4 WATERMARK
    # --------------------------------------------------
    convert -size 2480x3508 tile:"$dir/_wm_tile.png" \
        -background white -flatten \
        "$wm_png"

done
