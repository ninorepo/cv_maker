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
# PROCESS ROW
# =========================
process_row() {
    line="$1"

    # -------------------------
    # SAFE CSV PARSE (mlr)
    # -------------------------
    headers=$(head -n 1 "$INPUT")

    values=$(echo "$line")

    # convert line into key-value pairs using mlr
    eval "$(echo "$headers" | tr ',' '\n' | awk '{print "h["NR"]="$0}')"

    # convert current CSV row into array
    mapfile -t fields < <(
        echo "$line" | mlr --csv cat | mlr --ocsv cat
    )

    # fallback: proper mlr extraction (SAFE)
    declare -A data

    IFS=',' read -r -a header_arr <<< "$headers"

    i=0
    for key in "${header_arr[@]}"; do
        key=$(echo "$key" | tr -d '"')

        value=$(echo "$line" | mlr --csv cut -f "$key" | tail -n +2)

        data["$key"]="$value"

        ((i++))
    done

    # -------------------------
    # SAFE FILENAME
    # -------------------------
    name="${data[${header_arr[0]}]}"
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

        content=$(cat "$workdir/$tpl_file")

        # replace placeholders safely
        for key in "${header_arr[@]}"; do
            key=$(echo "$key" | tr -d '"')

            val="${data[$key]}"

            # LaTeX escape (CRITICAL FIX)
            val=$(printf '%s' "$val" | sed \
                -e 's/\\/\\\\/g' \
                -e 's/&/\\&/g' \
                -e 's/%/\\%/g' \
                -e 's/\$/\\$/g' \
                -e 's/#/\\#/g' \
                -e 's/_/\\_/g' \
                -e 's/{/\\{/g' \
                -e 's/}/\\}/g')

            content=${content//"{{$key}}"/$val}
        done

        echo "$content" > "$workdir/$tpl_file"

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

            apply_watermark "$extra_pdf" "$wm_img" "$wm_out"
            final_pdf="$wm_out"
        fi

        pdf_list="$pdf_list $final_pdf"
    done

    # =========================
    # FINAL OUTPUT
    # =========================
    final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "Generating: $final_pdf"

    pdfunite $pdf_list "$final_pdf"

    rm -rf "$workdir"
}

# =========================
# MAIN LOOP (MLR FIXED CSV INPUT)
# =========================
mlr --csv cat "$INPUT" | tail -n +2 | while IFS= read -r line; do
    process_row "$line"
done
