#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 11_fasta_index.sh"

# —— FASTA index + chrom sizes + dict
samtools faidx "${REF}"
cut -f1,2 "${REF}.fai" > "${CHROMSIZES}"

DICT="${GENOMIC}/${DATASET}_Genome.dict"
if [[ ! -s "${DICT}" ]]; then
  picard CreateSequenceDictionary -R "${REF}" -O "${DICT}"
fi
