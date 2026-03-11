#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

CONTAM="${OUT_DIR}/contamination"
mkdir -p "${CONTAM}"

for (( i = 0; i < NUM_SAMPLES; i++ )); do
  fastq_screen \
  --aligner bowtie2 \
  --subset 200000 \
  --threads "${THREADS}" \
  --conf fastq_screen.conf  \
  --outdir "${CONTAM}" \
  "${READS}/${SAMPLES_R1[i]}" "${READS}/${SAMPLES_R2[i]}"
done
