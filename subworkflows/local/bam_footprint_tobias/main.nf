//
// Correct Tn5 insertion bias and score motif footprints with TOBIAS.
//

include { TOBIAS_ATACORRECT  } from '../../../modules/local/tobias/atacorrect'
include { TOBIAS_SCOREBIGWIG } from '../../../modules/local/tobias/scorebigwig'
include { TOBIAS_BINDETECT   } from '../../../modules/local/tobias/bindetect'

workflow BAM_FOOTPRINT_TOBIAS {
    take:
    ch_bam_bai        // channel: [ val(meta), bam, bai ]
    ch_consensus_bed  // channel: [ val(meta), bed ]
    ch_fasta          // channel: [ fasta ]
    ch_motifs         // channel: [ motifs ]

    main:
    ch_versions = channel.empty()

    ch_consensus_bed
        .map { _meta, bed -> bed }
        .set { ch_consensus_bed_file }

    ch_bam_bai
        .combine(ch_consensus_bed_file)
        .map { meta, bam, bai, bed -> [ meta, bam, bai, bed ] }
        .set { ch_atacorrect_input }

    TOBIAS_ATACORRECT (
        ch_atacorrect_input,
        ch_fasta
    )
    ch_versions = ch_versions.mix(TOBIAS_ATACORRECT.out.versions)

    TOBIAS_ATACORRECT
        .out
        .corrected
        .combine(ch_consensus_bed_file)
        .map { meta, corrected, bed -> [ meta, corrected, bed ] }
        .set { ch_scorebigwig_input }

    TOBIAS_SCOREBIGWIG (
        ch_scorebigwig_input
    )
    ch_versions = ch_versions.mix(TOBIAS_SCOREBIGWIG.out.versions)

    TOBIAS_SCOREBIGWIG
        .out
        .footprints
        .collect(flat: false)
        .filter { rows -> rows.size() > 0 }
        .map { rows ->
            def sorted = rows.sort { a, b -> a[0].id <=> b[0].id }
            def footprints = sorted.collect { it[1] }
            def cond_names = sorted.collect { it[0].id }.join(' ')
            [ [ id: 'all_samples' ], footprints, cond_names ]
        }
        .set { ch_bindetect_input }

    TOBIAS_BINDETECT (
        ch_bindetect_input,
        ch_motifs,
        ch_fasta,
        ch_consensus_bed
    )
    ch_versions = ch_versions.mix(TOBIAS_BINDETECT.out.versions)

    emit:
    corrected    = TOBIAS_ATACORRECT.out.corrected
    expected     = TOBIAS_ATACORRECT.out.expected
    uncorrected  = TOBIAS_ATACORRECT.out.uncorrected
    bias         = TOBIAS_ATACORRECT.out.bias
    footprints   = TOBIAS_SCOREBIGWIG.out.footprints
    outdir       = TOBIAS_BINDETECT.out.outdir
    versions     = ch_versions
}
