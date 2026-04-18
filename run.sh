#!/usr/bin/bash

export global_path=$(pwd)
lib_path="lib"

"$lib_path/clear.sh"
"$lib_path/init_templates.sh"
"$lib_path/init_watermark.sh"
"$lib_path/compile_templates.sh"
"$lib_path/init_attachments.sh"
"$lib_path/burn_watermarks.sh"
"$lib_path/merge_pdfs.sh"
"$lib_path/clear.sh"
