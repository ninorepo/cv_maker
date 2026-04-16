#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="templates"
TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"

# Clean previous run
rm -rf "$TMP_ROOT"
mkdir -p "$TMP_ROOT"

awk -v template_dir="$TEMPLATE_DIR" -v root="$TMP_ROOT" '
function trim_quotes(s) {
    sub(/^"/, "", s)
    sub(/"$/, "", s)
    return s
}

# Basic CSV parser (supports quoted values, no multiline support)
function parse_csv(line,   i, c, field, inq, n, ch) {
    n = 0
    field = ""
    inq = 0

    for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)

        if (ch == "\"" ) {
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
    # headers
    n = parse_csv($0)
    for (i = 1; i <= n; i++) {
        headers[i] = values[i]
    }

    # validate id exists
    has_id = 0
    for (i = 1; i <= n; i++) {
        if (headers[i] == "id") has_id = 1
    }

    if (!has_id) {
        print "ERROR: missing required column 'id'" > "/dev/stderr"
        exit 1
    }

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

    if (row_id == "") {
        print "ERROR: empty id field" > "/dev/stderr"
        next
    }

    # sanitize id (VERY IMPORTANT)
    gsub(/[^a-zA-Z0-9_-]/, "", row_id)

    outdir = root "/." row_id
    system("mkdir -p \"" outdir "\"")

    # copy templates (including hidden files)
    system("cp -r " template_dir "/. " outdir "/")

    # process all files
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
}
' "$CSV_FILE"
