#!/usr/bin/env bash
set -Eeuo pipefail

source "0_vars.sh"

# Zip up the genome files and indices for IGV
zip -j "${DATASET}.zip" \
    "${GENOMIC}/${DATASET}_Genome.fasta" \
    "${GENOMIC}/${DATASET}_Genome.fasta.fai" \
    "${GENOMIC}/${DATASET}.gtf" \
    "${GENOMIC}/${DATASET}.gff" \
    "${GENOMIC}/${DATASET}_Genome.dict"

# Zip up all the .bw bigwig files in SAMPLES for IGV
tmp=$(mktemp -d)
shopt -s nullglob

for s in "${SAMPLES[@]}"; do
  for f in "${OUT_TRIM}/${s}"/*.sorted.bw; do
    ln -s "$f" "${tmp}/${s}_$(basename "$f")"
  done

  for f in "${OUT_TRIM}/${s}"/*.dedup.bw; do
    ln -s "$f" "${tmp}/${s}_$(basename "$f")"
  done
done

(
  cd "${tmp}" || exit
  zip -9 "${OLDPWD}/trimmed_aligned_bigwig.zip" *.bw
)
rm -rf "${tmp}"
