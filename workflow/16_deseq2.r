suppressPackageStartupMessages(library(DESeq2))

TRIM_UNTRIM <- "trimmed"

args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
  script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
  script_path <- normalizePath(getwd())
}

PROJECT_DIR <- normalizePath(file.path(script_path, ".."))
RESULTS_DIR <- file.path(PROJECT_DIR, "results")
OUT_DIR <- file.path(RESULTS_DIR, TRIM_UNTRIM)

counts_file <- file.path(OUT_DIR, "counts.csv")
samples_file <- file.path(PROJECT_DIR, "config", "samples.tsv")
output_file <- file.path(OUT_DIR, "deseq2_results.csv")

df <- read.csv(counts_file, row.names = 1, check.names = FALSE)

colData <- read.table(
  samples_file,
  header = TRUE,
  sep = "\t",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

colData <- colData[, c("sample_id", "condition")]
names(colData) <- c("sample", "condition")

# Preserve sample-sheet order
colData$condition <- factor(colData$condition)

stopifnot(all(colData$sample %in% colnames(df)))
df <- df[, colData$sample, drop = FALSE]
stopifnot(identical(colnames(df), colData$sample))
rownames(colData) <- colData$sample

# Set reference level to first condition in the sample sheet
colData$condition <- stats::relevel(
  colData$condition,
  ref = as.character(colData$condition[1])
)

countData <- as.matrix(round(df))
dds <- DESeqDataSetFromMatrix(
  countData = countData,
  colData = colData,
  design = ~ condition
)

dds <- dds[rowSums(counts(dds) >= 10) >= 2, , drop = FALSE]
dds <- DESeq(dds)

# Compare second level vs first level
condition_levels <- levels(colData$condition)
if (length(condition_levels) != 2) {
  stop("This script currently expects exactly 2 condition levels.")
}

res <- results(
  dds,
  contrast = c("condition", condition_levels[2], condition_levels[1]),
  alpha = 0.05
)

normed <- round(counts(dds, normalized = TRUE), 1)

colA <- rownames(colData)[colData$condition == condition_levels[1]]
colB <- rownames(colData)[colData$condition == condition_levels[2]]

out <- data.frame(
  name = rownames(res),
  baseMean = round(res$baseMean, 1),
  log2FoldChange = round(res$log2FoldChange, 3),
  lfcSE = round(res$lfcSE, 3),
  stat = round(res$stat, 3),
  PValue = res$pvalue,
  FDR = res$padj,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

out$baseMeanA <- round(rowMeans(normed[, colA, drop = FALSE]), 1)
out$baseMeanB <- round(rowMeans(normed[, colB, drop = FALSE]), 1)

out$foldChange <- NA_real_
ok_fc <- !is.na(out$log2FoldChange)
out$foldChange[ok_fc] <- round(2 ^ out$log2FoldChange[ok_fc], 3)

out$PValue_num <- out$PValue
out$PAdj_hoc <- p.adjust(out$PValue, method = "hochberg")

normed_df <- data.frame(name = rownames(normed), normed, check.names = FALSE)
total <- merge(out, normed_df, by = "name", all.x = TRUE)

# Sort safely even if foldChange has NAs
total <- total[order(total$PValue_num, -ifelse(is.na(total$foldChange), -Inf, total$foldChange)), ]

total$PValue <- formatC(total$PValue_num, format = "e", digits = 2)
total$FDR <- ifelse(
  is.na(total$FDR),
  NA_character_,
  formatC(total$FDR, format = "e", digits = 2)
)
total$PAdj_hoc <- ifelse(
  is.na(total$PAdj_hoc),
  NA_character_,
  formatC(total$PAdj_hoc, format = "e", digits = 2)
)

write.csv(total, file = output_file, row.names = FALSE, quote = FALSE)

cat(
  "# Tool: DESeq2\n",
  "# Samples: ", samples_file, "\n",
  "# Input: ", counts_file, "\n",
  "# Output: ", output_file, "\n",
  sep = ""
)
