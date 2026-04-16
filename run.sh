#!/usr/bin/bash

./clear.sh
./init_templates_watermark.sh
./compile_templates.sh
./build_watermark.sh
./init_attachments.sh
./burn_watermarks.sh
./merge_pdfs.sh
./clear.sh
