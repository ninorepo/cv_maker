#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="data.csv"
WATERMARK_TXT_TEMPLATE="watermarks/watermark.txt"
WATERMARK_SVG_TEMPLATE="watermarks/watermark.svg"
TMP_ROOT=".tmp_render"

awk -v wm_file="$WATERMARK_TXT_TEMPLATE" -v root="$TMP_ROOT" '

function trim_quotes(s) {
    sub(/^"/, "", s)
    sub(/"$/, "", s)
    return s
}

function parse_csv(line,   i, ch, field, inq, n) {
    n = 0
    field = ""
    inq = 0
    delete values

    for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)

        if (ch == "\"") {
            inq = !inq
        } else if (ch == "," && !inq) {
            values[++n] = trim_quotes(field)
            field = ""
        } else {
            field = field ch
        }
    }

    values[++n] = trim_quotes(field)
    return n
}

NR == 1 {
    n = parse_csv($0)
    for (i = 1; i <= n; i++) headers[i] = values[i]
    next
}

{
    delete values
    n = parse_csv($0)

    delete map
    for (i = 1; i <= n; i++) {
        map[headers[i]] = values[i]
    }

    row_id = map["id"]
    if (row_id == "") next

    gsub(/[^a-zA-Z0-9_-]/, "", row_id)

    outdir = root "/." row_id

    # ❗ CHECK: directory must already exist
    if (system("[ -d \"" outdir "\" ]") != 0) {
        print "ERROR: directory does not exist: " outdir > "/dev/stderr"
        exit 1
    }

    # load watermark.txt template
    wm_text = ""
    while ((getline l < wm_file) > 0) {
        wm_text = wm_text l "\n"
    }
    close(wm_file)

    # replace {{column}} placeholders in watermark.txt
    for (k in map) {
        safe = map[k]
        gsub(/\\/, "\\\\", safe)
        gsub(/&/, "\\&", safe)
        gsub("{{" k "}}", safe, wm_text)
    }

    # save watermark.txt
    txt_path = outdir "/watermark.txt"
    print wm_text > txt_path
    close(txt_path)

}
' "$CSV_FILE"

# === SVG processing ===

find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name ".*" | while read -r dir; do
    txt="$dir/watermark.txt"
    svg="$dir/watermark.svg"

    # copy svg template
    cp "$WATERMARK_SVG_TEMPLATE" "$svg"

    # read text content
    text=$(cat "$txt")

    # escape for sed
    text_escaped=$(printf '%s\n' "$text" | sed -e 's/[\/&]/\\&/g')

    # replace all {{text}} in svg
    sed -i "s/{{text}}/$text_escaped/g" "$svg"
done

echo "Done."
