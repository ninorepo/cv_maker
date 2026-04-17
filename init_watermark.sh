#!/usr/bin/env bash
set -euo pipefail

TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"
WATERMARK_FILE="watermarks/watermark.txt"

awk -v root="$TMP_ROOT" -v wm_file="$WATERMARK_FILE" '

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

    wm_text = ""
    while ((getline l < wm_file) > 0) {
        wm_text = wm_text l "\n"
    }
    close(wm_file)

    for (k in map) {
        safe = map[k]
        gsub(/\\/, "\\\\", safe)
        gsub(/&/, "\\&", safe)
        gsub("{{" k "}}", safe, wm_text)
    }

    print wm_text > (outdir "/watermark.txt")
    close(outdir "/watermark.txt")
}

' "$CSV_FILE"
