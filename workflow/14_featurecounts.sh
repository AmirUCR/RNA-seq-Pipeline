#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 14_featurecounts.sh"

mkdir -p "${OUT_TRIM}"

# Build BAMS from the sample list
BAMS=() 
while IFS=$'\t' read -r sample_id condition r1 r2; do
    BAMS+=("${OUT_TRIM}/${sample_id}/trimmed.dedup.bam")
done < <(tail -n +2 "${SAMPLES_TSV}")

infer_featurecounts_strand
log "Detected featureCounts strandedness: ${FEATURE_COUNTS_STRANDEDNESS}"

FEATURECOUNTS_ARGS=(
    -T "${THREADS}"
    -s "${FEATURE_COUNTS_STRANDEDNESS}"  # Reversely stranded?
    -p
    -B -C -Q 30
    --countReadPairs
)

# One featureCounts run for all BAMs
featureCounts \
    "${FEATURECOUNTS_ARGS[@]}" \
    -a "${GTF}" \
    -o "${OUT_TRIM}/counts.txt" \
    "${BAMS[@]}"
