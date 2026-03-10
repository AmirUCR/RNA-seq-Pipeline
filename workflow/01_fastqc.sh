#!/usr/bin/env bash
set -Eeuo pipefail

# Tell bash where to find conda
source ~/miniconda3/etc/profile.d/conda.sh

# Make sure env exists
conda activate ngs

source "0_vars.sh"

# Create directories
for sample in "${SAMPLES[@]}"; do
    mkdir -p $OUT/"$sample"
done

# ------- FASTQC
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    fastqc \
    "${READS}"/"${SAMPLES_R1[i]}" \
    "${READS}"/"${SAMPLES_R2[i]}" \
    -o "${OUT}"/"${SAMPLES[i]}" \
    -t "${THREADS}" &
done

wait

# ------- MULTIQC
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    multiqc \
    "${OUT}"/"${SAMPLES[i]}" \
    -o "${OUT}"/"${SAMPLES[i]}" \
    -f --clean-up &
done

wait