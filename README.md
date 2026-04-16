CSV → LaTeX → PDF Automation Pipeline

This project is designed to generate Cover Letters and CVs in Bahasa Indonesia in bulk, allowing you to apply to multiple companies at once efficiently.

Using a single CSV file containing company/job data, the system will automatically:

1. Fill LaTeX templates (Cover Letter + CV written in Bahasa Indonesia)
2. Compile them into PDFs
3. Merge them with additional documents (optional)
4. Produce one final PDF per application

---

✨ Features

- ✅ Bulk generation of Cover Letter + CV (Bahasa Indonesia)
- ✅ Header-based placeholders ("{{nama}}", "{{perusahaan}}", etc.)
- ✅ Supports quoted CSV (e.g., ""Jakarta, Indonesia"")
- ✅ Multiple templates per record
- ✅ Automatic LaTeX compilation ("pdflatex")
- ✅ Merge with additional PDFs (portfolio, certificates, etc.)
- ✅ Parallel processing (fast for large datasets)
- ✅ Clean output (no temporary files left)

---

🎯 Main Use Case

Ideal for:

- Applying to many companies at once
- Sending personalized applications
- Maintaining consistent formatting across applications

---

📁 Project Structure

project/
├── generate.sh
├── data.csv
├── template_cover_letter.tex
├── template_cv.tex
├── extra_pdfs/
│   ├── 01_portfolio.pdf
│   ├── 02_certificates.pdf
│   └── 03_appendix.pdf
└── output/

---

📄 CSV Format

- First row must be header
- Headers are used as placeholders in templates

Example:

nama,perusahaan,posisi,alamat
"John Doe","PT Maju Jaya","Software Engineer","Jakarta, Indonesia"
"Alice","PT Teknologi Baru","Data Analyst","Surabaya, Indonesia"

---

🧾 Template Format (Bahasa Indonesia)

Templates should be written in Bahasa Indonesia, for example:

Nama: {{nama}} \\
Melamar ke: {{perusahaan}} \\
Posisi: {{posisi}} \\
Alamat: {{alamat}}

«⚠️ Placeholders are case-sensitive and must match CSV headers»

---

📎 Additional PDFs

All PDFs inside "extra_pdfs/" will be appended to every generated document.

Recommended naming for correct order:

01_portfolio.pdf
02_certificates.pdf
03_appendix.pdf

---

⚙️ Requirements

Install required tools on Debian:

sudo apt install texlive-latex-base poppler-utils

- "pdflatex" → compile LaTeX
- "pdfunite" → merge PDFs

---

▶️ Usage

chmod +x generate.sh
./generate.sh

---

📤 Output

output/
 ├── PT Maju Jaya.pdf
 ├── PT Teknologi Baru.pdf
 └── ...

Each file contains:

Cover Letter (Bahasa Indonesia)
+ CV (Bahasa Indonesia)
+ Additional PDFs

---

⚡ Parallel Processing

You can adjust the number of parallel jobs in the script:

JOBS=4

---

⚠️ Notes

- CSV must be properly formatted (use quotes if fields contain commas)
- Placeholder names must match CSV headers exactly
- Output filenames are based on a selected column (e.g., company name)
- Invalid filename characters are automatically sanitized

---

🧠 Workflow

CSV → Fill Templates → Compile → Merge → Final PDF

---

🚀 Possible Improvements

- LaTeX error detection
- Incremental builds (skip unchanged outputs)
- ZIP export per application
- Email automation integration

---

📜 License

Free to use and modify for personal or academic purposes.
