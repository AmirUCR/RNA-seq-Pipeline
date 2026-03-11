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
