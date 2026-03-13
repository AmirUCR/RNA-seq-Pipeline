#
# Create heat map from an edgeR differential expression table.
#

suppressPackageStartupMessages(library(gplots))

TRIM_UNTRIM <- "trimmed"

args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
  script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
  script_path <- normalizePath(getwd())
}

PROJECT_DIR <- normalizePath(file.path(script_path, ".."))
ROOT_DIR <- file.path(PROJECT_DIR, "example_data")
OUT_DIR <- file.path(ROOT_DIR, "output", TRIM_UNTRIM)

count_file <- file.path(OUT_DIR, "edger_results.csv")
samples_file <- file.path(PROJECT_DIR, "config", "samples.tsv")
output_file <- file.path(OUT_DIR, "edger_heatmap.pdf")
png_file <- file.path(OUT_DIR, "edger_heatmap.png")

cat("# Tool: Create Heatmap\n")
cat("# Input:", count_file, "\n")
cat("# Output:", output_file, "\n")

MIN_FDR <- 0.05
WIDTH <- 12
HEIGHT <- 14
MARGINS <- c(14, 12)
LHEI <- c(1, 5)

data <- read.csv(count_file, header = TRUE, as.is = TRUE, check.names = FALSE)

sample_data <- read.table(
  samples_file,
  header = TRUE,
  sep = "\t",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

sample_cols <- sample_data$sample_id

if (!("FDR" %in% colnames(data))) {
  stop("Expected an 'FDR' column.")
}

if (!("name" %in% colnames(data))) {
  stop("Expected a 'name' column for gene IDs.")
}

missing_samples <- setdiff(sample_cols, colnames(data))
if (length(missing_samples) > 0) {
  stop(
    paste(
      "Missing sample columns in edgeR results:",
      paste(missing_samples, collapse = ", ")
    )
  )
}

# Ensure numeric FDR
data$FDR <- as.numeric(data$FDR)

# Subset significant genes
data <- subset(data, !is.na(FDR) & FDR <= MIN_FDR)

if (nrow(data) == 0) {
  stop("No rows pass the FDR cutoff.")
}

row_names <- data$name
counts <- data[, sample_cols, drop = FALSE]

# Make sure counts are numeric
values <- as.matrix(sapply(counts, as.numeric))
rownames(values) <- row_names

# Add tiny noise only if needed to avoid zero-variance rows
row_sds <- apply(values, 1, sd, na.rm = TRUE)
zero_var <- is.na(row_sds) | row_sds == 0
if (any(zero_var)) {
  values[zero_var, ] <- jitter(values[zero_var, ], factor = 1, amount = 1e-5)
}

# Row-wise z-score
row_means <- rowMeans(values, na.rm = TRUE)
row_sds <- apply(values, 1, sd, na.rm = TRUE)
row_sds[row_sds == 0 | is.na(row_sds)] <- 1

zscores <- sweep(values, 1, row_means, "-")
zscores <- sweep(zscores, 1, row_sds, "/")
rownames(zscores) <- row_names

# Optional column annotation by condition
condition <- sample_data$condition
names(condition) <- sample_data$sample_id
condition <- condition[colnames(zscores)]

draw_heatmap <- function() {
  heatmap.2(
    zscores,
    col = greenred(75),
    density.info = "none",
    Colv = NULL,
    dendrogram = "row",
    trace = "none",
    margins = MARGINS,
    lhei = LHEI,
    srtCol = 45,
    cexCol = 0.8
  )
}

pdf(output_file, width = WIDTH, height = HEIGHT)
draw_heatmap()
dev.off()

png(
  png_file,
  width = WIDTH,
  height = HEIGHT,
  units = "in",
  res = 600
)
draw_heatmap()
dev.off()
