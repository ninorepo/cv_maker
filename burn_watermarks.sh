#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"

echo "Scanning root: $TMP_ROOT"

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" | while read -r dir; do
    echo "DIR: $dir"

    svg="$dir/watermark.svg"
    wm_pdf="$dir/watermark.pdf"
    attach_dir="$dir/attachments"

    if [ ! -f "$svg" ]; then
        echo "  skip: no watermark.svg"
        continue
    fi

    if [ ! -d "$attach_dir" ]; then
        echo "  skip: no attachments/"
        continue
    fi

    # === convert SVG → PDF (once per folder) ===
    echo "  converting SVG → PDF"
    rsvg-convert -f pdf -o "$wm_pdf" "$svg"

    echo "  scanning PDFs in: $attach_dir"

    found_any=false

    while IFS= read -r pdf; do
        found_any=true
        echo "  found: $pdf"

        tmp="${pdf}.tmp.pdf"

        # === overlay using Ghostscript ===
        gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
            -sOutputFile="$tmp" \
            -c "<< /EndPage { pop 2 eq } >> setpagedevice" \
            -f "$pdf" "$wm_pdf"

        mv "$tmp" "$pdf"

        echo "  updated: $pdf"
    done < <(find "$attach_dir" -type f -iname "*.wm.pdf")

    if [ "$found_any" = false ]; then
        echo "  no *.wm.pdf found"
    fi
done

echo "Done."
