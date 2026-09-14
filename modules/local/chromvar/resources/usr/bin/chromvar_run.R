#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(GenomicRanges)
    library(SummarizedExperiment)
    library(Rsamtools)
    library(Matrix)
    library(chromVAR)
})

parse_options <- function(arguments) {
    options <- list(
        counts = NULL,
        matches = NULL,
        motif_peaks = NULL,
        motif_ids = NULL,
        fasta = NULL,
        out_prefix = "chromvar",
        min_counts = 1L,
        min_samples = 1L,
        background_peaks = 50L
    )
    if (length(arguments) %% 2L != 0L) stop("Options must be provided as --name value pairs.", call. = FALSE)
    for (index in seq.int(1L, length(arguments), by = 2L)) {
        key <- sub("^--", "", arguments[[index]])
        key <- gsub("-", "_", key, fixed = TRUE)
        if (!key %in% names(options)) stop("Unknown option: ", arguments[[index]], call. = FALSE)
        options[[key]] <- arguments[[index + 1L]]
    }
    options$min_counts <- as.integer(options$min_counts)
    options$min_samples <- as.integer(options$min_samples)
    options$background_peaks <- as.integer(options$background_peaks)
    if (anyNA(unlist(options[c("min_counts", "min_samples", "background_peaks")]))) stop("Numeric options must be valid integers.", call. = FALSE)
    options
}

opt <- parse_options(commandArgs(trailingOnly = TRUE))

required <- c("counts", "matches", "motif_peaks", "motif_ids", "fasta")
missing <- required[vapply(required, function(x) is.null(opt[[x]]) || !nzchar(opt[[x]]), logical(1))]
if (length(missing) > 0) {
    stop("Missing required option(s): ", paste(missing, collapse = ", "), call. = FALSE)
}

read_counts <- function(path) {
    tab <- read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
    required_cols <- c("region_id", "chrom", "start", "end")
    missing_cols <- setdiff(required_cols, colnames(tab))
    if (length(missing_cols) > 0) {
        stop("Count matrix is missing required column(s): ", paste(missing_cols, collapse = ", "), call. = FALSE)
    }
    sample_cols <- setdiff(colnames(tab), required_cols)
    if (length(sample_cols) < 2) {
        stop("chromVAR requires at least two samples in the count matrix.", call. = FALSE)
    }
    counts <- as.matrix(tab[, sample_cols, drop = FALSE])
    storage.mode(counts) <- "integer"
    rownames(counts) <- make.unique(tab$region_id)
    list(tab = tab, counts = counts, sample_cols = sample_cols)
}

counts_input <- read_counts(opt$counts)
motif_peaks <- read.delim(opt$motif_peaks, check.names = FALSE, stringsAsFactors = FALSE)
motif_ids <- read.delim(opt$motif_ids, check.names = FALSE, stringsAsFactors = FALSE)
required_peak_cols <- c("row_index", "region_id", "chrom", "start", "end")
required_motif_cols <- c("column_index", "motif_id")
if (length(setdiff(required_peak_cols, colnames(motif_peaks))) > 0L) stop("Motif peak mapping is malformed.", call. = FALSE)
if (length(setdiff(required_motif_cols, colnames(motif_ids))) > 0L) stop("Motif identifier mapping is malformed.", call. = FALSE)

count_order <- match(motif_peaks$region_id, counts_input$tab$region_id)
if (anyNA(count_order)) stop("Motif-match regions are not all represented in the count matrix.", call. = FALSE)
counts <- counts_input$counts[count_order, , drop = FALSE]
rownames(counts) <- motif_peaks$region_id
annotations <- readMM(opt$matches)
if (nrow(annotations) != nrow(counts) || ncol(annotations) != nrow(motif_ids)) {
    stop("Motif-match matrix dimensions do not match its region or motif mapping.", call. = FALSE)
}
colnames(annotations) <- motif_ids$motif_id

gr <- GRanges(
    seqnames = motif_peaks$chrom,
    ranges = IRanges(start = as.integer(motif_peaks$start) + 1L, end = as.integer(motif_peaks$end)),
    region_id = motif_peaks$region_id
)

keep <- width(gr) > 0 &
    rowSums(counts, na.rm = TRUE) >= opt$min_counts &
    rowSums(counts > 0, na.rm = TRUE) >= opt$min_samples

if (sum(keep) < 2) {
    stop("Fewer than two peaks remain after chromVAR filtering.", call. = FALSE)
}

counts <- counts[keep, , drop = FALSE]
gr <- gr[keep]
annotations <- annotations[keep, , drop = FALSE]

se <- SummarizedExperiment(
    assays = list(counts = counts),
    rowRanges = gr,
    colData = DataFrame(sample = colnames(counts), row.names = colnames(counts))
)

fa <- FaFile(opt$fasta)
se <- addGCBias(se, genome = fa)

bg <- getBackgroundPeaks(se, niterations = opt$background_peaks)
dev <- computeDeviations(object = se, annotations = annotations, background_peaks = bg)

motif_ids <- rownames(assay(dev, "deviations"))
motif_names <- motif_ids

write_long_matrix <- function(mat, value_name, path) {
    row_ids <- rownames(mat)
    out <- data.frame(
        motif_id = rep(row_ids, times = ncol(mat)),
        motif_name = rep(motif_names[match(row_ids, motif_ids)], times = ncol(mat)),
        sample = rep(colnames(mat), each = nrow(mat)),
        value = as.vector(mat),
        check.names = FALSE
    )
    colnames(out)[4] <- value_name
    write.table(out, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

deviation_matrix <- assay(dev, "deviations")
z_matrix <- assay(dev, "z")

write_long_matrix(deviation_matrix, "deviation", paste0(opt$out_prefix, ".chromvar_deviations.tsv"))
write_long_matrix(z_matrix, "z", paste0(opt$out_prefix, ".chromvar_z.tsv"))

variability <- as.data.frame(computeVariability(dev))
variability$motif_id <- rownames(variability)
variability$motif_name <- motif_names[match(variability$motif_id, motif_ids)]
if ("p_value" %in% colnames(variability)) {
    variability$padj <- p.adjust(variability$p_value, method = "BH")
} else if ("p.value" %in% colnames(variability)) {
    variability$padj <- p.adjust(variability$p.value, method = "BH")
} else {
    variability$padj <- NA_real_
}
variability <- variability[, c("motif_id", "motif_name", setdiff(colnames(variability), c("motif_id", "motif_name"))), drop = FALSE]
write.table(variability, paste0(opt$out_prefix, ".chromvar_variability.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

pca_input <- t(z_matrix)
pca_input[!is.finite(pca_input)] <- 0
pca <- prcomp(pca_input, center = TRUE, scale. = FALSE)
pca_df <- data.frame(sample = rownames(pca$x), pca$x[, seq_len(min(5, ncol(pca$x))), drop = FALSE], check.names = FALSE)
write.table(pca_df, paste0(opt$out_prefix, ".chromvar_pca.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

saveRDS(
    list(
        counts = se,
        motif_matches = annotations,
        background_peaks = bg,
        deviations = dev,
        variability = variability,
        pca = pca_df
    ),
    paste0(opt$out_prefix, ".chromvar.rds")
)
