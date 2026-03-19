#
# Differential expression analysis with edgeR.
#

suppressPackageStartupMessages(library(edgeR))

TRIM_UNTRIM <- "trimmed"

# Try to get script path from commandArgs()
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
output_file <- file.path(OUT_DIR, "edger_results.csv")

# Read sample sheet
colData <- read.table(
  samples_file,
  header = TRUE,
  sep = "\t",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

colData <- colData[, c("sample_id", "condition")]
names(colData) <- c("sample", "condition")

stopifnot(all(c("sample", "condition") %in% colnames(colData)))

colData$condition <- factor(colData$condition)
colData$condition <- relevel(
  colData$condition,
  ref = as.character(colData$condition[1])
)

sample_names <- colData$sample

# Read counts matrix
df <- read.csv(counts_file, row.names = 1, check.names = FALSE)

stopifnot(all(sample_names %in% colnames(df)))
counts <- round(df[, sample_names, drop = FALSE])

# Extra annotation columns if present
otherCols <- df[, !(colnames(df) %in% sample_names), drop = FALSE]

group <- colData$condition

dge <- DGEList(counts = counts, group = group)
dge <- calcNormFactors(dge)

# Optional but common low-count filtering
keep <- filterByExpr(dge)
dge <- dge[keep, , keep.lib.sizes = FALSE]

dge <- estimateCommonDisp(dge)
dge <- estimateTagwiseDisp(dge)

etx <- exactTest(dge)
etp <- topTags(etx, n = nrow(dge$counts), sort.by = "PValue")

# Normalized counts on CPM-like scale used in your original script
scale <- dge$samples$lib.size * dge$samples$norm.factors
normed <- round(t(t(dge$counts) / scale) * mean(scale), 1)
normed <- as.data.frame(normed, check.names = FALSE)

# Merge annotation columns and edgeR result table
data <- merge(
  otherCols,
  etp$table,
  by = "row.names",
  all.y = TRUE
)

colnames(data)[1] <- "name"
names(data)[names(data) == "logFC"] <- "log2FoldChange"

data$foldChange <- 2 ^ data$log2FoldChange
data$PAdj_hoc <- p.adjust(data$PValue, method = "hochberg")

# Merge normalized counts
total <- merge(data, normed, by.x = "name", by.y = "row.names", all.x = TRUE)

# Condition-specific sample names
condition_levels <- levels(colData$condition)
if (length(condition_levels) != 2) {
  stop("This script currently expects exactly 2 condition levels.")
}

col_names_A <- colData$sample[colData$condition == condition_levels[1]]
col_names_B <- colData$sample[colData$condition == condition_levels[2]]

# Group means from normalized counts
total$baseMeanA <- rowMeans(total[, col_names_A, drop = FALSE], na.rm = TRUE)
total$baseMeanB <- rowMeans(total[, col_names_B, drop = FALSE], na.rm = TRUE)
total$baseMean <- rowMeans(total[, c(col_names_A, col_names_B), drop = FALSE], na.rm = TRUE)

# Optional cumulative expected false positives in sorted table
total <- total[with(total, order(PValue, -foldChange)), ]
total$falsePos <- seq_len(nrow(total)) * total$FDR

# Reorganize columns
new_cols <- c(
  "name",
  names(otherCols),
  "baseMean", "baseMeanA", "baseMeanB",
  "foldChange", "log2FoldChange", "logCPM", "PValue", "PAdj_hoc", "FDR", "falsePos",
  col_names_A, col_names_B
)

new_cols <- new_cols[new_cols %in% colnames(total)]
total <- total[, new_cols, drop = FALSE]

write.csv(total, file = output_file, row.names = FALSE, quote = FALSE)

cat("# Tool: edgeR\n", sep = "")
cat(paste0("# Samples: ", samples_file, "\n"))
cat(paste0("# Input: ", counts_file, "\n"))
cat(paste0("# Output: ", output_file, "\n"))
