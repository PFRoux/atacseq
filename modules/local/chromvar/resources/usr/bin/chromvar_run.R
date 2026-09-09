#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(optparse)
    library(GenomicRanges)
    library(SummarizedExperiment)
    library(Rsamtools)
    library(TFBSTools)
    library(motifmatchr)
    library(chromVAR)
})

option_list <- list(
    make_option("--counts", type = "character"),
    make_option("--regions", type = "character"),
    make_option("--fasta", type = "character"),
    make_option("--motifs", type = "character"),
    make_option("--out-prefix", type = "character", default = "chromvar"),
    make_option("--min-counts", type = "integer", default = 1),
    make_option("--min-samples", type = "integer", default = 1),
    make_option("--background-peaks", type = "integer", default = 50),
    make_option("--motif-p-cutoff", type = "double", default = 5e-05)
)
opt <- parse_args(OptionParser(option_list = option_list))

required <- c("counts", "regions", "fasta", "motifs")
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
regions <- counts_input$tab

gr <- GRanges(
    seqnames = regions$chrom,
    ranges = IRanges(start = as.integer(regions$start) + 1L, end = as.integer(regions$end)),
    region_id = rownames(counts_input$counts)
)

keep <- width(gr) > 0 &
    rowSums(counts_input$counts, na.rm = TRUE) >= opt$`min-counts` &
    rowSums(counts_input$counts > 0, na.rm = TRUE) >= opt$`min-samples`

if (sum(keep) < 2) {
    stop("Fewer than two peaks remain after chromVAR filtering.", call. = FALSE)
}

counts <- counts_input$counts[keep, , drop = FALSE]
gr <- gr[keep]

se <- SummarizedExperiment(
    assays = list(counts = counts),
    rowRanges = gr,
    colData = DataFrame(sample = colnames(counts), row.names = colnames(counts))
)

fa <- FaFile(opt$fasta)
se <- addGCBias(se, genome = fa)

motifs <- readJASPARMatrix(opt$motifs, matrixClass = "PFM")
if (length(motifs) == 0) {
    stop("No motifs were parsed from the JASPAR motif file.", call. = FALSE)
}

motif_ix <- matchMotifs(motifs, se, genome = fa, out = "matches", p.cutoff = opt$`motif-p-cutoff`)
bg <- getBackgroundPeaks(se, niterations = opt$`background-peaks`)
dev <- computeDeviations(object = se, annotations = motif_ix, background_peaks = bg)

input_motif_ids <- vapply(motifs, TFBSTools::ID, character(1))
input_motif_names <- vapply(
    motifs,
    function(motif) {
        value <- tryCatch(TFBSTools::name(motif), error = function(e) "")
        if (!nzchar(value)) {
            value <- TFBSTools::ID(motif)
        }
        value
    },
    character(1)
)
motif_ids <- rownames(assay(dev, "deviations"))
motif_names <- input_motif_names[match(motif_ids, input_motif_ids)]
motif_names[is.na(motif_names) | motif_names == ""] <- motif_ids[is.na(motif_names) | motif_names == ""]

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

write_long_matrix(deviation_matrix, "deviation", paste0(opt$`out-prefix`, ".chromvar_deviations.tsv"))
write_long_matrix(z_matrix, "z", paste0(opt$`out-prefix`, ".chromvar_z.tsv"))

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
write.table(variability, paste0(opt$`out-prefix`, ".chromvar_variability.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

pca_input <- t(z_matrix)
pca_input[!is.finite(pca_input)] <- 0
pca <- prcomp(pca_input, center = TRUE, scale. = FALSE)
pca_df <- data.frame(sample = rownames(pca$x), pca$x[, seq_len(min(5, ncol(pca$x))), drop = FALSE], check.names = FALSE)
write.table(pca_df, paste0(opt$`out-prefix`, ".chromvar_pca.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

saveRDS(
    list(
        counts = se,
        motifs = motif_ix,
        background_peaks = bg,
        deviations = dev,
        variability = variability,
        pca = pca_df
    ),
    paste0(opt$`out-prefix`, ".chromvar.rds")
)
