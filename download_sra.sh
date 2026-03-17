#!/bin/bash

# Usage: ./download_sra.sh accessions.txt
# The accessions.txt file should have one SRR ID per line.

ACCESSIONS_FILE=$1
OUTPUT_PATH="example_data/reads/untrimmed"

if [[ -z "$ACCESSIONS_FILE" ]]; then
    echo "Error: No accession list provided."
    echo "Usage: $0 accessions.txt"
    exit 1
fi

# Create an output directory for FASTQs
mkdir -p "${OUTPUT_PATH}"

while IFS= read -r ACC || [[ -n "$ACC" ]]; do
    # Skip empty lines or comments
    [[ -z "$ACC" || "$ACC" =~ ^# ]] && continue

    echo "------------------------------------------------------"
    echo "Processing: $ACC"
    echo "------------------------------------------------------"

    # 1. Prefetch the data
    echo "Starting prefetch..."
    prefetch "$ACC"

    # 2. Extract to FASTQ (using 4 threads)
    # Using --split-3 to handle paired-end and single-end automatically
    echo "Extracting FASTQs..."
    fasterq-dump --split-3 --threads 4 --outdir "${OUTPUT_PATH}" "$ACC"

    # 3. Compress the resulting files
    echo "Compressing files..."
    gzip "${OUTPUT_PATH}"/"$ACC"*.fastq

    echo "Done with $ACC"
done < "$ACCESSIONS_FILE"

echo "------------------------------------------------------"
echo "Batch processing complete. Files are in ${OUTPUT_PATH}"
