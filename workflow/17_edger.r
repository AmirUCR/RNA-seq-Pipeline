#
# Differential expression analysis with the edgeR package.
#
# https://bioconductor.org/packages/release/bioc/html/edgeR.html
#

suppressPackageStartupMessages(library(edgeR))

# Try to get script path from commandArgs()
args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
  # Running with Rscript
  script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
  # Interactive fallback (use working directory)
  script_path <- normalizePath(getwd())
}

# ROOT_DIR = ../data relative to script location
ROOT_DIR <- normalizePath(file.path(script_path, "..", "data"))
OUT_DIR  <- file.path(ROOT_DIR, "output")

# Count file produced by featurecounts.
counts_file <- file.path(OUT_DIR, "counts.csv")

# The sample file must be in CSV format and must have the headers "sample" and "condition".
design_file <- file.path(ROOT_DIR, "design.csv")

# The final result file.
output_file <- file.path(OUT_DIR, "edger_results.csv")

# Read the sample file.
colData <- read.csv(design_file, stringsAsFactors = FALSE)
stopifnot(all(c("sample", "condition") %in% colnames(colData)))

# Turn conditions into factors.
colData$condition <- factor(colData$condition)

# The first level should correspond to the first entry in the file!
# Required when building a model.
colData$condition <- relevel(colData$condition, toString(colData$condition[1]))

# Isolate the sample names.
sample_names <- colData$sample

# Read the count matrix (rows=genes, columns=samples)
df <- read.csv(counts_file, row.names = 1, check.names = FALSE)

# Align counts to design order and round to integers
stopifnot(all(sample_names %in% colnames(df)))
counts <- round(df[, sample_names, drop = FALSE])

# Other columns in the dataframe that are not sample information.
# NOTE: this must select COLUMNS, not rows
otherCols <- df[, !(colnames(df) %in% sample_names), drop = FALSE]

# Using the same naming as in the library.
group <- colData$condition

# Creates a DGEList object from a table of counts and group.
dge <- DGEList(counts = counts, group = group)

# (Optional but recommended) normalization factors
dge <- calcNormFactors(dge)

# Maximizes the negative binomial conditional common likelihood to estimate a common dispersion value across all genes.
dis <- estimateCommonDisp(dge)

# Estimates tagwise dispersion values by an empirical Bayes method based on weighted conditional maximum likelihood.
tag <- estimateTagwiseDisp(dis)

# Compute genewise exact tests for differences in the means between the groups.
etx <- exactTest(tag)

# Extracts the most differentially expressed genes.
etp <- topTags(etx, n = nrow(counts))

# Get the scale of the data
scale <- dge$samples$lib.size * dge$samples$norm.factors

# Get the normalized counts (same method as your original script)
normed <- round(t(t(counts) / scale) * mean(scale))
normed <- as.data.frame(normed)

# Turn the edgeR results into a data frame.
# merge expects otherCols to have rownames aligned to genes
data <- merge(
  otherCols,
  etp$table,
  by = "row.names",
  all.y = TRUE
)

# Rename the first column for consistency with other methods.
colnames(data)[1] <- "name"

# Create column placeholders.
data$baseMean      <- 1
data$baseMeanA     <- 1
data$baseMeanB     <- 1
data$foldChange    <- 2 ^ data$logFC
data$falsePos      <- 1

# Rename the column.
names(data)[names(data) == "logFC"] <- "log2FoldChange"

# Compute the adjusted p-value (optional; FDR is already provided by edgeR)
data$PAdj <- p.adjust(data$PValue, method = "hochberg")

# Create a merged output that contains the normalized counts.
total <- merge(data, normed, by.x = "name", by.y = "row.names", all.x = TRUE)

# Sort the data for the output.
total <- total[with(total, order(PValue, -foldChange)), ]

# Compute the false discovery counts on the sorted table.
total$falsePos <- seq_len(nrow(total)) * total$FDR

# Sample names for condition A
col_names_A <- data.frame(split(colData, colData$condition)[1])[, 1]

# Sample names for condition B
col_names_B <- data.frame(split(colData, colData$condition)[2])[, 1]

# Create the individual baseMean columns from normalized counts.
total$baseMeanA <- rowMeans(total[, col_names_A, drop = FALSE])
total$baseMeanB <- rowMeans(total[, col_names_B, drop = FALSE])
total$baseMean  <- total$baseMeanA + total$baseMeanB

# Round the numbers
# total$foldChange      <- round(total$foldChange, 3)
# total$FDR             <- round(total$FDR, 4)
# total$PAdj            <- round(total$PAdj, 4)
# total$logCPM          <- round(total$logCPM, 1)
# total$log2FoldChange  <- round(total$log2FoldChange, 1)
# total$baseMean        <- round(total$baseMean, 1)
# total$baseMeanA       <- round(total$baseMeanA, 1)
# total$baseMeanB       <- round(total$baseMeanB, 1)
# total$falsePos        <- round(total$falsePos, 0)

# Reformat these columns as string.
# total$PAdj   <- formatC(total$PAdj,   format = "e", digits = 1)
# total$PValue <- formatC(total$PValue, format = "e", digits = 1)

# Reorganize columns names to make more sense.
new_cols <- c(
  "name",
  names(otherCols),
  "baseMean","baseMeanA","baseMeanB",
  "foldChange","log2FoldChange","logCPM","PValue","PAdj","FDR","falsePos",
  col_names_A, col_names_B
)

# Slice the dataframe with new columns (only keep columns that exist)
new_cols <- new_cols[new_cols %in% colnames(total)]
total <- total[, new_cols, drop = FALSE]

# Write the result to file.
write.csv(total, file = output_file, row.names = FALSE, quote = FALSE)

# Inform the user.
cat("# Tool: edgeR\n", sep = "")
cat(paste0("# Design: ", design_file, "\n"))
cat(paste0("# Input: ", counts_file, "\n"))
cat(paste0("# Output: ", output_file, "\n"))
