//
// Call super-enhancers with ROSE from merged library-level ATAC-seq BAMs.
//

include { GTF_TO_ROSE_ANNOTATION } from '../../../modules/local/gtf_to_rose_annotation'
include { ROSE                   } from '../../../modules/local/rose'
include { CONSENSUS_SUPER_ENHANCERS } from '../../../modules/local/consensus_super_enhancers'
include { BEDTOOLS_MULTICOV_COUNTS as SUPER_ENHANCERS_MULTICOV_COUNTS } from '../../../modules/local/bedtools/multicov_counts'

workflow BAM_SUPERENHANCER_ROSE {
    take:
    ch_peaks         // channel: [ val(meta), peaks ]
    ch_bam_bai       // channel: [ val(meta), bam, bai ] or [ val(meta), [bams], [bais] ] if controls are used
    ch_gtf           // channel: [ gtf ]
    ch_multicov_bams // channel: [ sample_names, bams, bais ]
    rose_stitch      // integer: ROSE stitching distance
    rose_tss         // integer: ROSE TSS exclusion distance

    main:
    ch_versions = channel.empty()

    GTF_TO_ROSE_ANNOTATION (
        ch_gtf
    )
    ch_versions = ch_versions.mix(GTF_TO_ROSE_ANNOTATION.out.versions)

    ch_bam_bai
        .map { meta, bam, bai ->
            def signal_bam = bam instanceof List ? bam[0] : bam
            def signal_bai = bai instanceof List ? bai[0] : bai
            [ meta, signal_bam, signal_bai ]
        }
        .set { ch_signal_bam_bai }

    ch_peaks
        .join(ch_signal_bam_bai, by: [0])
        .combine(GTF_TO_ROSE_ANNOTATION.out.annotation)
        .map { meta, peaks, bam, bai, annotation -> [ meta, peaks, bam, bai, annotation ] }
        .set { ch_rose_input }

    ROSE (
        ch_rose_input,
        rose_stitch,
        rose_tss
    )
    ch_versions = ch_versions.mix(ROSE.out.versions)

    ROSE
        .out
        .super_enhancers
        .map { _meta, table -> table }
        .collect()
        .filter { tables -> tables.size() > 0 }
        .map { tables -> [ [ id: 'consensus_super_enhancers' ], tables ] }
        .set { ch_super_enhancer_tables }

    CONSENSUS_SUPER_ENHANCERS (
        ch_super_enhancer_tables
    )
    ch_versions = ch_versions.mix(CONSENSUS_SUPER_ENHANCERS.out.versions)

    CONSENSUS_SUPER_ENHANCERS
        .out
        .bed
        .combine(ch_multicov_bams)
        .map { meta, bed, sample_names, bams, bais -> [ meta, bed, sample_names, bams, bais ] }
        .set { ch_super_enhancer_counts_input }

    SUPER_ENHANCERS_MULTICOV_COUNTS (
        ch_super_enhancer_counts_input
    )
    ch_versions = ch_versions.mix(SUPER_ENHANCERS_MULTICOV_COUNTS.out.versions)

    emit:
    annotation       = GTF_TO_ROSE_ANNOTATION.out.annotation
    super_enhancers  = ROSE.out.super_enhancers
    all_enhancers    = ROSE.out.all_enhancers
    enhancers_bed    = ROSE.out.enhancers_bed
    super_genes      = ROSE.out.super_genes
    plot             = ROSE.out.plot
    consensus_bed    = CONSENSUS_SUPER_ENHANCERS.out.bed
    consensus_saf    = CONSENSUS_SUPER_ENHANCERS.out.saf
    raw_counts       = SUPER_ENHANCERS_MULTICOV_COUNTS.out.counts
    versions         = ch_versions
}
