#!/usr/bin/env bash
set -Eeuo pipefail

# Tell bash where to find conda
source ~/miniconda3/etc/profile.d/conda.sh

# Make sure env exists
conda activate ngs

source "0_vars.sh"

for (( i = 0; i < NUM_SAMPLES; i++ )); do
  mkdir -p "${OUT}"/strand/"${SAMPLES[i]}"
done

# Align a sample of reads
# sample (reproducible, random selection)
for (( i = 0; i < NUM_SAMPLES; i++ )); do
  seqtk sample -s100 "${READS}"/"${SAMPLES_R1[i]}" 500000 > "${OUT}"/strand/"${SAMPLES[i]}"/R1_500k_sample.fq
  seqtk sample -s100 "${READS}"/"${SAMPLES_R2[i]}" 500000 > "${OUT}"/strand/"${SAMPLES[i]}"/R2_500k_sample.fq
done

# align without assuming strandness
for (( i = 0; i < NUM_SAMPLES; i++ )); do
  hisat2 -p $THREADS -x $HISAT2_IDX \
  -1 "${OUT}"/strand/"${SAMPLES[i]}"/R1_500k_sample.fq \
  -2 "${OUT}"/strand/"${SAMPLES[i]}"/R2_500k_sample.fq \
  -S "${OUT}"/strand/"${SAMPLES[i]}"/sample.sam
done

# convert to sorted BAM
for (( i = 0; i < NUM_SAMPLES; i++ )); do
  samtools view -bS "${OUT}"/strand/"${SAMPLES[i]}"/sample.sam | samtools sort -@"${THREADS}" -m 2G -T "${OUT}"/strand/"${SAMPLES[i]}"/tmp.sort -o "${OUT}"/strand/"${SAMPLES[i]}"/sample.sorted.bam
  samtools index "${OUT}"/strand/"${SAMPLES[i]}"/sample.sorted.bam
done

# Prepare gene annotation in BED format
gtf2bed < "${GENOMIC}"/"${DATASET}".gtf > "${GENOMIC}"/"${DATASET}".bed

# Run infer_experiment.py
for (( i = 0; i < NUM_SAMPLES; i++ )); do
  infer_experiment.py -i "${OUT}"/strand/"${SAMPLES[i]}"/sample.sorted.bam -r "${GENOMIC}"/"${DATASET}".bed > "${GENOMIC}"/"${SAMPLES[i]}"_strandedness.txt
done