#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 09_hisat2.sh"

# Create directory
while IFS=$'\t' read -r sample_id condition r1 r2; do
    mkdir -p "${OUT_TRIM}/${sample_id}"
done < <(tail -n +2 "${SAMPLES_TSV}")

infer_hisat2_strand
log "Detected hisat2 strandedness: ${HISAT2_STRANDEDNESS}"

align() {
  local idx_prefix="$1"
  local r1="$2"
  local r2="$3"
  local tag="$4"
  
  # derive RG fields from tag (…/SAMPLE/trimmed)
  local RGID; RGID="$(basename "${tag}")"
  local RGSM; RGSM="$(basename "$(dirname "${tag}")")"
  local RGLB="${RGSM}.lib1"
  local RGPL="ILLUMINA"
  local RGPU="${RGSM}.unit1"

  # Align -> sort BAM (with @RG)
  hisat2 -p "${THREADS}" --rna-strandness "${HISAT2_STRANDEDNESS}" \
    -x "${idx_prefix}" -1 "${r1}" -2 "${r2}" \
    --rg-id "${RGID}" \
    --rg "SM:${RGSM}" --rg "LB:${RGLB}" --rg "PL:${RGPL}" --rg "PU:${RGPU}" \
    -S "${tag}.sam" 2> "${tag}.hisat2.log"

  samtools view -b "${tag}.sam" | samtools sort -@ "${THREADS}" -o "${tag}.sorted.bam"
  rm -f "${tag}.sam"

  samtools flagstat "${tag}.sorted.bam" > "${tag}.flagstat.txt"
}

# —— Run
while IFS=$'\t' read -r sample_id condition r1 r2; do
  align \
    "${HISAT2_IDX}" \
    "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
    "${READS_TRIM}/${sample_id}_R2.fastq.gz" \
    "${OUT_TRIM}/${sample_id}/trimmed"
done < <(tail -n +2 "${SAMPLES_TSV}")
