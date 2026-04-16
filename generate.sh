#!/bin/bash
set -e

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

# =========================
# WATERMARK FUNCTION
# =========================
apply_watermark() {
    input="$1"
    wm="$2"
    output="$3"

    tmpdir=$(mktemp -d)

    pdftoppm "$input" "$tmpdir/page" -png

    for img in "$tmpdir"/page-*.png; do
        convert "$img" "$wm" \
            -gravity center \
            -compose dissolve \
            -define compose:args=25 \
            -composite \
            "$img.wm.png"
    done

    convert "$tmpdir"/*.wm.png "$output"
    rm -rf "$tmpdir"
}

export -f apply_watermark

# =========================
# PROCESS ROW
# =========================
process_row() {
    line="$1"

    awk -v line="$line" \
        -v t1="$TEMPLATE1" \
        -v t2="$TEMPLATE2" \
        -v extra="$EXTRA_PDF_DIR" \
        -v outdir="$OUTPUT_DIR" \
        -v wm_dir="$WATERMARK_DIR" '
    BEGIN {

        # =========================
        # SAFE CSV PARSING (FIX)
        # =========================
        FPAT = "([^,]+)|(\"[^\"]+\")"

        while ((getline header < "'"$INPUT"'") > 0) {
            split(header, h, ",")
            break
        }

        split(line, f, ",")

        for (i = 1; i <= length(h); i++) {
            gsub(/^"|"$/, "", h[i])
            gsub(/^"|"$/, "", f[i])
            data[h[i]] = f[i]
        }

        # =========================
        # FILENAME (UNCHANGED LOGIC)
        # =========================
        name = data[h[1]]
        gsub(/[^a-zA-Z0-9]/, "_", name)

        workdir = outdir "/tmp_" rand()
        system("mkdir -p \"" workdir "\"")

        pdf_list = ""

        templates[1] = t1
        templates[2] = t2

        # =========================
        # TEMPLATE PROCESSING (UNCHANGED)
        # =========================
        for (t in templates) {

            template = templates[t]
            outfile = workdir "/" template

            system("cp \"" template "\" \"" outfile "\"")

            for (k in data) {
                val = data[k]
                gsub(/["\\\/&]/, "\\\\&", val)

                cmd = "sed -i \"s/{{" k "}}/" val "/g\" \"" outfile "\""
                system(cmd)
            }

            cmd = "cd \"" workdir "\" && pdflatex -interaction=nonstopmode \"" template "\" > /dev/null 2>&1"
            system(cmd)

            pdf = template
            sub(/\.tex$/, ".pdf", pdf)

            pdf_list = pdf_list " \"" workdir "/" pdf "\""
        }

        # =========================
        # EXTRA PDFs + WATERMARK (UNCHANGED LOGIC)
        # =========================
        cmd = "ls \"" extra "\"/*.pdf 2>/dev/null | sort -V"

        while ((cmd | getline extra_pdf) > 0) {

            final_pdf = extra_pdf

            if (extra_pdf ~ /\.wm\.pdf$/) {

                wm_img = wm_dir "/default.png"
                wm_out = workdir "/wm_" rand() ".pdf"

                apply_cmd = "bash -c 'apply_watermark \"" extra_pdf "\" \"" wm_img "\" \"" wm_out "\"'"
                system(apply_cmd)

                final_pdf = wm_out
            }

            pdf_list = pdf_list " \"" final_pdf "\""
        }

        close(cmd)

        # =========================
        # OUTPUT
        # =========================
        final = outdir "/" name ".pdf"

        print "Generating: " final

        system("pdfunite " pdf_list " \"" final "\"")

        system("rm -rf \"" workdir "\"")
    }'
}

# =========================
# MAIN LOOP (UNCHANGED)
# =========================
tail -n +2 "$INPUT" | while IFS= read -r line; do
    process_row "$line"
done
