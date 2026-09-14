nextflow.enable.dsl = 2

include { MGATK_CALL } from '../main.nf'

workflow {
    input = channel.of([
        [ id: 'test', single_end: false ],
        file("${projectDir}/modules/local/nucleoatac/tests/test.bam"),
        file("${projectDir}/modules/local/nucleoatac/tests/test.bam.bai"),
        file("${projectDir}/modules/local/nucleoatac/tests/test.fa")
    ])

    MGATK_CALL(input)
}
