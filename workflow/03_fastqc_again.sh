#!/usr/bin/env bash
set -Eeuo pipefail

# Tell bash where to find conda
source ~/miniconda3/etc/profile.d/conda.sh

# Make sure env exists
conda activate ngs

source "0_vars.sh"

# Create directory
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    mkdir -p "${OUT_TRIM}/${SAMPLES[i]}"
done

# ------- FASTQC
# Uncomment and run these instead to run in parallel
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    fastqc \
    "${READS_TRIM}"/"${SAMPLES_R1[i]}" \
    "${READS_TRIM}"/"${SAMPLES_R2[i]}" \
    -o "${OUT_TRIM}"/"${SAMPLES[i]}" \
    --threads "${THREADS}" &
done

# Wait for all FastQC jobs to complete
wait

# ------- MULTIQC
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    multiqc \
    "${OUT_TRIM}"/"${SAMPLES[i]}" \
    -o "${OUT_TRIM}"/"${SAMPLES[i]}" \
    -f --clean-up &
done

wait