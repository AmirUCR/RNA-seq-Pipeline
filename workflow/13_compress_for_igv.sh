#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 13_compress_for_igv.sh"

mkdir -p "${OUT_DIR}"

rm -f "${IGV_GENOME_ZIP}" "${IGV_BW_ZIP}"

# Zip genome resources for IGV.
zip -j "${IGV_GENOME_ZIP}" \
    "${GENOMIC}/${DATASET}_Genome.fasta" \
    "${GENOMIC}/${DATASET}_Genome.fasta.fai" \
    "${GENOMIC}/${DATASET}.gtf" \
    "${GENOMIC}/${DATASET}.gff" \
    "${GENOMIC}/${DATASET}_Genome.dict"

# Collect BigWig files with clean sample-prefixed names.
tmp="$(mktemp -d)"
shopt -s nullglob

while IFS=$'\t' read -r sample_id condition r1 r2; do
    for f in "${OUT_TRIM}/${sample_id}"/*.sorted.bw; do
        ln -s "${f}" "${tmp}/${sample_id}_$(basename "${f}")"
    done

    for f in "${OUT_TRIM}/${sample_id}"/*.dedup.bw; do
        ln -s "${f}" "${tmp}/${sample_id}_$(basename "${f}")"
    done
done < <(tail -n +2 "${SAMPLES_TSV}")

bw_files=("${tmp}"/*.bw)

if (( ${#bw_files[@]} > 0 )); then
    (
        cd "${tmp}" || exit 1
        zip -9 "${IGV_BW_ZIP}" *.bw
    )
else
    echo "No BigWig files found under ${OUT_TRIM}"
fi

rm -rf "${tmp}"
