#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { CHROMVAR } from '../main.nf'

workflow {
    ch_input = Channel.of([
        [ id:'consensus_peaks' ],
        file("$projectDir/../../../../tests/data/chromvar_counts.tsv", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_matches.mtx", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_motif_peaks.tsv", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_motif_ids.tsv", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_genome.fa", checkIfExists: true),
    ])

    CHROMVAR(ch_input)
}
