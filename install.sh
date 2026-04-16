#!/bin/bash

set -e

echo "Updating package list..."
sudo apt update

echo "Installing required packages..."

sudo apt install -y \
    texlive-latex-recommended \
    texlive-latex-extra \
    poppler-utils \
    imagemagick \
    ghostscript

echo "Checking installations..."

command -v pdflatex >/dev/null 2>&1 && echo "pdflatex installed" || echo "pdflatex NOT found"
command -v pdfunite >/dev/null 2>&1 && echo "pdfunite installed" || echo "pdfunite NOT found"

echo "Done."
