#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { TELOMEREHUNTER2 } from '../main.nf'

workflow {
    input = Channel.of([
        [ id: 'test' ],
        file("$projectDir/../../../../tests/data/chromvar_genome.fa", checkIfExists: true),
        file("$projectDir/../../../../tests/data/chromvar_genome.fa.fai", checkIfExists: true),
        [],
        true,
        true,
        '',
        ''
    ])

    TELOMEREHUNTER2(input)
}
