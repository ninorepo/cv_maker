#!/bin/bash

set -e

echo "Updating package list..."
sudo apt update

echo "Installing required packages for generate.sh..."

sudo apt install -y \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    poppler-utils \
    imagemagick \
    ghostscript \
    miller \
    coreutils \
    gawk \
    sed \
    findutils

echo "Checking installations..."

# -------------------------
# LaTeX
# -------------------------
command -v pdflatex >/dev/null 2>&1 && echo "pdflatex OK" || echo "pdflatex MISSING"

# -------------------------
# PDF merge
# -------------------------
command -v pdfunite >/dev/null 2>&1 && echo "pdfunite OK" || echo "pdfunite MISSING"

# -------------------------
# CSV tool (mlr)
# -------------------------
command -v mlr >/dev/null 2>&1 && echo "mlr OK" || echo "mlr MISSING"

# -------------------------
# ImageMagick
# -------------------------
command -v convert >/dev/null 2>&1 && echo "ImageMagick OK" || echo "ImageMagick MISSING"

# -------------------------
# PDF raster tool
# -------------------------
command -v pdftoppm >/dev/null 2>&1 && echo "pdftoppm OK" || echo "pdftoppm MISSING"

# -------------------------
# Ghostscript
# -------------------------
command -v gs >/dev/null 2>&1 && echo "ghostscript OK" || echo "ghostscript MISSING"

echo "Done."
