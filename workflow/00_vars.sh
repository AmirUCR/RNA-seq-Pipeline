export THREADS=30

export DATASET=PlasmoDB-36_PbergheiANKA
export DIR=$(cd .. && pwd)/data

export READS_DIR="${DIR}/reads"
export ADAPT="${READS_DIR}/illumina_adapters.fasta"

export GENOMIC="${DIR}/genomic"
export REF="${GENOMIC}/${DATASET}_Genome.fasta"

export RNA_STRAND="RF"

export READS="${READS_DIR}/untrimmed"
export READS_TRIM="${READS_DIR}/trimmed"

export OUT_DIR="${DIR}/output"
export OUT="${OUT_DIR}/untrimmed"
export OUT_TRIM="${OUT_DIR}/trimmed"

export GFF="${GENOMIC}/${DATASET}.gff"
export GTF="${GENOMIC}/${DATASET}.gtf"
export CHROMSIZES="${GENOMIC}/${DATASET}.chrom.sizes"

export IDX_DIR="${GENOMIC}/hisat2_index"
export BOWTIE2_IDX="${GENOMIC}/bowtie2_index"
export HISAT2_IDX="${IDX_DIR}/${DATASET}_index"

# ------- DATA
export A1=24WT_Schi3_B7_S72_L007_R1_001.fastq.gz
export A2=24WT_Schi3_B7_S72_L007_R2_001.fastq.gz

export B1=24WT_Schi4_B8_S73_L007_R1_001.fastq.gz
export B2=24WT_Schi4_B8_S73_L007_R2_001.fastq.gz

export C1=CRK6_PTD1_B9_S74_L007_R1_001.fastq.gz
export C2=CRK6_PTD1_B9_S74_L007_R2_001.fastq.gz

export D1=CRK6_PTD2_B10_S75_L007_R1_001.fastq.gz
export D2=CRK6_PTD2_B10_S75_L007_R2_001.fastq.gz

export E1=CRK6_PTD3_B11_S76_L007_R1_001.fastq.gz
export E2=CRK6_PTD3_B11_S76_L007_R2_001.fastq.gz

export F1=CRK6_PTD4_B12_S77_L007_R1_001.fastq.gz
export F2=CRK6_PTD4_B12_S77_L007_R2_001.fastq.gz

# ------- OUTPUTS 
export A=24WT_Schi3
export B=24WT_Schi4
export C=CRK6_PTD1
export D=CRK6_PTD2
export E=CRK6_PTD3
export F=CRK6_PTD4

export SAMPLES=("$A" "$B" "$C" "$D" "$E" "$F")
export SAMPLES_R1=("$A1" "$B1" "$C1" "$D1" "$E1" "$F1")
export SAMPLES_R2=("$A2" "$B2" "$C2" "$D2" "$E2" "$F2")

export NUM_SAMPLES=${#SAMPLES[@]}
