#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT="$global_path/.tmp_render"

echo "Scanning root: $TMP_ROOT"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" | while read -r dir; do
    echo "DIR: $dir"

    svg="$dir/watermark.svg"
    attach_dir="$dir/attachments"

    if [ ! -f "$svg" ]; then
        echo "  skip: no watermark.svg"
        continue
    fi

    if [ ! -d "$attach_dir" ]; then
        echo "  skip: no attachments/"
        continue
    fi

    echo "  converting SVG → PNG watermark"
    rsvg-convert -f png -w 2480 -h 3508 -o "$dir/watermark.png" -b none "$svg"

    echo "  scanning PDFs in: $attach_dir"

    found_any=false

    find "$attach_dir" -type f -iname "*.wm.pdf" | while read -r pdf; do
        found_any=true
        echo "  found: $pdf"

        base="${pdf%.pdf}"

        echo "  converting PDF → PNG pages"
        pdftoppm -png -r 300 "$pdf" "$base"

        for page in "${base}"-*.png; do
            out="${page%.png}.wm.png"

            echo "  overlaying watermark on $page"
            convert "$page" "$dir/watermark.png" \
                -gravity center -composite "$out"
        done

        echo "  rebuilding PDF"
        img2pdf "${base}"-*.wm.png -o "$pdf"

        echo "  cleaned temp images"
        rm -f "${base}"-*.png
        rm -f "${base}"-*.wm.png

        echo "  updated: $pdf"
    done

    if [ "$found_any" = false ]; then
        echo "  no *.wm.pdf found"
    fi
done

echo "Done."
