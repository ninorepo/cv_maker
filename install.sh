#!/bin/bash

set -e

echo "Updating package list..."
sudo apt update

echo "Installing required packages..."
sudo apt install -y \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    poppler-utils \
    coreutils \
    gawk \
    sed \
    findutils

echo "Checking installations..."

# Check pdflatex
if command -v pdflatex >/dev/null 2>&1; then
    echo "pdflatex installed"
else
    echo "pdflatex NOT found"
fi

# Check pdfunite
if command -v pdfunite >/dev/null 2>&1; then
    echo "pdfunite installed"
else
    echo "pdfunite NOT found"
fi

echo "Done."
