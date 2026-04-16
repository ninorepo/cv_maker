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
# DEPENDENCIES CHECK
# =========================
for cmd in mlr pdflatex pdftoppm convert pdfunite; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd"
        exit 1
    }
done

# =========================
# WATERMARK
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
    local company="$1"
    local company_address="$2"
    local applicant="$3"
    local birthplace="$4"
    local home="$5"
    local phone="$6"
    local email="$7"
    local latest_education="$8"
    local current_education="$9"

    # =========================
    # FILENAME RULE (NO SPACE, LOWERCASE)
    # =========================
    sanitize_no_space() {
        echo "$1" \
            | tr '[:upper:]' '[:lower:]' \
            | tr -d '[:space:]'
    }

    local field1 field2 name

    field1=$(sanitize_no_space "$company")
    field2=$(sanitize_no_space "$applicant")

    name="${field1}_${field2}"

    local workdir
    workdir=$(mktemp -d -t pdfgen.XXXXXX)

    local pdf_list=()

    # =========================
    # TEMPLATE PROCESSING
    # =========================
    for template in "$TEMPLATE1" "$TEMPLATE2"; do
        local tpl_file content

        tpl_file=$(basename "$template")
        cp "$template" "$workdir/"

        content=$(cat "$workdir/$tpl_file")

        # replace variables
        content=${content//"{{company}}"/$(escape_latex "$company")}
        content=${content//"{{company_address}}"/$(escape_latex "$company_address")}
        content=${content//"{{applicant}}"/$(escape_latex "$applicant")}
        content=${content//"{{birthplace}}"/$(escape_latex "$birthplace")}
        content=${content//"{{home}}"/$(escape_latex "$home")}
        content=${content//"{{phone}}"/$(escape_latex "$phone")}
        content=${content//"{{email}}"/$(escape_latex "$email")}
        content=${content//"{{latest_education}}"/$(escape_latex "$latest_education")}
        content=${content//"{{current_education}}"/$(escape_latex "$current_education")}

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
            local wm_out="$workdir/wm_$(basename "$extra_pdf")"

            apply_watermark "$extra_pdf" "$WATERMARK_DIR/default.png" "$wm_out"
            final_pdf="$wm_out"
        fi

        pdf_list+=("$final_pdf")
    done
    shopt -u nullglob

    # =========================
    # OUTPUT FILE
    # =========================
    local final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "Generating: $final_pdf"

    pdfunite "${pdf_list[@]}" "$final_pdf"

    rm -rf "$workdir"
}

export -f process_row

# =========================
# MAIN LOOP (MLR ONLY SAFE CSV)
# =========================
mlr --icsv --opprint cat "$INPUT" \
| tail -n +2 \
| while IFS=$'\t' read -r company company_address applicant birthplace home phone email latest_education current_education; do
    process_row "$company" "$company_address" "$applicant" "$birthplace" "$home" "$phone" "$email" "$latest_education" "$current_education"
done
