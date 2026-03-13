# RNA-seq Analysis Pipeline

End-to-end bulk RNA-seq analysis workflow used for *Plasmodium berghei* – WT vs SMC4 knockdown
transcriptomics experiments. Public data obtained from [Tewari, R., et al. Cell Rep., 2020
](https://pmc.ncbi.nlm.nih.gov/articles/PMC7016506/) – SRA PRJNA542367.


## Pipeline steps:

1. Quality control (FastQC)
2. Adapter and reads trimming (fastp)
3. Contamination screening (FastQ Screen)
4. Alignment (HISAT2)
5. Deduplication (marking only)
6. Feature counting (featureCounts)
7. Differential expression (DESeq2 / edgeR)
8. Visualization (PCA, heatmaps, volcano plots)
9. GO enrichment analysis

## Example Output

### Volcano plot

(image)

### Differential expression heatmap

(image)

### GO enrichment

(image)

## Run pipeline

1. Create and activate environment:
   ```
   conda env create -f environment.yaml
   conda activate rnaseq
   ```
2. Configure paths in: `workflow/00_vars.sh`
3. Run workflow:
   ```
   bash workflow/01_fastqc.sh
   bash workflow/02_trimming.sh
   ```
