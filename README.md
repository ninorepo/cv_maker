# CSV to LaTeX to PDF Automation Pipeline

This project generates Cover Letters and CVs in Bahasa Indonesia in bulk,
allowing you to apply to multiple companies efficiently.

Using a single CSV file, the pipeline will:
1. Fill LaTeX templates (Cover Letter and CV in Bahasa Indonesia)
2. Compile them into PDFs using pdflatex
3. Merge them with additional PDF documents (optional)
4. Output one final PDF per application

------------------------------------------------------------

FEATURES

- Bulk generation of Cover Letter and CV (Bahasa Indonesia)
- Header-based placeholders ({{nama}}, {{perusahaan}}, etc.)
- Supports quoted CSV (e.g., "Jakarta, Indonesia")
- Multiple templates per record
- Automatic LaTeX compilation
- Merge with additional PDFs (portfolio, certificates, etc.)
- Parallel processing
- Clean output (no temporary files left)

------------------------------------------------------------

MAIN USE CASE

- Apply to many companies at once
- Send personalized applications
- Keep consistent document formatting

------------------------------------------------------------

PROJECT STRUCTURE

project/
|-- generate.sh
|-- data.csv
|-- templates/
|   |-- cover_letter.tex
|   \-- cv.tex
|-- extra_pdfs/
|   |-- 01_portfolio.pdf
|   |-- 02_certificates.pdf
|   \-- 03_appendix.pdf
\-- output/

------------------------------------------------------------

CSV FORMAT

- First row must be a header
- Headers are used as placeholders in templates

Example:

nama,perusahaan,posisi,alamat
"John Doe","PT Maju Jaya","Software Engineer","Jakarta, Indonesia"
"Alice","PT Teknologi Baru","Data Analyst","Surabaya, Indonesia"

------------------------------------------------------------

TEMPLATE FORMAT (Bahasa Indonesia)

Templates must be written in Bahasa Indonesia.

Example:

\documentclass{article}
\begin{document}

Nama: {{nama}} \\
Melamar ke: {{perusahaan}} \\
Posisi: {{posisi}} \\
Alamat: {{alamat}}

\end{document}

Note:
- Placeholders are case-sensitive
- Must match CSV headers exactly

------------------------------------------------------------

ADDITIONAL PDF FILES

All PDFs inside extra_pdfs/ will be appended to every generated document.

Recommended naming:

01_portfolio.pdf
02_certificates.pdf
03_appendix.pdf

------------------------------------------------------------

REQUIREMENTS

Install dependencies on Debian:

sudo apt install texlive-latex-base poppler-utils

Tools used:
- pdflatex  (LaTeX compiler)
- pdfunite  (PDF merge tool)

------------------------------------------------------------

USAGE

chmod +x generate.sh
./generate.sh

------------------------------------------------------------

OUTPUT

output/
|-- PT Maju Jaya.pdf
|-- PT Teknologi Baru.pdf
`-- ...

Each file contains:
- Cover Letter (Bahasa Indonesia)
- CV (Bahasa Indonesia)
- Additional PDFs

------------------------------------------------------------

PARALLEL PROCESSING

You can adjust the number of jobs in generate.sh:

JOBS=4

Recommended:
- Set equal to number of CPU cores

------------------------------------------------------------

NOTES

- CSV must be properly formatted
- Use quotes if fields contain commas
- Output filenames are based on selected column
- Invalid filename characters are sanitized automatically

------------------------------------------------------------

WORKFLOW

CSV -> Fill Templates -> Compile -> Merge -> Final PDF

------------------------------------------------------------

LICENSE

Free to use and modify for personal or academic purposes.
