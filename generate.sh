#!/bin/bash
set -e

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"

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

export -f apply_watermark

# =========================
# CSV PARSER (SAFE, NO PYTHON)
# =========================
parse_csv_line() {
    line="$1"

    awk -v line="$line" '
    BEGIN {
        FPAT = "([^,]+)|(\"[^\"]+\")"
        split(line, f, ",")

        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", f[i])
            print f[i]
        }
    }'
}

# =========================
# MAIN PROCESS
# =========================
process_row() {
    line="$1"

    # -------------------------
    # Load header
    # -------------------------
    IFS=',' read -r -a headers <<< "$(head -n 1 "$INPUT")"

    # -------------------------
    # Load values safely (quoted CSV supported)
    # -------------------------
    mapfile -t values < <(awk -v line="$line" '
    BEGIN {
        FPAT="([^,]+)|(\"[^\"]+\")"
        split(line, f, ",")
        for (i=1; i<=length(f); i++) {
            gsub(/^"|"$/, "", f[i])
            print f[i]
        }
    }')

    declare -A data

    for i in "${!headers[@]}"; do
        key="${headers[$i]}"
        val="${values[$i]}"

        key=$(echo "$key" | tr -d '"')
        val=$(echo "$val" | tr -d '"')

        data["$key"]="$val"
    done

    # -------------------------
    # SAFE FILENAME
    # -------------------------
    name="${data[${headers[0]}]}"
    name=$(echo "$name" | sed 's/[^a-zA-Z0-9]/_/g')

    workdir="$OUTPUT_DIR/tmp_$RANDOM"
    mkdir -p "$workdir"

    pdf_list=""

    # =========================
    # TEMPLATE PROCESSING
    # =========================
    for template in "$TEMPLATE1" "$TEMPLATE2"; do

        tpl_file=$(basename "$template")
        cp "$template" "$workdir/"

        # replace placeholders safely
        while IFS= read -r key; do
            val="${data[$key]}"

            # LaTeX escaping (IMPORTANT FIX for runaway string)
            val=$(echo "$val" | sed \
                -e 's/\\/\\\\/g' \
                -e 's/&/\\&/g' \
                -e 's/%/\\%/g' \
                -e 's/\$/\\$/g' \
                -e 's/#/\\#/g' \
                -e 's/_/\\_/g' \
                -e 's/{/\\{/g' \
                -e 's/}/\\}/g')

            sed -i "s/{{${key}}}/${val}/g" "$workdir/$tpl_file"

        done < <(printf "%s\n" "${headers[@]}")

        (
            cd "$workdir"
            pdflatex -interaction=nonstopmode "$tpl_file" > latex.log 2>&1
        )

        pdf="${tpl_file%.tex}.pdf"
        pdf_list="$pdf_list $workdir/$pdf"
    done

    # =========================
    # EXTRA PDFs + WATERMARK
    # =========================
    for extra_pdf in "$EXTRA_PDF_DIR"/*.pdf; do
        [ -e "$extra_pdf" ] || continue

        final_pdf="$extra_pdf"

        if [[ "$extra_pdf" == *.wm.pdf ]]; then
            wm_img="$WATERMARK_DIR/default.png"
            wm_out="$workdir/wm_$RANDOM.pdf"

            # NO bash -c (FIXED)
            apply_watermark "$extra_pdf" "$wm_img" "$wm_out"

            final_pdf="$wm_out"
        fi

        pdf_list="$pdf_list $final_pdf"
    done

    # =========================
    # FINAL MERGE
    # =========================
    final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "Generating: $final_pdf"

    pdfunite $pdf_list "$final_pdf"

    rm -rf "$workdir"
}

# =========================
# RUN (SAFE LOOP)
# =========================
tail -n +2 "$INPUT" | while IFS= read -r line; do
    process_row "$line"
done
