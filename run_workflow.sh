#!/usr/bin/env bash
set -Eeuo pipefail

bash workflow/02_fastqc.sh
bash workflow/03_trimming.sh
bash workflow/04_fastqc_again.sh
bash workflow/05_hisat2_index.sh
bash workflow/06_bowtie2_index.sh # OPTIONAL - Can comment out to skip background screen
bash workflow/07_fastp_screen.sh  # OPTIONAL - Can comment out to skip background screen
bash workflow/08_find_rna_strand.sh
bash workflow/09_hisat2.sh
bash workflow/10_dedup.sh
bash workflow/11_fasta_index.sh
bash workflow/12_make_bw.sh
bash workflow/13_compress_for_igv.sh
bash workflow/14_featurecounts.sh
Rscript workflow/15_parse_featurecounts.r
Rscript workflow/16_deseq2.r
Rscript workflow/17_edger.r
Rscript workflow/18_create_heatmap_edger.r
python workflow/19_volcano.py
