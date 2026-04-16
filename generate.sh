#!/bin/bash
set -euo pipefail

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

# =========================
# DEPENDENCY CHECK
# =========================
for cmd in mlr jq pdflatex pdftoppm convert pdfunite; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd"
        exit 1
    }
done

# =========================
# WATERMARK FUNCTION
# =========================
apply_watermark() {
    local input="$1"
    local wm="$2"
    local output="$3"

    local tmpdir
    tmpdir=$(mktemp -d -t wm.XXXXXX)

    pdftoppm "$input" "$tmpdir/page" -png >/dev/null 2>&1

    for img in $(ls -1v "$tmpdir"/page-*.png); do
        convert "$img" "$wm" \
            -gravity center \
            -compose dissolve \
            -define compose:args=25 \
            -composite \
            "$img.wm.png"
    done

    convert $(ls -1v "$tmpdir"/*.wm.png) "$output"

    rm -rf "$tmpdir"
}

export -f apply_watermark

# =========================
# LATEX ESCAPE
# =========================
escape_latex() {
    printf '%s' "$1" | sed \
        -e 's/\\/\\\\/g' \
        -e 's/&/\\&/g' \
        -e 's/%/\\%/g' \
        -e 's/\$/\\$/g' \
        -e 's/#/\\#/g' \
        -e 's/_/\\_/g' \
        -e 's/{/\\{/g' \
        -e 's/}/\\}/g'
}

# =========================
# PROCESS ROW
# =========================
process_row() {
    local json="$1"

    declare -A data
    data=()

    while IFS="=" read -r k v; do
        data["$k"]="$v"
    done < <(echo "$json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')

    # =========================
    # SAFE FILENAME (FINAL RULE)
    # field1 + field2: lowercase, remove whitespace only
    # =========================
    local field1 field2 name

    field1="${data[${header_arr[0]}]:-output}"
    field2="${data[${header_arr[1]}]:-data}"

    sanitize_no_space() {
        echo "$1" \
            | tr '[:upper:]' '[:lower:]' \
            | tr -d '[:space:]'
    }

    field1=$(sanitize_no_space "$field1")
    field2=$(sanitize_no_space "$field2")

    name="${field1}_${field2}"

    local workdir
    workdir=$(mktemp -d -t pdfgen.XXXXXX)

    local pdf_list=()

    # =========================
    # TEMPLATE PROCESSING
    # =========================
    for template in "$TEMPLATE1" "$TEMPLATE2"; do

        local tpl_file
        tpl_file=$(basename "$template")

        cp "$template" "$workdir/"

        local content
        content=$(cat "$workdir/$tpl_file")

        for key in "${!data[@]}"; do
            val="${data[$key]}"
            val=$(escape_latex "$val")

            content=${content//"{{$key}}"/$val}
        done

        echo "$content" > "$workdir/$tpl_file"

        (
            cd "$workdir"
            pdflatex -interaction=nonstopmode -halt-on-error "$tpl_file" > latex.log 2>&1
        )

        pdf_list+=("$workdir/${tpl_file%.tex}.pdf")
    done

    # =========================
    # EXTRA PDFs + WATERMARK
    # =========================
    shopt -s nullglob
    for extra_pdf in "$EXTRA_PDF_DIR"/*.pdf; do

        local final_pdf="$extra_pdf"

        if [[ "$extra_pdf" == *.wm.pdf ]]; then
            local wm_img="$WATERMARK_DIR/default.png"
            local wm_out="$workdir/wm_$(basename "$extra_pdf")"

            apply_watermark "$extra_pdf" "$wm_img" "$wm_out"
            final_pdf="$wm_out"
        fi

        pdf_list+=("$final_pdf")
    done
    shopt -u nullglob

    # =========================
    # FINAL OUTPUT
    # =========================
    local final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "Generating: $final_pdf"

    pdfunite "${pdf_list[@]}" "$final_pdf"

    rm -rf "$workdir"
}

export -f process_row

# =========================
# MAIN LOOP
# =========================
mlr --icsv --ojson cat "$INPUT" \
    | jq -c '.[]' \
    | while read -r row; do
        process_row "$row"
    done
