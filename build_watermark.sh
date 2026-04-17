#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' dir; do

    wm_txt="$dir/watermark.txt"
    out_svg="$dir/watermark.svg"

    [[ -f "$wm_txt" ]] || continue

    wm_text="$(cat "$wm_txt")"

    # -------------------------
    # XML ESCAPE (CRITICAL)
    # -------------------------
    wm_text="$(printf '%s' "$wm_text" \
        | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"

    # -------------------------
    # BUILD TILED SVG (A4 STYLE GRID INSIDE SVG)
    # -------------------------
    cat > "$out_svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg"
     width="2480" height="3508"
     viewBox="0 0 2480 3508">

  <rect width="100%" height="100%" fill="white"/>

  <g opacity="0.12"
     fill="red"
     font-family="Arial"
     font-size="90"
     font-weight="bold">

    <!-- TILED WATERMARK GRID -->

    <!-- row 1 -->
    <text x="200" y="300" transform="rotate(-45 200 300)">$wm_text</text>
    <text x="800" y="300" transform="rotate(-45 800 300)">$wm_text</text>
    <text x="1400" y="300" transform="rotate(-45 1400 300)">$wm_text</text>
    <text x="2000" y="300" transform="rotate(-45 2000 300)">$wm_text</text>

    <!-- row 2 -->
    <text x="200" y="800" transform="rotate(-45 200 800)">$wm_text</text>
    <text x="800" y="800" transform="rotate(-45 800 800)">$wm_text</text>
    <text x="1400" y="800" transform="rotate(-45 1400 800)">$wm_text</text>
    <text x="2000" y="800" transform="rotate(-45 2000 800)">$wm_text</text>

    <!-- row 3 -->
    <text x="200" y="1300" transform="rotate(-45 200 1300)">$wm_text</text>
    <text x="800" y="1300" transform="rotate(-45 800 1300)">$wm_text</text>
    <text x="1400" y="1300" transform="rotate(-45 1400 1300)">$wm_text</text>
    <text x="2000" y="1300" transform="rotate(-45 2000 1300)">$wm_text</text>

    <!-- row 4 -->
    <text x="200" y="1800" transform="rotate(-45 200 1800)">$wm_text</text>
    <text x="800" y="1800" transform="rotate(-45 800 1800)">$wm_text</text>
    <text x="1400" y="1800" transform="rotate(-45 1400 1800)">$wm_text</text>
    <text x="2000" y="1800" transform="rotate(-45 2000 1800)">$wm_text</text>

    <!-- row 5 -->
    <text x="200" y="2300" transform="rotate(-45 200 2300)">$wm_text</text>
    <text x="800" y="2300" transform="rotate(-45 800 2300)">$wm_text</text>
    <text x="1400" y="2300" transform="rotate(-45 1400 2300)">$wm_text</text>
    <text x="2000" y="2300" transform="rotate(-45 2000 2300)">$wm_text</text>

    <!-- row 6 -->
    <text x="200" y="2800" transform="rotate(-45 200 2800)">$wm_text</text>
    <text x="800" y="2800" transform="rotate(-45 800 2800)">$wm_text</text>
    <text x="1400" y="2800" transform="rotate(-45 1400 2800)">$wm_text</text>
    <text x="2000" y="2800" transform="rotate(-45 2000 2800)">$wm_text</text>

    <!-- row 7 -->
    <text x="200" y="3300" transform="rotate(-45 200 3300)">$wm_text</text>
    <text x="800" y="3300" transform="rotate(-45 800 3300)">$wm_text</text>
    <text x="1400" y="3300" transform="rotate(-45 1400 3300)">$wm_text</text>
    <text x="2000" y="3300" transform="rotate(-45 2000 3300)">$wm_text</text>

  </g>

</svg>
EOF

done
