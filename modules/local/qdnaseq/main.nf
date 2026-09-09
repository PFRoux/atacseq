process QDNASEQ {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/bioconductor-qdnaseq:1.46.0--r45hdfd78af_0' :
        'quay.io/biocontainers/bioconductor-qdnaseq:1.46.0--r45hdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(bai), path(bins_rds), val(bin_size), val(loss_threshold), val(gain_threshold)

    output:
    tuple val(meta), path("*.qdnaseq.rds")         , emit: rds
    tuple val(meta), path("*.qdnaseq.bins.tsv")    , emit: bins
    tuple val(meta), path("*.qdnaseq.segments.tsv"), emit: segments, optional: true
    tuple val(meta), path("*.qdnaseq.calls.tsv")   , emit: calls, optional: true
    tuple val(meta), path("*.qdnaseq.pdf")         , emit: plots, optional: true
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    Rscript ${moduleDir}/resources/usr/bin/qdnaseq_run.R \\
        --bam ${bam} \\
        --bins-rds ${bins_rds} \\
        --bin-size ${bin_size} \\
        --loss-threshold ${loss_threshold} \\
        --gain-threshold ${gain_threshold} \\
        --out-prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        QDNAseq: \$(Rscript -e 'cat(as.character(utils::packageVersion("QDNAseq")))')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.qdnaseq.rds
    printf "chromosome\\tstart\\tend\\treads\\tlog2\\tcall\\nchr1\\t0\\t1\\t0\\t0\\tneutral\\n" > ${prefix}.qdnaseq.bins.tsv
    printf "chromosome\\tstart\\tend\\tlog2\\tcall\\nchr1\\t0\\t1\\t0\\tneutral\\n" > ${prefix}.qdnaseq.segments.tsv
    printf "chromosome\\tstart\\tend\\tlog2\\tcall\\nchr1\\t0\\t1\\t0\\tneutral\\n" > ${prefix}.qdnaseq.calls.tsv
    touch ${prefix}.qdnaseq.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        QDNAseq: 1.46.0
    END_VERSIONS
    """
}
