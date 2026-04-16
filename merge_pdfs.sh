#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

echo "==> Starting per-row PDF merge..."

# --------------------------------------------------
# 1. Load CSV mapping (id → field2, field3)
# --------------------------------------------------
declare -A FIELD2_MAP
declare -A FIELD3_MAP

while IFS=, read -r id f2 f3 _; do

    # skip header
    [[ "$id" == "id" ]] && continue

    # trim quotes + spaces
    id="${id//\"/}"
    f2="${f2//\"/}"
    f3="${f3//\"/}"

    # store
    FIELD2_MAP["$id"]="$f2"
    FIELD3_MAP["$id"]="$f3"

done < "$CSV_FILE"

# --------------------------------------------------
# helper: clean field
# --------------------------------------------------
clean() {
    echo "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]//g'
}

# --------------------------------------------------
# 2. Process each row folder
# --------------------------------------------------
find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" -print0 |
while IFS= read -r -d '' rowdir; do

    rowid="$(basename "$rowdir")"

    f2="${FIELD2_MAP[$rowid]}"
    f3="${FIELD3_MAP[$rowid]}"

    [[ -n "$f2" && -n "$f3" ]] || continue

    # --------------------------------------------------
    # filename rule: field2_field3.pdf
    # --------------------------------------------------
    f2_clean="$(clean "$f2")"
    f3_clean="$(clean "$f3")"

    filename="${f2_clean}_${f3_clean}.pdf"

    echo "Row: $rowid → $filename"

    ATTACH_DIR="$rowdir/attachments"
    OUTPUT_PDF="$OUTPUT_DIR/$filename"

    pdfs=()

    # --------------------------------------------------
    # PDFs in row folder (excluding attachments)
    # --------------------------------------------------
    while IFS= read -r -d '' f; do
        pdfs+=("$f")
    done < <(find "$rowdir" -maxdepth 1 -type f -name "*.pdf" ! -path "*/attachments/*" -print0)

    # --------------------------------------------------
    # PDFs in attachments
    # --------------------------------------------------
    if [[ -d "$ATTACH_DIR" ]]; then
        while IFS= read -r -d '' f; do
            pdfs+=("$f")
        done < <(find "$ATTACH_DIR" -maxdepth 1 -type f -name "*.pdf" -print0)
    fi

    # --------------------------------------------------
    # sort deterministically
    # --------------------------------------------------
    if [[ ${#pdfs[@]} -eq 0 ]]; then
        echo "  No PDFs found"
        continue
    fi

    IFS=$'\n' sorted=($(printf "%s\n" "${pdfs[@]}" | sort))
    unset IFS

    # --------------------------------------------------
    # merge
    # --------------------------------------------------
    pdfunite "${sorted[@]}" "$OUTPUT_PDF"

    echo "  Created: $OUTPUT_PDF"

done

echo "==> All done"
