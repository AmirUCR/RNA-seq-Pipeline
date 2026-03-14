#!/usr/bin/env bash

# Central configuration for the RNA-seq workflow.
# This file is meant to be sourced by the other workflow scripts:
#
#   source "$(dirname "$0")/00_vars.sh"
#
# Note:
# - Paths are resolved relative to this file, not the caller's current directory.

readonly WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd "${WORKFLOW_DIR}/.." && pwd)"
readonly BOWTIE2_PATH="$(command -v bowtie2)"

readonly DIR="${PROJECT_DIR}/example_data"

readonly THREADS=64
readonly ENV="rnaseq"
readonly DATASET="PlasmoDB-36_PbergheiANKA"

readonly READS_DIR="${EXAMPLE_DIR}/reads"
readonly READS="${READS_DIR}/untrimmed"
readonly READS_TRIM="${READS_DIR}/trimmed"

readonly OUT_DIR="${PROJECT_DIR}/results"
readonly OUT="${OUT_DIR}/untrimmed"
readonly OUT_TRIM="${OUT_DIR}/trimmed"
readonly CONTAM_OUT="${OUT_DIR}/contamination"
readonly FASTQ_SCREEN_CONFIG="${CONTAM_OUT}/fastq_screen.conf"
readonly STRAND_DIR="${OUT_TRIM}/strand"
readonly IGV_GENOME_ZIP="${OUT_DIR}/${DATASET}.zip"
readonly IGV_BW_ZIP="${OUT_DIR}/trimmed_aligned_bigwig.zip"

readonly GENOMIC="${EXAMPLE_DIR}/genomic"
readonly REF="${GENOMIC}/${DATASET}_Genome.fasta"
readonly GFF="${GENOMIC}/${DATASET}.gff"
readonly GTF="${GENOMIC}/${DATASET}.gtf"
readonly CHROMSIZES="${GENOMIC}/${DATASET}.chrom.sizes"

readonly IDX_DIR="${GENOMIC}/hisat2_index"
readonly BOWTIE2_IDX="${GENOMIC}/bowtie2_index"
readonly HISAT2_IDX="${IDX_DIR}/${DATASET}_index"

readonly ADAPT="${READS_DIR}/illumina_adapters.fasta"
readonly SAMPLES_TSV="${PROJECT_DIR}/config/samples.tsv"
readonly BACKGROUND_TSV="${PROJECT_DIR}/config/background.tsv"
