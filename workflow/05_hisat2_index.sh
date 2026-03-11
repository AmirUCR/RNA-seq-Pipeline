#!/usr/bin/env bash
set -Eeuo pipefail

# —— Conda
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate ngs

source "0_vars.sh"

mkdir -p "${IDX_DIR}"

# —— Build HISAT2 index (only if missing)
if ! ls "${HISAT2_IDX}".* >/dev/null 2>&1; then
  hisat2-build "${REF}" "${HISAT2_IDX}"
fi