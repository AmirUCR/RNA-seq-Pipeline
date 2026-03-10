#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

# —— Coverage tracks (dedup + raw), with proper RNA-seq handling
make_bw () {
  local bam=$1 bed=$2 bw=$3
  # keep mapped, primary, non-supplementary; drop low MAPQ; honor splicing
  samtools view -b -F 2308 -q 10 "${bam}" \
  | bedtools genomecov -bg -split -ibam - \
  | LC_ALL=C sort -k1,1 -k2,2n \
  > "${bed}"
  bedGraphToBigWig "${bed}" "${CHROMSIZES}" "${bw}"
}

for s in "${SAMPLES[@]}"; do
  make_bw \
    "${OUT_TRIM}/${s}/trimmed.dedup.bam" \
    "${OUT_TRIM}/${s}/trimmed.dedup.bedgraph" \
    "${OUT_TRIM}/${s}/trimmed.dedup.bw"

  make_bw \
    "${OUT_TRIM}/${s}/trimmed.sorted.bam" \
    "${OUT_TRIM}/${s}/trimmed.sorted.bedgraph" \
    "${OUT_TRIM}/${s}/trimmed.sorted.bw"
done
