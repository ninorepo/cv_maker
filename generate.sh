#!/bin/bash

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
WATERMARK_DIR="watermark"
OUTPUT_DIR="output"

JOBS=4

mkdir -p "$OUTPUT_DIR"

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

process_row() {
    line="$1"

    awk -v line="$line" -v headers="$HEADER" \
        -v t1="$TEMPLATE1" -v t2="$TEMPLATE2" \
        -v extra="$EXTRA_PDF_DIR" -v outdir="$OUTPUT_DIR" \
        -v wm_dir="$WATERMARK_DIR" '
    BEGIN {
        FPAT = "([^,]+)|(\"[^\"]+\")"
        n = split(headers, h, ",")
    }

    {
        $0 = line

        for (i = 1; i <= NF; i++) {
            gsub(/^"|"$/, "", $i)
        }

        for (i = 1; i <= NF; i++) {
            key = h[i]
            val = $i
            data[key] = val
        }

        name = data[h[1]]
        gsub(/[\/:*?"<>|]/, "_", name)

        workdir = outdir "/tmp_" rand()
        system("mkdir -p \"" workdir "\"")

        split(t1 " " t2, templates, " ")

        pdf_list = ""

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

            system("cd \"" workdir "\" && pdflatex -interaction=nonstopmode \"" template "\" > /dev/null 2>&1")

            pdf = template
            sub(/\.tex$/, ".pdf", pdf)

            pdf_list = pdf_list " \"" workdir "/" pdf "\""
        }

        # =========================
        # EXTRA PDF HANDLING
        # =========================
        cmd = "ls \"" extra "\"/*.pdf 2>/dev/null | sort -V"

        while ((cmd | getline extra_pdf) > 0) {

            final_extra = extra_pdf

            # detect watermark suffix
            if (extra_pdf ~ /\.wm\.pdf$/) {

                base = extra_pdf
                sub(/\.wm\.pdf$/, ".pdf", base)

                wm_img = wm_dir "/default.png"

                wm_out = workdir "/wm_" rand() ".pdf"

                cmd2 = "bash -c '\''apply_watermark \"" extra_pdf "\" \"" wm_img "\" \"" wm_out "\"'\''"
                system(cmd2)

                final_extra = wm_out
            }

            pdf_list = pdf_list " \"" final_extra "\""
        }

        close(cmd)

        final_pdf = outdir "/" name ".pdf"

        cmd = "pdfunite " pdf_list " \"" final_pdf "\""
        system(cmd)

        system("rm -rf \"" workdir "\"")
    }'
}

export -f process_row apply_watermark
export TEMPLATE1 TEMPLATE2 EXTRA_PDF_DIR OUTPUT_DIR WATERMARK_DIR

HEADER=$(head -n 1 "$INPUT")

tail -n +2 "$INPUT" | xargs -I{} -P "$JOBS" bash -c 'process_row "$@"' _ {}
