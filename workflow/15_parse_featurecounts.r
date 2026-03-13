# Parse featureCounts output into a simple counts matrix.

TRIM_UNTRIM <- "trimmed"

# Try to get script path from commandArgs()
args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
    script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
    script_path <- normalizePath(getwd())
}

# Project structure
PROJECT_DIR <- normalizePath(file.path(script_path, ".."))
ROOT_DIR <- file.path(PROJECT_DIR, "example_data")
OUT_DIR <- file.path(ROOT_DIR, "output", TRIM_UNTRIM)

# Input files
counts_file <- file.path(OUT_DIR, "counts.txt")
samples_file <- file.path(PROJECT_DIR, "config", "samples.tsv")

# Output file
output_file <- file.path(OUT_DIR, "counts.csv")

# Inform the user
cat("# Tool: Parse featureCounts\n")
cat("# Samples:", samples_file, "\n")
cat("# Input:", counts_file, "\n")

# Read sample sheet
sample_data <- read.table(
    samples_file,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    check.names = FALSE
)

sample_data <- sample_data[, c("sample_id", "condition")]
names(sample_data) <- c("sample", "condition")

if (!all(c("sample", "condition") %in% names(sample_data))) {
    stop("samples.tsv must contain columns named 'sample_id' and 'condition'")
}

sample_data$condition <- factor(sample_data$condition)
sample_data$condition <- stats::relevel(
    sample_data$condition,
    ref = as.character(sample_data$condition[1])
)

# Read featureCounts output
df <- read.table(
    counts_file,
    header = TRUE,
    sep = "\t",
    comment.char = "#",
    check.names = FALSE
)

# featureCounts columns:
# 1 Geneid
# 2 Chr
# 3 Start
# 4 End
# 5 Strand
# 6 Length
# 7+ sample count columns
counts <- df[, c(1, 7:ncol(df))]

# Check sample count consistency
if ((ncol(counts) - 1) != nrow(sample_data)) {
    stop("Number of samples in counts.txt does not match number of rows in samples.tsv")
}

# Rename columns using sample sheet sample names
colnames(counts) <- c("name", sample_data$sample)

# Write output
write.csv(counts, file = output_file, row.names = FALSE, quote = FALSE)

# Inform the user
cat("# Output:", output_file, "\n")
