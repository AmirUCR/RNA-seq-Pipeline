#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 12_make_bw.sh"

# Coverage tracks (dedup + raw)
make_bw () {
  local bam=$1
  local bed=$2
  local bw=$3

  # keep mapped, primary, non-supplementary; drop low MAPQ; honor splicing
  samtools view -b -F 2308 -q 10 "${bam}" \
  | bedtools genomecov -bg -split -ibam - \
  | LC_ALL=C sort -k1,1 -k2,2n \
  > "${bed}"
  bedGraphToBigWig "${bed}" "${CHROMSIZES}" "${bw}"
}

while IFS=$'\t' read -r sample_id condition r1 r2; do
  make_bw \
    "${OUT_TRIM}/${sample_id}/trimmed.dedup.bam" \
    "${OUT_TRIM}/${sample_id}/trimmed.dedup.bedgraph" \
    "${OUT_TRIM}/${sample_id}/trimmed.dedup.bw"

  make_bw \
    "${OUT_TRIM}/${sample_id}/trimmed.sorted.bam" \
    "${OUT_TRIM}/${sample_id}/trimmed.sorted.bedgraph" \
    "${OUT_TRIM}/${sample_id}/trimmed.sorted.bw"
done < <(tail -n +2 "${SAMPLES_TSV}")
