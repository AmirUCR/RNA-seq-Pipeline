#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration first.
source "${SCRIPT_DIR}/00_vars.sh"

# Tell bash where to find conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"

# Activate analysis environment.
conda activate "${ENV}"

# Run FastQC per sample into sample-specific output directories.
while IFS=$'\t' read -r sample_id condition r1 r2; do
    mkdir -p "${OUT}/${sample_id}"

    echo "Running FastQC for ${sample_id}"

    fastqc \
        "${READS}/${r1}" \
        "${READS}/${r2}" \
        -o "${OUT}/${sample_id}" \
        -t "${THREADS}"
done < <(tail -n +2 "${SAMPLES_TSV}")

# Aggregate each sample directory with MultiQC.
while IFS=$'\t' read -r sample_id condition r1 r2; do
    echo "Running MultiQC for ${sample_id}"

    multiqc \
        "${OUT}/${sample_id}" \
        -o "${OUT}/${sample_id}" \
        -f \
        --clean-up
done < <(tail -n +2 "${SAMPLES_TSV}")
