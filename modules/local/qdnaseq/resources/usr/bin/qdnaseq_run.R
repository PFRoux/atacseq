#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(QDNAseq)
    library(Biobase)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
    idx <- match(flag, args)
    if (is.na(idx) || idx == length(args)) {
        return(default)
    }
    args[[idx + 1]]
}

bam <- get_arg("--bam")
bins_rds <- get_arg("--bins-rds")
bin_size <- as.integer(get_arg("--bin-size", "1000"))
loss_threshold <- as.numeric(get_arg("--loss-threshold", "-0.4"))
gain_threshold <- as.numeric(get_arg("--gain-threshold", "0.4"))
out_prefix <- get_arg("--out-prefix", "qdnaseq")

if (is.null(bam) || is.null(bins_rds)) {
    stop("--bam and --bins-rds are required")
}

bins <- readRDS(bins_rds)
if (!inherits(bins, "QDNAseqReadCounts")) {
    counts <- binReadCounts(bins, bamfiles = bam)
} else {
    counts <- bins
}

if (!inherits(counts, "QDNAseqReadCounts")) {
    counts <- binReadCounts(counts, bamfiles = bam)
}

counts <- applyFilters(counts, residual = TRUE, blacklist = TRUE)
counts <- estimateCorrection(counts)
counts <- correctBins(counts)
counts <- normalizeBins(counts)
counts <- smoothOutlierBins(counts)
counts <- segmentBins(counts)
counts <- callBins(counts, cutoffs = c(loss_threshold, gain_threshold))

saveRDS(counts, paste0(out_prefix, ".qdnaseq.rds"))

feature_table <- as.data.frame(fData(counts))
expr_table <- as.data.frame(exprs(counts))
if (ncol(expr_table) > 0) {
    colnames(expr_table) <- paste0("reads_", seq_len(ncol(expr_table)))
}
bin_table <- cbind(feature_table, expr_table)
write.table(
    bin_table,
    file = paste0(out_prefix, ".qdnaseq.bins.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

if ("segmented" %in% assayDataElementNames(counts)) {
    segmented_table <- cbind(feature_table, as.data.frame(assayDataElement(counts, "segmented")))
    write.table(
        segmented_table,
        file = paste0(out_prefix, ".qdnaseq.segments.tsv"),
        sep = "\t",
        quote = FALSE,
        row.names = FALSE
    )
}

if ("calls" %in% assayDataElementNames(counts)) {
    calls_table <- cbind(feature_table, as.data.frame(assayDataElement(counts, "calls")))
    write.table(
        calls_table,
        file = paste0(out_prefix, ".qdnaseq.calls.tsv"),
        sep = "\t",
        quote = FALSE,
        row.names = FALSE
    )
}

pdf(paste0(out_prefix, ".qdnaseq.pdf"), width = 10, height = 6)
try(plot(counts, logTransform = FALSE, main = paste0("QDNAseq CNV profile: ", out_prefix)), silent = TRUE)
try(plot(counts, chromosomes = NULL, logTransform = FALSE, main = paste0("QDNAseq genome profile: ", out_prefix)), silent = TRUE)
dev.off()
