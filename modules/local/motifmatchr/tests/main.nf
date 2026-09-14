#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { MOTIFMATCHR_MATCHMOTIFS } from '../main.nf'

workflow {
    ch_input = Channel.of([
        [ id: 'consensus_peaks' ],
        file("$projectDir/../../../../tests/data/chromvar_regions.bed", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_genome.fa", checkIfExists: true),
        file("$projectDir/../../../../tests/data/tobias_motifs.jaspar", checkIfExists: true)
    ])

    MOTIFMATCHR_MATCHMOTIFS(ch_input)
}
