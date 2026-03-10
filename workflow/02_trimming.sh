#!/usr/bin/env bash
set -Eeuo pipefail

# Tell bash where to find conda
source ~/miniconda3/etc/profile.d/conda.sh

# Make sure env exists
conda activate ngs

source "0_vars.sh"

# Create directory
mkdir -p "${READS_TRIM}"

# ------- FASTP
ALL_OTHER_PARAMETERS=(
  # --adapter_fasta "$ADAPT" # adapter trim is enabled by default
  --length_required 25
  --cut_tail
  --cut_window_size 6
  --cut_mean_quality 26
  --trim_tail1 40  # The last bases
  --trim_tail2 40
  --trim_front1 13  # Remove the wobbling GC-content seen in FASTQC
  --trim_front2 13  
  --trim_poly_x
  --poly_x_min_len 10
  --thread "$THREADS"
)

for (( i = 0; i < NUM_SAMPLES; i++ )); do
  fastp \
  -i "${READS}"/"${SAMPLES_R1[i]}" \
  -I "${READS}"/"${SAMPLES_R2[i]}" \
  -o "${READS_TRIM}"/"${SAMPLES_R1[i]}" \
  -O "${READS_TRIM}"/"${SAMPLES_R2[i]}" \
  --html "${READS_TRIM}"/fastp_report_"${SAMPLES[i]}".html \
  "${ALL_OTHER_PARAMETERS[@]}" &
done

wait
