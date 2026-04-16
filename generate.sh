#!/bin/bash

INPUT="data.csv"
TEMPLATE1="templates/template_cover_letter.tex"
TEMPLATE2="templates/template_cv.tex"

EXTRA_PDF_DIR="extra_pdfs"
OUTPUT_DIR="output"

# Number of parallel jobs (adjust to CPU)
JOBS=4

mkdir -p "$OUTPUT_DIR"

process_row() {
    line="$1"

    # Read header separately
    IFS=',' read -r -a headers <<< "$HEADER"

    # Parse CSV line safely using awk
    awk -v line="$line" -v headers="$HEADER" \
        -v t1="$TEMPLATE1" -v t2="$TEMPLATE2" \
        -v extra="$EXTRA_PDF_DIR" -v outdir="$OUTPUT_DIR" '
    BEGIN {
        FPAT = "([^,]+)|(\"[^\"]+\")"

        # Split header
        n = split(headers, h, ",")
    }

    {
        # Parse current line
        $0 = line

        for (i = 1; i <= NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^"|"$/, "", h[i])
        }

        # Build key-value map
        for (i = 1; i <= NF; i++) {
            key = h[i]
            val = $i
            data[key] = val
        }

        name = data[h[1]]  # use first column as filename
        gsub(/[\/:*?"<>|]/, "_", name)

        workdir = outdir "/tmp_" rand()
        system("mkdir -p \"" workdir "\"")

        split(t1 " " t2, templates, " ")

        pdf_list = ""

        for (t in templates) {
            template = templates[t]
            outfile = workdir "/" template

            system("cp \"" template "\" \"" outfile "\"")

            # Replace {{header}} placeholders
            for (k in data) {
                val = data[k]
                gsub(/["\\\/&]/, "\\\\&", val)

                cmd = "sed -i \"s/{{" k "}}/" val "/g\" \"" outfile "\""
                system(cmd)
            }

            # Compile LaTeX
            cmd = "cd \"" workdir "\" && pdflatex -interaction=nonstopmode \"" template "\" > /dev/null 2>&1"
            system(cmd)
            system(cmd)

            pdf = template
            sub(/\.tex$/, ".pdf", pdf)
            pdf_list = pdf_list " \"" workdir "/" pdf "\""
        }

        # Add extra PDFs sorted
        cmd = "ls \"" extra "\"/*.pdf 2>/dev/null | sort -V"
        while ((cmd | getline extra_pdf) > 0) {
            pdf_list = pdf_list " \"" extra_pdf "\""
        }
        close(cmd)

        final_pdf = outdir "/" name ".pdf"
        cmd = "pdfunite " pdf_list " \"" final_pdf "\""
        system(cmd)

        system("rm -rf \"" workdir "\"")
    }'
}

export -f process_row
export TEMPLATE1 TEMPLATE2 EXTRA_PDF_DIR OUTPUT_DIR

# Extract header
HEADER=$(head -n 1 "$INPUT")

# Process rows in parallel
tail -n +2 "$INPUT" | xargs -I{} -P "$JOBS" bash -c 'process_row "$@"' _ {}
