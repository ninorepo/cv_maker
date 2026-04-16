#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="templates"
TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"
WATERMARK_FILE="watermarks/watermark.txt"

awk -v template_dir="$TEMPLATE_DIR" \
    -v root="$TMP_ROOT" \
    -v wm_file="$WATERMARK_FILE" '

function trim_quotes(s) {
    sub(/^"/, "", s)
    sub(/"$/, "", s)
    return s
}

function parse_csv(line,   i, ch, field, inq, n) {
    n = 0
    field = ""
    inq = 0

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

function load_file(path,   line, out) {
    out = ""
    while ((getline line < path) > 0) {
        out = out line "\n"
    }
    close(path)
    return out
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
    system("mkdir -p \"" outdir "\"")

    # -------------------------
    # copy templates
    # -------------------------
    system("cp -r " template_dir "/. " outdir "/")

    # -------------------------
    # process templates
    # -------------------------
    cmd = "find " outdir " -type f"
    while ((cmd | getline file) > 0) {

        tmp = file ".tmp"

        while ((getline line < file) > 0) {
            for (k in map) {
                gsub("{{" k "}}", map[k], line)
            }
            print line > tmp
        }

        close(file)
        close(tmp)

        system("mv " tmp " " file)
    }

    # -------------------------
    # BUILD watermark.txt (NEW)
    # -------------------------
    wm_text = load_file(wm_file)

    for (k in map) {
        gsub("{{" k "}}", map[k], wm_text)
    }

    gsub(/\n$/, "", wm_text)

    print wm_text > (outdir "/watermark.txt")
    close(outdir "/watermark.txt")
}
' "$CSV_FILE"
