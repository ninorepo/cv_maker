#!/usr/bin/env bash
set -euo pipefail

ATTACH_DIR="attachments"
TMP_ROOT=".tmp_render"

echo "==> Copying attachments into row folders..."

# loop all row folders
find "$TMP_ROOT" -maxdepth 1 -type d -name ".*" | while read -r rowdir; do

    echo "Processing row: $(basename "$rowdir")"

    # skip if no attachments
    [[ -d "$ATTACH_DIR" ]] || continue

    # copy all PDFs into row folder
    find "$ATTACH_DIR" -type f -name "*.pdf" -exec cp -f {} "$rowdir/" \;

done

echo "==> Attachment copy complete"
