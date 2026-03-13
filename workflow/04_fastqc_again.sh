#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 04_fastqc_again.sh"

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
log "Concurrent FastQC jobs: ${MAX_JOBS}"
log "Threads per FastQC job: ${THREADS_PER_SAMPLE}"

run_fastqc_trimmed() {
    local sample_id="$1"
    local condition="$2"
    local r1="$3"
    local r2="$4"

    log "Creating directory for ${sample_id}"
    mkdir -p "${OUT_TRIM}/${sample_id}"

    log "Running FastQC for ${sample_id}"
    fastqc \
        "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
        "${READS_TRIM}/${sample_id}_R2.fastq.gz" \
        -o "${OUT_TRIM}/${sample_id}" \
        --threads "${THREADS_PER_SAMPLE}"
}

active_jobs=0

for line in "${SAMPLE_LINES[@]}"; do
    IFS=$'\t' read -r sample_id condition r1 r2 <<< "${line}"

    run_fastqc_trimmed "${sample_id}" "${condition}" "${r1}" "${r2}" &
    ((active_jobs+=1))

    if (( active_jobs >= MAX_JOBS )); then
        wait
        active_jobs=0
    fi
done

wait

log "Running multiqc"
multiqc \
    "${OUT_TRIM}" \
    -o "${OUT_TRIM}" \
    -f \
    --clean-up
    