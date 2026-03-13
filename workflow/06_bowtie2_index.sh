#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 06_bowtie2_index.sh"

while IFS=$'\t' read -r shorthand path_in_genomic; do
    log "Creating directory for ${shorthand}"
    mkdir -p "${BOWTIE2_IDX}/${shorthand}"

    log "Running bowtie-build for ${shorthand}"
    if [[ ! -f "${GENOMIC}/${path_in_genomic}" ]]; then
        log "Missing genomic file: ${GENOMIC}/${path_in_genomic}" >&2
        exit 1
    fi

    bowtie2-build \
        "${GENOMIC}/${path_in_genomic}" \
        "${BOWTIE2_IDX}/${shorthand}/${shorthand}" \
        --threads "${THREADS}"
done < <(tail -n +2 "${BACKGROUND_TSV}")
