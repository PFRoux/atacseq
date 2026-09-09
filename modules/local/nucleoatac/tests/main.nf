#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { NUCLEOATAC } from '../main.nf'

workflow {
    input = Channel.of([
        [ id:'test', single_end:false ],
        file("$projectDir/test.bam", checkIfExists: true),
        file("$projectDir/test.bam.bai", checkIfExists: true),
        file("$projectDir/test.bed", checkIfExists: true),
        file("$projectDir/test.fa", checkIfExists: true),
        file("$projectDir/test.fa.fai", checkIfExists: true)
    ])

    NUCLEOATAC(input)
}
