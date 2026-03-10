#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

# Create directory
for (( i = 0; i < NUM_SAMPLES; i++ )); do
    mkdir -p "${OUT_TRIM}/${SAMPLES[i]}"
done

align() {
  local idx_prefix=$1 r1=$2 r2=$3 tag=$4

  # derive RG fields from tag (…/SAMPLE/trimmed)
  local RGID; RGID="$(basename "${tag}")"
  local RGSM; RGSM="$(basename "$(dirname "${tag}")")"
  local RGLB="${RGSM}.lib1"
  local RGPL="ILLUMINA"
  local RGPU="${RGSM}.unit1"

  # Align -> sort BAM (with @RG)
  hisat2 -p "${THREADS}" --rna-strandness "${RNA_STRAND}" \
    -x "${idx_prefix}" -1 "${r1}" -2 "${r2}" \
    --rg-id "${RGID}" \
    --rg "SM:${RGSM}" --rg "LB:${RGLB}" --rg "PL:${RGPL}" --rg "PU:${RGPU}" \
    -S "${tag}.sam" 2> "${tag}.hisat2.log"

  samtools view -b "${tag}.sam" | samtools sort -@ "${THREADS}" -o "${tag}.sorted.bam"
  rm -f "${tag}.sam"

  samtools flagstat "${tag}.sorted.bam" > "${tag}.flagstat.txt"
}

# —— Run
for (( i = 0; i < NUM_SAMPLES; i++ )); do
  align "${HISAT2_IDX}" "${READS_TRIM}/${SAMPLES_R1[i]}" "${READS_TRIM}/${SAMPLES_R2[i]}" "${OUT_TRIM}/${SAMPLES[i]}/trimmed"
done
