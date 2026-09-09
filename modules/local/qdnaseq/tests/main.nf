#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { QDNASEQ } from '../main.nf'

workflow {
    input = Channel.of([
        [ id:'test', single_end:false ],
        file("$projectDir/../../nucleoatac/tests/test.bam", checkIfExists: true),
        file("$projectDir/../../nucleoatac/tests/test.bam.bai", checkIfExists: true),
        file("$projectDir/test_bins.rds", checkIfExists: true),
        1000,
        -0.4,
        0.4
    ])

    QDNASEQ(input)
}
