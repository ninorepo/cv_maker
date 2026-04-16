#!/bin/bash
set -e

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"
JOBS=4

mkdir -p "$OUTPUT_DIR"

# =========================
# WATERMARK FUNCTION
# =========================
apply_watermark() {
    input="$1"
    wm="$2"
    output="$3"

    tmpdir=$(mktemp -d)

    pdftoppm "$input" "$tmpdir/page" -png

    for img in "$tmpdir"/page-*.png; do
        convert "$img" "$wm" \
            -gravity center \
            -compose dissolve \
            -define compose:args=25 \
            -composite \
            "$img.wm.png"
    done

    convert "$tmpdir"/*.wm.png "$output"

    rm -rf "$tmpdir"
}

# =========================
# PROCESS ONE ROW
# =========================
process_row() {
    line="$1"

    awk -v line="$line" \
        -v t1="$TEMPLATE1" \
        -v t2="$TEMPLATE2" \
        -v extra="$EXTRA_PDF_DIR" \
        -v outdir="$OUTPUT_DIR" \
        -v wm_dir="$WATERMARK_DIR" '
    BEGIN {
        FPAT = "([^,]+)|(\"[^\"]+\")"
    }

    {
        split(line, f, ",")

        # build header map
        if (NR == 1) {
            exit
        }

        # NOTE: headers passed via ENV is simpler avoided here
    }
    ' >/dev/null

    # =========================
    # REAL PROCESSING (BASH CONTROLLED)
    # =========================

    IFS=',' read -r -a headers <<< "$(head -n 1 "$INPUT")"
    IFS=',' read -r -a values <<< "$line"

    declare -A data

    for i in "${!headers[@]}"; do
        key="${headers[$i]}"
        val="${values[$i]}"

        key=$(echo "$key" | tr -d '"')
        val=$(echo "$val" | tr -d '"')

        data["$key"]="$val"
    done

    name="${data[${headers[0]}]}"
    name=$(echo "$name" | sed 's/[^a-zA-Z0-9]/_/g')

    workdir="$OUTPUT_DIR/tmp_$RANDOM"
    mkdir -p "$workdir"

    pdf_list=""

    # =========================
    # COMPILE TEMPLATES
    # =========================
    for template in "$TEMPLATE1" "$TEMPLATE2"; do

        cp "$template" "$workdir/"

        tpl_file=$(basename "$template")

        # replace placeholders
        for k in "${!data[@]}"; do
            v="${data[$k]}"
            v=$(echo "$v" | sed 's/[\/&]/\\&/g')

            sed -i "s/{{$k}}/$v/g" "$workdir/$tpl_file"
        done

        (
            cd "$workdir"
            pdflatex -interaction=nonstopmode "$tpl_file" > latex.log 2>&1
        )

        pdf="${tpl_file%.tex}.pdf"
        pdf_list="$pdf_list $workdir/$pdf"
    done

    # =========================
    # EXTRA PDFS + WATERMARK
    # =========================
    for extra_pdf in "$EXTRA_PDF_DIR"/*.pdf; do
        [ -e "$extra_pdf" ] || continue

        final_pdf="$extra_pdf"

        if [[ "$extra_pdf" == *.wm.pdf ]]; then
            wm_img="$WATERMARK_DIR/default.png"
            wm_out="$workdir/wm_$RANDOM.pdf"

            apply_watermark "$extra_pdf" "$wm_img" "$wm_out"
            final_pdf="$wm_out"
        fi

        pdf_list="$pdf_list $final_pdf"
    done

    # =========================
    # OUTPUT
    # =========================
    final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "Generating: $final_pdf"

    pdfunite $pdf_list "$final_pdf"

    rm -rf "$workdir"
}

export -f apply_watermark

# =========================
# MAIN LOOP (FIXED)
# =========================
tail -n +2 "$INPUT" | while IFS= read -r line; do
    process_row "$line"
done
