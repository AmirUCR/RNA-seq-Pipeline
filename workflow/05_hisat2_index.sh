#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 05_hisat2_index.sh"

mkdir -p "${IDX_DIR}"

# —— Build HISAT2 index (only if missing)
if ! ls "${HISAT2_IDX}".* >/dev/null 2>&1; then
  log "Running hisat2-build"
  
  hisat2-build -p "${THREADS}" "${REF}" "${HISAT2_IDX}"
fi
