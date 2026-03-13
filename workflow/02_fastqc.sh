#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration first.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda and activate env.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 02_fastqc.sh"

# Run FastQC per sample into sample-specific output directories.
while IFS=$'\t' read -r sample_id condition r1 r2; do
    log "Creating directory for ${sample_id}"
    mkdir -p "${OUT}/${sample_id}"

    log "Running FastQC for ${sample_id}"
    fastqc \
        "${READS}/${r1}" \
        "${READS}/${r2}" \
        -o "${OUT}/${sample_id}" \
        -t "${THREADS}"
done < <(iterate_samples)

log "Running multiqc"
multiqc \
    "${OUT}" \
    -o "${OUT}" \
    -f \
    --clean-up
