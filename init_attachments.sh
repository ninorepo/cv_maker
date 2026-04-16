#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
TMP_ROOT=".tmp_render"

echo "==> Copying attachments into row folders..."

# loop all row folders
find "$TMP_ROOT" -maxdepth 1 -type d -name ".*" | while read -r rowdir; do

    echo "Processing row: $(basename "$rowdir")"

    # create per-row attachments folder
    ROW_ATTACH="$rowdir/attachments"
    mkdir -p "$ROW_ATTACH"

    # skip if source doesn't exist
    [[ -d "$ATTACH_DIR" ]] || continue

    # copy all PDFs into row attachments folder
    find "$ATTACH_DIR" -type f -name "*.pdf" -exec cp -f {} "$ROW_ATTACH/" \;

done

echo "==> Attachment copy complete"
