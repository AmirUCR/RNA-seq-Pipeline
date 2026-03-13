#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/00_vars.sh"
source "${SCRIPT_DIR}/01_common.sh"

# Load conda and activate env.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 03_trimming.sh"

# Create output directory.
mkdir -p "${READS_TRIM}"

# ------- FASTP PARAMETERS
ALL_OTHER_PARAMETERS=(
  # --adapter_fasta "${ADAPT}"  # optional custom adapters
  --length_required 25
  --cut_tail
  --cut_window_size 6
  --cut_mean_quality 26
  --trim_tail1 1        # trim last base (artifact)
  --trim_tail2 1
  --trim_front1 11      # remove GC bias observed in FastQC
  --trim_front2 11
  --trim_poly_x
  --poly_x_min_len 10
  --thread "${THREADS}"
)

while IFS=$'\t' read -r sample_id condition r1 r2; do
  log "Running fastp for ${sample_id}"

  fastp \
    -i "${READS}/${r1}" \
    -I "${READS}/${r2}" \
    -o "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
    -O "${READS_TRIM}/${sample_id}_R2.fastq.gz" \
    --html "${READS_TRIM}/fastp_report_${sample_id}.html" \
    --json "${READS_TRIM}/fastp_report_${sample_id}.json" \
    "${ALL_OTHER_PARAMETERS[@]}"

done < <(tail -n +2 "${SAMPLES_TSV}")
