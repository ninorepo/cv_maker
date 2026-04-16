#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="templates"
WATERMARK_FILE="watermarks/watermark.txt"
TMP_ROOT=".tmp_render"
CSV_FILE="data.csv"

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

NR == 1 {
    n = parse_csv($0)
    for (i = 1; i <= n; i++) headers[i] = values[i]

    has_id = 0
    for (i = 1; i <= n; i++) {
        if (headers[i] == "id") has_id = 1
    }

    if (!has_id) {
        print "ERROR: missing required column id" > "/dev/stderr"
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

    gsub(/[^a-zA-Z0-9_-]/, "", row_id)

    outdir = root "/." row_id
    system("mkdir -p \"" outdir "\"")

    # --------------------------------------------------
    # 1. Copy templates
    # --------------------------------------------------
    system("cp -r " template_dir "/. " outdir "/")

    # --------------------------------------------------
    # 2. Replace template placeholders
    # --------------------------------------------------
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

    # --------------------------------------------------
    # 3. BUILD TILED WATERMARK (NEW FEATURE)
    # --------------------------------------------------

    wm_text = ""
    while ((getline l < wm_file) > 0) {
        wm_text = wm_text l "\n"
    }
    close(wm_file)

    for (k in map) {
        gsub("{{" k "}}", map[k], wm_text)
    }
    gsub(/\n$/, "", wm_text)

    tile_path = outdir "/_wm_tile.png"
    wm_path   = outdir "/_watermark.png"

    # small rotated tile
    cmd_tile =
        "convert -size 600x300 xc:none " \
        "-gravity center " \
        "-fill 'rgba(128,128,128,0.15)' " \
        "-font DejaVu-Sans-Bold " \
        "-pointsize 40 " \
        "-annotate 45 \"" wm_text "\" " \
        tile_path

    system(cmd_tile)

    # tile across A4 page
    cmd_fill =
        "convert -size 2480x3508 tile:" tile_path " " wm_path

    system(cmd_fill)
}
' "$CSV_FILE"
