#
# Create heat map from a differential expression count table.
#
suppressPackageStartupMessages(library(gplots))

args <- commandArgs(trailingOnly = FALSE)
script_location <- grep("--file=", args, value = TRUE)

if (length(script_location) > 0) {
  script_path <- dirname(normalizePath(sub("^--file=", "", script_location)))
} else {
  script_path <- normalizePath(getwd())
}

ROOT_DIR <- normalizePath(file.path(script_path, "..", "data"))
OUT_DIR  <- file.path(ROOT_DIR, "output")

count_file  <- file.path(OUT_DIR, "edger_results.csv")
output_file <- file.path(OUT_DIR, "edger_heatmap.pdf")
png_file <- file.path(OUT_DIR, "edger_heatmap.png")

print("# Tool: Create Heatmap ")
print(paste("# Input: ", count_file))
print(paste("# Output: ", output_file))

MIN_FDR <- 0.05
WIDTH   <- 12
HEIGHT  <- 14
MARGINS <- c(14, 12)
LHEI    <- c(1, 5)

data <- read.csv(count_file, header = TRUE, as.is = TRUE)

# Subset data for values under a threshold.
data <- subset(data, FDR <= MIN_FDR)

if (nrow(data) == 0) {
  stop("No rows pass the FDR cutoff.")
}

if (!("name" %in% colnames(data))) {
  stop("Expected a 'name' column for gene IDs.")
}

row_names <- data$name

if (!("falsePos" %in% colnames(data))) {
  stop("Expected a 'falsePos' column to locate the count matrix.")
}

idx <- which(colnames(data) == "falsePos") + 1
if (idx > ncol(data)) {
  stop("No columns found to the right of 'falsePos' for the count matrix.")
}

counts <- data[, idx:ncol(data), drop = FALSE]

# Make sure counts are numeric
values <- as.matrix(sapply(counts, as.numeric))
row.names(values) <- row_names

# Add tiny noise to avoid zero-variance rows breaking clustering/zscore
values <- jitter(values, factor = 1, amount = 1e-5)

# Row-wise z-score, vectorized, with sd guard
row_means <- rowMeans(values, na.rm = TRUE)
row_sds   <- apply(values, 1, sd, na.rm = TRUE)

# Avoid division by zero
row_sds[row_sds == 0 | is.na(row_sds)] <- 1

zscores <- (values - row_means) / row_sds
row.names(zscores) <- row_names

col <- greenred

draw_heatmap <- function() {
  heatmap.2(
    zscores,
    col = greenred,
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

# PDF
pdf(output_file, width = WIDTH, height = HEIGHT)
draw_heatmap()
dev.off()

# PNG (high resolution, publication ready)
png(
  png_file,
  width = WIDTH,
  height = HEIGHT,
  units = "in",
  res = 600
)
draw_heatmap()

dev.off()
