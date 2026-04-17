#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="templates"
TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"

awk -v template_dir="$TEMPLATE_DIR" -v root="$TMP_ROOT" '

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
    system("mkdir -p \"" outdir "\"")

    system("cp -r " template_dir "/. " outdir "/")

    cmd = "find " outdir " -type f"
    while ((cmd | getline file) > 0) {

        tmp = file ".tmp"

        while ((getline l < file) > 0) {
            for (k in map) {
                safe = map[k]
                gsub(/\\/, "\\\\", safe)
                gsub(/&/, "\\&", safe)
                gsub("{{" k "}}", safe, l)
            }
            print l > tmp
        }

        close(file)
        close(tmp)

        system("mv " tmp " " file)
    }

    close(cmd)
}

' "$CSV_FILE"
