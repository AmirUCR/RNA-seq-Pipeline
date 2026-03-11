#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

# —— FASTA index + chrom sizes + dict
samtools faidx "${REF}"
cut -f1,2 "${REF}.fai" > "${CHROMSIZES}"

DICT="${GENOMIC}/${DATASET}_Genome.dict"
if [[ ! -s "${DICT}" ]]; then
  picard CreateSequenceDictionary -R "${REF}" -O "${DICT}"
fi
