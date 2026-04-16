#!/bin/bash
set -euo pipefail

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"
LOG_FILE="$OUTPUT_DIR/debug.log"

mkdir -p "$OUTPUT_DIR"

# =========================
# GLOBAL ERROR HANDLER
# =========================
trap 'echo "❌ ERROR on line $LINENO" | tee -a "$LOG_FILE"' ERR

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== STARTING PDF GENERATION ==="

# =========================
# DEPENDENCY CHECK
# =========================
for cmd in mlr pdflatex pdftoppm convert pdfunite; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Missing dependency: $cmd"
        exit 1
    fi
done

echo "✔ Dependencies OK"

# =========================
# WATERMARK
# =========================
apply_watermark() {
    local input="$1"
    local wm="$2"
    local output="$3"

    echo "🟡 Watermarking: $input"

    local tmpdir
    tmpdir=$(mktemp -d -t wm.XXXXXX)

    pdftoppm "$input" "$tmpdir/page" -png || {
        echo "❌ pdftoppm failed"
        return 1
    }

    for img in $(ls -1v "$tmpdir"/page-*.png); do
        convert "$img" "$wm" \
            -gravity center \
            -compose dissolve \
            -define compose:args=25 \
            -composite \
            "$img.wm.png" || {
                echo "❌ ImageMagick failed on $img"
                return 1
            }
    done

    convert $(ls -1v "$tmpdir"/*.wm.png) "$output" || {
        echo "❌ PDF merge failed in watermark"
        return 1
    }

    rm -rf "$tmpdir"

    echo "✔ Watermark done: $output"
}

export -f apply_watermark

# =========================
# LATE X ESCAPE
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

    echo "----------------------------"
    echo "🟢 Processing: $applicant"

    sanitize_no_space() {
        echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
    }

    local field1 field2 name
    field1=$(sanitize_no_space "$company")
    field2=$(sanitize_no_space "$applicant")

    name="${field1}_${field2}"

    echo "📄 Output name: $name"

    local workdir
    workdir=$(mktemp -d -t pdfgen.XXXXXX)

    local pdf_list=()

    # =========================
    # TEMPLATE
    # =========================
    for template in "$TEMPLATE1" "$TEMPLATE2"; do

        if [[ ! -f "$template" ]]; then
            echo "❌ Template not found: $template"
            exit 1
        fi

        local tpl_file content
        tpl_file=$(basename "$template")
        cp "$template" "$workdir/"

        content=$(cat "$workdir/$tpl_file")

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

        echo "🔧 Running pdflatex: $tpl_file"

        (
            cd "$workdir"
            pdflatex -interaction=nonstopmode -halt-on-error "$tpl_file" || {
                echo "❌ LaTeX failed: $tpl_file"
                cat latex.log
                exit 1
            }
        )

        pdf_list+=("$workdir/${tpl_file%.tex}.pdf")
    done

    # =========================
    # MERGE
    # =========================
    local final_pdf="$OUTPUT_DIR/${name}.pdf"

    echo "📦 Merging PDFs → $final_pdf"

    if ! pdfunite "${pdf_list[@]}" "$final_pdf"; then
        echo "❌ pdfunite failed"
        exit 1
    fi

    rm -rf "$workdir"

    echo "✔ DONE: $final_pdf"
}

export -f process_row

# =========================
# MAIN LOOP (MLR ONLY SAFE CSV)
# =========================
echo "📥 Reading CSV: $INPUT"

mlr --icsv --csv cat "$INPUT" \
| tail -n +2 \
| mlr --icsv --opprint cat \
| while IFS=$'\t' read -r company company_address applicant birthplace home phone email latest_education current_education; do

    process_row "$company" "$company_address" "$applicant" "$birthplace" "$home" "$phone" "$email" "$latest_education" "$current_education"

done

echo "=== FINISHED ==="
