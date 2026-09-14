#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { CHROMVAR } from '../main.nf'

workflow {
    ch_input = Channel.of([
        [ id:'consensus_peaks' ],
        file("$projectDir/../../../../tests/data/chromvar_counts.tsv", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_regions.bed", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_genome.fa", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_genome.fa.fai", checkIfExists: true),
        file("$projectDir/../../../../tests/data/tobias_motifs.jaspar", checkIfExists: true)
    ])

    CHROMVAR(ch_input)
}
