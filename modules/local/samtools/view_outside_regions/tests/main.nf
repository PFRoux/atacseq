#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { SAMTOOLS_VIEW_OUTSIDE_REGIONS } from '../main.nf'

workflow {
    input = Channel.of([
        [ id:'test', single_end:false ],
        file("$projectDir/../../../nucleoatac/tests/test.bam", checkIfExists: true),
        file("$projectDir/../../../nucleoatac/tests/test.bam.bai", checkIfExists: true),
        file("$projectDir/../../../nucleoatac/tests/test.bed", checkIfExists: true)
    ])

    SAMTOOLS_VIEW_OUTSIDE_REGIONS(input)
}
