#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 07_fastp_screen.sh"

mkdir -p "${CONTAM_OUT}"

log "Creating FastQ Screen config at ${FASTQ_SCREEN_CONFIG}"

{
    echo "# where bowtie2 lives"
    echo "BOWTIE2        ${BOWTIE2_PATH}"
    echo ""
    echo "# add a touch more sensitivity + unique hits"
    echo "BOWTIE2_OPTIONS --very-sensitive"
    echo ""
    echo "# Databases (name then index prefix)"

    while IFS=$'\t' read -r shorthand path_in_genomic; do
        idx="${BOWTIE2_IDX}/${shorthand}/${shorthand}"

        if [[ ! -f "${idx}.1.bt2" ]]; then
            log "Warning: bowtie2 index for ${shorthand} not found: ${idx}"
        fi

        echo "DATABASE       ${shorthand}      ${idx}"
    done < <(tail -n +2 "${BACKGROUND_TSV}")
} > "${FASTQ_SCREEN_CONFIG}"

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
log "Concurrent FastQ Screen jobs: ${MAX_JOBS}"
log "Threads per FastQ Screen job: ${THREADS_PER_SAMPLE}"

run_fastq_screen() {
    local sample_id="$1"
    local condition="$2"
    local r1="$3"
    local r2="$4"

    log "Running FastQ Screen for ${sample_id}"

    fastq_screen \
        --aligner bowtie2 \
        --subset 200000 \
        --threads "${THREADS_PER_SAMPLE}" \
        --conf "${FASTQ_SCREEN_CONFIG}" \
        --outdir "${CONTAM_OUT}" \
        "${READS_TRIM}/${sample_id}_R1.fastq.gz" \
        "${READS_TRIM}/${sample_id}_R2.fastq.gz"
}

active_jobs=0

for line in "${SAMPLE_LINES[@]}"; do
    IFS=$'\t' read -r sample_id condition r1 r2 <<< "${line}"

    run_fastq_screen "${sample_id}" "${condition}" "${r1}" "${r2}" &
    ((active_jobs+=1))

    if (( active_jobs >= MAX_JOBS )); then
        wait
        active_jobs=0
    fi
done

wait
