#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration first.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda and activate env.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 02_fastqc.sh"

# Read samples into an array so we can count them.
mapfile -t SAMPLE_LINES < <(iterate_samples)
NUM_SAMPLES="${#SAMPLE_LINES[@]}"

if (( NUM_SAMPLES == 0 )); then
    echo "No samples found in ${SAMPLES_TSV}" >&2
    exit 1
fi

# Limit the number of concurrent FastQC jobs so total threads stay reasonable.
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

run_fastqc() {
    local sample_id="$1"
    local condition="$2"
    local r1="$3"
    local r2="$4"

    log "Creating directory for ${sample_id}"
    mkdir -p "${OUT}/${sample_id}"

    log "Running FastQC for ${sample_id}"
    fastqc \
        "${READS}/${r1}" \
        "${READS}/${r2}" \
        -o "${OUT}/${sample_id}" \
        -t "${THREADS_PER_SAMPLE}"
}

active_jobs=0

for line in "${SAMPLE_LINES[@]}"; do
    IFS=$'\t' read -r sample_id condition r1 r2 <<< "${line}"

    run_fastqc "${sample_id}" "${condition}" "${r1}" "${r2}" &
    ((active_jobs+=1))

    if (( active_jobs >= MAX_JOBS )); then
        wait
        active_jobs=0
    fi
done

wait

log "Running multiqc"
multiqc \
    "${OUT}" \
    -o "${OUT}" \
    -f \
    --clean-up