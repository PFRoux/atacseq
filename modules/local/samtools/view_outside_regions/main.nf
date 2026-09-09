process SAMTOOLS_VIEW_OUTSIDE_REGIONS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::samtools=1.20"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_1' :
        'quay.io/biocontainers/samtools:1.20--h50ea8bc_1' }"

    input:
    tuple val(meta), path(bam), path(bai), path(regions)

    output:
    tuple val(meta), path("*.bam")    , emit: bam
    tuple val(meta), path("*.bam.bai"), emit: bai
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.outside_regions"
    """
    samtools view \\
        -b \\
        -L ${regions} \\
        -U ${prefix}.bam \\
        -o /dev/null \\
        ${bam}

    samtools index ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | sed -n '1s/^samtools //p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.outside_regions"
    """
    touch ${prefix}.bam ${prefix}.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.20
    END_VERSIONS
    """
}
