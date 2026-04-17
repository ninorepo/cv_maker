#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"
OUTPUT_DIR="output"

#mkdir -p "$OUTPUT_DIR"

echo "==> Starting per-row PDF merge..."

# --------------------------------------------------
# 1. Load CSV mapping (id → field2, field3)
# --------------------------------------------------
declare -A FIELD2_MAP
declare -A FIELD3_MAP

while IFS=, read -r id f2 f3 _; do

    # skip header
    [[ "$id" == "id" ]] && continue

    # trim quotes
    id="${id//\"/}"
    f2="${f2//\"/}"
    f3="${f3//\"/}"

    FIELD2_MAP["$id"]="$f2"
    FIELD3_MAP["$id"]="$f3"

done < "$CSV_FILE"

# --------------------------------------------------
# helper: clean filename
# --------------------------------------------------
clean() {
    echo "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]//g'
}

# --------------------------------------------------
# 2. Process each CSV row id (source of truth)
# --------------------------------------------------
for rowid in "${!FIELD2_MAP[@]}"; do

    f2="${FIELD2_MAP[$rowid]}"
    f3="${FIELD3_MAP[$rowid]}"

    [[ -n "$f2" && -n "$f3" ]] || continue

    rowdir="$TMP_ROOT/.$rowid"
    ATTACH_DIR="$rowdir/attachments"

    [[ -d "$rowdir" ]] || continue

    # --------------------------------------------------
    # filename rule: field2_field3.pdf
    # --------------------------------------------------
    f2_clean="$(clean "$f2")"
    f3_clean="$(clean "$f3")"

    filename="${f2_clean}_${f3_clean}.pdf"
    OUTPUT_PDF="$OUTPUT_DIR/$filename"

    echo "Row: $rowid → $filename"

    pdfs_main=()
    pdfs_attach=()

    # --------------------------------------------------
    # 3. Main PDFs (row folder, exclude attachments)
    # --------------------------------------------------
    while IFS= read -r -d '' f; do
        pdfs_main+=("$f")
    done < <(
        find "$rowdir" -maxdepth 1 -type f -name "*.pdf" -print0
    )

    # sort main PDFs
    if [[ ${#pdfs_main[@]} -gt 0 ]]; then
        IFS=$'\n' pdfs_main=($(printf "%s\n" "${pdfs_main[@]}" | sort))
        unset IFS
    fi

    # --------------------------------------------------
    # 4. Attachment PDFs
    # --------------------------------------------------
    if [[ -d "$ATTACH_DIR" ]]; then
        while IFS= read -r -d '' f; do
            pdfs_attach+=("$f")
        done < <(
            find "$ATTACH_DIR" -type f -name "*.pdf" -print0
        )

        if [[ ${#pdfs_attach[@]} -gt 0 ]]; then
            IFS=$'\n' pdfs_attach=($(printf "%s\n" "${pdfs_attach[@]}" | sort))
            unset IFS
        fi
    fi

    # --------------------------------------------------
    # 5. Combine in correct order
    # --------------------------------------------------
    pdfs=("${pdfs_main[@]}" "${pdfs_attach[@]}")

    if [[ ${#pdfs[@]} -eq 0 ]]; then
        echo "  No PDFs found"
        continue
    fi

    # --------------------------------------------------
    # 6. Merge
    # --------------------------------------------------
    pdfunite "${pdfs[@]}" "$OUTPUT_PDF"

    echo "  Created: $OUTPUT_PDF"

done

echo "==> All done"
