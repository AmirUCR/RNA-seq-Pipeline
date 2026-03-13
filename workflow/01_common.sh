#!/usr/bin/env bash
set -Eeuo pipefail

readonly COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${COMMON_DIR}/00_vars.sh"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_file() {
    local path="$1"
    if [[ ! -f "${path}" ]]; then
        echo "Missing file: ${path}" >&2
        exit 1
    fi
}

require_dir() {
    local path="$1"
    if [[ ! -d "${path}" ]]; then
        echo "Missing directory: ${path}" >&2
        exit 1
    fi
}

iterate_samples() {
    tail -n +2 "${SAMPLES_TSV}"
}

get_first_strandedness_file() {
    local file=""
    shopt -s nullglob
    for file in "${STRAND_DIR}"/*/*_strandedness.txt; do
        printf '%s\n' "${file}"
        return 0
    done
    echo "No strandedness report found under ${STRAND_DIR}" >&2
    return 1
}

parse_strandedness_fractions() {
    local file="$1"
    local forward=""
    local reverse=""

    require_file "${file}"

    forward="$(grep '1++,1--,2+-,2-+' "${file}" | awk '{print $NF}')"
    reverse="$(grep '1+-,1-+,2++,2--' "${file}" | awk '{print $NF}')"

    if [[ -z "${forward}" || -z "${reverse}" ]]; then
        echo "Could not parse strandedness fractions from ${file}" >&2
        return 1
    fi

    printf '%s\t%s\n' "${forward}" "${reverse}"
}

infer_featurecounts_strand() {
    local file=""
    local forward=""
    local reverse=""

    file="$(get_first_strandedness_file)"
    read -r forward reverse < <(parse_strandedness_fractions "${file}")

    if awk -v f="${forward}" -v r="${reverse}" 'BEGIN { exit !(r > 0.8 && r > f) }'; then
        FEATURE_COUNTS_STRANDEDNESS=2
    elif awk -v f="${forward}" -v r="${reverse}" 'BEGIN { exit !(f > 0.8 && f > r) }'; then
        FEATURE_COUNTS_STRANDEDNESS=1
    else
        FEATURE_COUNTS_STRANDEDNESS=0
    fi

    export FEATURE_COUNTS_STRANDEDNESS
}

infer_hisat2_strand() {
    local file=""
    local forward=""
    local reverse=""

    file="$(get_first_strandedness_file)"
    read -r forward reverse < <(parse_strandedness_fractions "${file}")

    if awk -v f="${forward}" -v r="${reverse}" 'BEGIN { exit !(r > 0.8 && r > f) }'; then
        HISAT2_STRANDEDNESS="RF"
    elif awk -v f="${forward}" -v r="${reverse}" 'BEGIN { exit !(f > 0.8 && f > r) }'; then
        HISAT2_STRANDEDNESS="FR"
    else
        HISAT2_STRANDEDNESS="none"
    fi

    export HISAT2_STRANDEDNESS
}