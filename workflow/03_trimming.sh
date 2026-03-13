#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda and activate env.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 03_trimming.sh"

# Create output directory.
mkdir -p "${READS_TRIM}"

mapfile -t SAMPLE_LINES < <(iterate_samples)
NUM_SAMPLES="${#SAMPLE_LINES[@]}"

if (( NUM_SAMPLES == 0 )); then
    echo "No samples found in ${SAMPLES_TSV}" >&2
    exit 1
fi

MAX_JOBS="${NUM_SAMPLES}"
if (( MAX_JOBS > THREADS )); then
    MAX_JOBS="${THREADS}"
fi

THREADS_PER_SAMPLE=$(( THREADS / MAX_JOBS ))
if (( THREADS_PER_SAMPLE < 1 )); then
    THREADS_PER_SAMPLE=1
fi

log "Total threads: ${THREADS}"
log "Samples: ${NUM_SAMPLES}"
log "Concurrent fastp jobs: ${MAX_JOBS}"
log "Threads per fastp job: ${THREADS_PER_SAMPLE}"

run_fastp() {
    local sample_id="$1"
    local condition="$2"
    local r1="$3"
    local r2="$4"

    log "Running fastp for ${sample_id}"

    fastp \
        -i "${READS}/${r1}" \
        -I "${READS}/${r2}" \
        -o "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
        -O "${READS_TRIM}/${sample_id}_R2.fastq.gz" \
        --html "${READS_TRIM}/fastp_report_${sample_id}.html" \
        --json "${READS_TRIM}/fastp_report_${sample_id}.json" \
        --length_required 25 \
        --cut_tail \
        --cut_window_size 6 \
        --cut_mean_quality 26 \
        --trim_tail1 1 \
        --trim_tail2 1 \
        --trim_front1 11 \
        --trim_front2 11 \
        --trim_poly_x \
        --poly_x_min_len 10 \
        --thread "${THREADS_PER_SAMPLE}"
}

active_jobs=0

for line in "${SAMPLE_LINES[@]}"; do
    IFS=$'\t' read -r sample_id condition r1 r2 <<< "${line}"

    run_fastp "${sample_id}" "${condition}" "${r1}" "${r2}" &
    ((active_jobs+=1))

    if (( active_jobs >= MAX_JOBS )); then
        wait
        active_jobs=0
    fi
done

wait
