process DEEPTOOLS_BAMCOVERAGE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0':
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(index)
    val effective_genome_size
    val normalization
    val bin_size
    val smooth_length
    val fragment_size

    output:
    tuple val(meta), path("*.bigWig"), emit: bigwig
    path  "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def norm       = normalization ?: 'CPM'
    def smooth     = smooth_length ? "--smoothLength ${smooth_length}" : ''
    def egs        = norm == 'RPGC' ? "--effectiveGenomeSize ${effective_genome_size}" : ''
    def extend     = meta.single_end ? ((fragment_size as Integer) > 0 ? "--extendReads ${fragment_size}" : '') : '--extendReads'
    """
    if [ "${norm}" = "RPGC" ] && [ -z "${effective_genome_size}" ]; then
        echo "ERROR: --bamcoverage_normalization RPGC requires --macs_gsize or an iGenomes effective genome size." >&2
        exit 1
    fi

    bamCoverage \\
        --bam $bam \\
        --outFileName ${prefix}.bigWig \\
        --outFileFormat bigwig \\
        --numberOfProcessors $task.cpus \\
        --binSize ${bin_size} \\
        --normalizeUsing ${norm} \\
        $egs \\
        $smooth \\
        $extend \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(bamCoverage --version | sed -e "s/bamCoverage //g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bigWig

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$(bamCoverage --version | sed -e "s/bamCoverage //g")
    END_VERSIONS
    """
}
