suppressPackageStartupMessages(library(DESeq2))

args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
  script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
  script_path <- normalizePath(getwd())
}

ROOT_DIR <- normalizePath(file.path(script_path, "..", "data"))

OUT_DIR     <- file.path(ROOT_DIR, "output")
counts_file <- file.path(OUT_DIR, "counts.csv")
design_file <- file.path(ROOT_DIR, "design.csv")
output_file <- file.path(OUT_DIR, "deseq2_results.csv")

df <- read.csv(counts_file, row.names = 1, check.names = FALSE)
colData <- read.csv(design_file, stringsAsFactors = FALSE)

colData$condition <- factor(colData$condition, levels = c("WT", "KD"))

stopifnot(all(colData$sample %in% colnames(df)))
df <- df[, colData$sample, drop = FALSE]
stopifnot(identical(colnames(df), colData$sample))
rownames(colData) <- colData$sample

countData <- as.matrix(round(df))
dds <- DESeqDataSetFromMatrix(
  countData = countData,
  colData   = colData,
  design    = ~ condition
)

dds <- dds[rowSums(counts(dds) >= 10) >= 2, , drop = FALSE]

dds <- DESeq(dds)

# alpha is optional; it affects independent filtering bookkeeping, not raw pvalues
res <- results(dds, contrast = c("condition", "KD", "WT"), alpha = 0.05)

normed <- round(counts(dds, normalized = TRUE), 1)

colA <- rownames(colData)[colData$condition == "WT"]
colB <- rownames(colData)[colData$condition == "KD"]

out <- data.frame(
  name           = rownames(res),
  baseMean       = round(res$baseMean, 1),
  log2FoldChange = round(res$log2FoldChange, 3),
  lfcSE          = round(res$lfcSE, 3),
  stat           = round(res$stat, 3),
  PValue         = res$pvalue,
  FDR            = res$padj,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

out$baseMeanA <- round(rowMeans(normed[, colA, drop = FALSE]), 1)
out$baseMeanB <- round(rowMeans(normed[, colB, drop = FALSE]), 1)

# foldChange with NA-safe handling
out$foldChange <- NA_real_
ok_fc <- !is.na(out$log2FoldChange)
out$foldChange[ok_fc] <- round(2 ^ out$log2FoldChange[ok_fc], 3)

# Keep numeric pvalue for sorting before formatting
out$PValue_num <- out$PValue

# Optional: This is NOT the same as DESeq2 padj (BH). Keep only if you really want it.
out$PAdj_hoc <- p.adjust(out$PValue, method = "hochberg")

normed_df <- data.frame(name = rownames(normed), normed, check.names = FALSE)
total <- merge(out, normed_df, by = "name", all.x = TRUE)

# Sort numerically
total <- total[order(total$PValue_num, -total$foldChange), ]

# Now format for output
total$PValue <- formatC(total$PValue_num, format = "e", digits = 2)
total$FDR    <- ifelse(is.na(total$FDR), NA_character_,
                       formatC(total$FDR, format = "e", digits = 2))
total$PAdj_hoc <- ifelse(is.na(total$PAdj_hoc), NA_character_,
                         formatC(total$PAdj_hoc, format = "e", digits = 2))

# Drop helper column if you do not want it in the CSV
# total$PValue_num <- NULL

write.csv(total, file = output_file, row.names = FALSE, quote = FALSE)

cat("# Tool: DESeq2\n",
    "# Design: ", design_file, "\n",
    "# Input: ", counts_file, "\n",
    "# Output: ", output_file, "\n", sep = "")
