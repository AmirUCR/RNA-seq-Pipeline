#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 08_find_rna_strand.sh"

while IFS=$'\t' read -r sample_id condition r1 r2; do
  log "Creating ${STRAND_DIR}/${sample_id}"
  mkdir -p "${STRAND_DIR}/${sample_id}"
done < <(tail -n +2 "${SAMPLES_TSV}")

# Prepare gene annotation in BED format
log "Creating ${GENOMIC}/${DATASET}.bed"
gtf2bed < "${GTF}" > "${GENOMIC}/${DATASET}.bed"

# Align a sample of reads
# sample (reproducible, random selection)
while IFS=$'\t' read -r sample_id condition r1 r2; do
  seqtk sample -s100 "${READS_TRIM}/${sample_id}_R1.fastq.gz" 500000 > \
    "${STRAND_DIR}/${sample_id}/R1_500k_sample.fq"
  seqtk sample -s100 "${READS_TRIM}/${sample_id}_R2.fastq.gz" 500000 > \
    "${STRAND_DIR}/${sample_id}/R2_500k_sample.fq"

  hisat2 -p "${THREADS}" -x "${HISAT2_IDX}" \
  -1 "${STRAND_DIR}/${sample_id}/R1_500k_sample.fq" \
  -2 "${STRAND_DIR}/${sample_id}/R2_500k_sample.fq" \
  -S "${STRAND_DIR}/${sample_id}/sample.sam"

  rm -f "${STRAND_DIR}/${sample_id}/R1_500k_sample.fq"
  rm -f "${STRAND_DIR}/${sample_id}/R2_500k_sample.fq"

  samtools \
    view -bS "${STRAND_DIR}/${sample_id}/sample.sam" | \
    samtools sort -@ "${THREADS}" -m 2G -T "${STRAND_DIR}/${sample_id}/tmp.sort" \
      -o "${STRAND_DIR}/${sample_id}/sample.sorted.bam"
  
  rm -f "${STRAND_DIR}/${sample_id}/sample.sam"
  
  samtools index "${STRAND_DIR}/${sample_id}/sample.sorted.bam"

  # Run infer_experiment.py
  log "Running infer_experiment"

  infer_experiment.py \
    -i "${STRAND_DIR}/${sample_id}/sample.sorted.bam" \
    -r "${GENOMIC}/${DATASET}.bed" > "${STRAND_DIR}/${sample_id}/${sample_id}_strandedness.txt"

  rm -f "${STRAND_DIR}/${sample_id}/sample.sorted.bam" \
        "${STRAND_DIR}/${sample_id}/sample.sorted.bam.bai"
done < <(tail -n +2 "${SAMPLES_TSV}")
