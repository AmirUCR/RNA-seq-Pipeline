#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 04_fastqc_again.sh"

while IFS=$'\t' read -r sample_id condition r1 r2; do
    log "Creating directory for ${sample_id}"
    mkdir -p "${OUT_TRIM}/${sample_id}"
done < <(tail -n +2 "${SAMPLES_TSV}")

# ------- FASTQC & multiqc
while IFS=$'\t' read -r sample_id condition r1 r2; do
    log "Running FastQC for ${sample_id}"
    fastqc \
    "${READS_TRIM}"/"${sample_id}_R1.fastq.gz" \
    "${READS_TRIM}"/"${sample_id}_R2.fastq.gz" \
    -o "${OUT_TRIM}"/"${sample_id}" \
    --threads "${THREADS}"
done < <(tail -n +2 "${SAMPLES_TSV}")

log "Running multiqc"
multiqc \
    "${OUT_TRIM}" \
    -o "${OUT_TRIM}" \
    -f \
    --clean-up
    