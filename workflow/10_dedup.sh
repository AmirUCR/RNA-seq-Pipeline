#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load workflow configuration.
source "${SCRIPT_DIR}/01_common.sh"

# Load conda.
source "${HOME}/miniconda3/etc/profile.d/conda.sh"
conda activate "${ENV}"

log "> 10_dedup.sh"

dedup() {
  local tag=$1

  # Picard MarkDuplicates (remove + index)
  picard -Xmx8g MarkDuplicates \
    -I "${tag}.sorted.bam" \
    -O "${tag}.dedup.bam" \
    -M "${tag}.dup_metrics.txt" \
    -OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 \
    -CREATE_INDEX true \
    -VALIDATION_STRINGENCY SILENT
    # -REMOVE_DUPLICATES true \
}

# —— Run
while IFS=$'\t' read -r sample_id condition r1 r2; do
  dedup "${OUT_TRIM}/${sample_id}/trimmed"
done < <(tail -n +2 "${SAMPLES_TSV}")

dedup_counts() {
  local tag="$1"
  local bam="${tag}.dedup.bam"
  local out="${tag}.dedup_read_counts.txt"

  # Counts (exclude secondary 0x100 and supplementary 0x800 everywhere)
  local total_primary primary_mapped proper_pairs singletons r1 r2
  total_primary=$(samtools view -c -F 0x900 "$bam")
  primary_mapped=$(samtools view -c -F 0x904 "$bam")
  proper_pairs=$(samtools view -c -f 0x42 -F 0x904 "$bam")   # count pairs once via first-in-pair 0x40
  singletons=$(samtools view -c -f 0x8  -F 0x904 "$bam")     # mapped read whose mate is unmapped
  r1=$(samtools view -c -f 0x40 -F 0x904 "$bam")
  r2=$(samtools view -c -f 0x80 -F 0x904 "$bam")

  awk -v bam="$bam" -v total="$total_primary" -v mapped="$primary_mapped" \
      -v proper="$proper_pairs" -v single="$singletons" -v r1="$r1" -v r2="$r2" '
    BEGIN{
      pairs = (total/2.0);
      mapped_rate = (total>0)? 100.0*mapped/total : 0.0;
      proper_rate = (pairs>0)? 100.0*proper/pairs : 0.0;
      printf "bam\t%s\n", bam;
      printf "total_primary_alignments\t%d\n", total;
      printf "primary_mapped_reads\t%d\n", mapped;
      printf "primary_mapped_rate\t%.2f%%\n", mapped_rate;
      printf "properly_paired_pairs\t%d\n", proper;
      printf "properly_paired_rate\t%.2f%%\n", proper_rate;
      printf "singleton_mapped_reads\t%d\n", single;
      printf "read1_mapped\t%d\n", r1;
      printf "read2_mapped\t%d\n", r2;
    }' > "$out"

  # Optionally append duplication rate from Picard metrics if present
  if [[ -f "${tag}.dup_metrics.txt" ]]; then
    local dup_rate=$(awk -F'\t' '
      BEGIN{col=-1}
      /^#/ {next}
      $1=="LIBRARY" {for(i=1;i<=NF;i++){if($i=="PERCENT_DUPLICATION"){col=i}}; next}
      col>0 {print $col; exit}
    ' "${tag}.dup_metrics.txt")
    echo -e "picard_percent_duplication\t${dup_rate}" >> "$out"
  fi

  echo "Wrote ${out}"
}
 
while IFS=$'\t' read -r sample_id condition r1 r2; do
  dedup_counts "${OUT_TRIM}/${sample_id}/trimmed"
done < <(tail -n +2 "${SAMPLES_TSV}")
