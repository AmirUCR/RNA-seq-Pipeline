#!/usr/bin/env bash
set -Eeuo pipefail

# Tell bash where to find conda
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ngs

source "0_vars.sh"

# Build BAMS from the sample list
BAMS=() 
for s in "${SAMPLES[@]}"; do
    BAMS+=("${OUT_TRIM}/${s}/trimmed.dedup.bam")
done

ALL_OTHER_PARAMETERS=(
    -T "${THREADS}"
    -s 2  # Reversely stranded
    -p
    -B -C -Q 30
    --countReadPairs
)

# One featureCounts run for all BAMs
featureCounts \
    "${ALL_OTHER_PARAMETERS[@]}" \
    -a "${GTF}" \
    -o "${OUT_TRIM}/counts.txt" \
    "${BAMS[@]}"
