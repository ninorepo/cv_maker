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
    img2pdf \
    librsvg2-bin \

echo "Checking installations..."

check() {
    command -v "$1" >/dev/null 2>&1 && echo "$1 OK" || echo "$1 MISSING"
}

# LaTeX
check pdflatex

# PDF tools
check pdfunite
check pdftoppm
check img2pdf

# ImageMagick (new + old compatibility)
check magick
check convert
check rsvg-convert

echo "Done."
