#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

mkdir -p ${BOWTIE2_IDX}/pberghei
mkdir -p ${BOWTIE2_IDX}/hst2t
mkdir -p ${BOWTIE2_IDX}/phix
mkdir -p ${BOWTIE2_IDX}/mmusculus

# bowtie2-build "${GENOMIC}/human/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna.gz" ${BOWTIE2_IDX}/hst2t/hst2t --threads "${THREADS}"
bowtie2-build "${GENOMIC}/mmusculus/GCF_000001635.27_GRCm39_genomic.fna.gz" ${BOWTIE2_IDX}/mmusculus/mmusculus --threads "${THREADS}"
# bowtie2-build "${GENOMIC}/phix/genome.fa" ${BOWTIE2_IDX}/phix/phix --threads "${THREADS}"
# bowtie2-build "${REF}" ${BOWTIE2_IDX}/pberghei/pberghei --threads "${THREADS}"
