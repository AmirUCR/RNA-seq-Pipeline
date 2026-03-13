#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 07_fastp_screen.sh"

mkdir -p "${CONTAM_OUT}"

log "Creating FastQ Screen config at ${FASTQ_SCREEN_CONFIG}"

{
    echo "# where bowtie2 lives"
    echo "BOWTIE2        ${BOWTIE2_PATH}"
    echo ""

    echo "# add a touch more sensitivity + unique hits"
    echo "BOWTIE2_OPTIONS --very-sensitive"
    echo ""

    echo "# Databases (name then index prefix)"
    while IFS=$'\t' read -r shorthand path_in_genomic; do
        idx="${BOWTIE2_IDX}/${shorthand}/${shorthand}"

        if [[ ! -f "${idx}.1.bt2" ]]; then
            log "Warning: bowtie2 index for ${shorthand} not found: ${idx}" >&2
        fi

        echo "DATABASE       ${shorthand}      ${idx}"
    done < <(tail -n +2 "${BACKGROUND_TSV}")
} > "${FASTQ_SCREEN_CONFIG}"

while IFS=$'\t' read -r sample_id condition r1 r2; do
    log "Running FastQ Screen for ${sample_id}"

    fastq_screen \
        --aligner bowtie2 \
        --subset 200000 \
        --threads "${THREADS}" \
        --conf "${FASTQ_SCREEN_CONFIG}" \
        --outdir "${CONTAM_OUT}" \
        "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
        "${READS_TRIM}/${sample_id}_R2.fastq.gz"

done < <(tail -n +2 "${SAMPLES_TSV}")