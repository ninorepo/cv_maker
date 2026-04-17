#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
TMP_ROOT=".tmp_render"

echo "==> Copying attachments into row folders..."

# --------------------------------------------------
# 1. Validate source
# --------------------------------------------------
if [[ ! -d "$ATTACH_DIR" ]]; then
    echo "ERROR: attachments directory not found"
    exit 1
fi

# --------------------------------------------------
# 2. Process ONLY valid row folders
#    (dot + alphanumeric safe IDs)
# --------------------------------------------------
find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d \
    -name ".[0-9a-zA-Z_-]*" -print0 |
while IFS= read -r -d '' rowdir; do

    base="$(basename "$rowdir")"

    # extra safety: exclude wrong folders
    [[ "$base" == "attachments" ]] && continue
    [[ "$base" == .work* ]] && continue

    echo "Processing row: $base"

    # --------------------------------------------------
    # 3. Create attachments folder ONLY inside row
    # --------------------------------------------------
    ROW_ATTACH="$rowdir/attachments"
    mkdir -p "$ROW_ATTACH"

    # --------------------------------------------------
    # 4. Copy PDFs into row attachments
    # --------------------------------------------------
    find "$ATTACH_DIR" -type f -name "*.pdf" -print0 |
    while IFS= read -r -d '' file; do
        cp -f "$file" "$ROW_ATTACH/"
    done

done

echo "==> Attachment copy complete"
