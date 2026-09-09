process TELOMEREHUNTER2 {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://fpopp22/telomerehunter2:latest' :
        'fpopp22/telomerehunter2:latest' }"

    input:
    tuple val(meta), path(bam), path(bai), path(cytoband), val(fast_mode), val(plot_none), val(repeats), val(repeats_context)

    output:
    tuple val(meta), path("*.telomerehunter2.summary.tsv")          , emit: summary, optional: true
    tuple val(meta), path("*.telomerehunter2.TVR_top_contexts.tsv") , emit: tvr_top_contexts, optional: true
    tuple val(meta), path("*.telomerehunter2.singletons.tsv")       , emit: singletons, optional: true
    tuple val(meta), path("*.telomerehunter2.files.txt")            , emit: file_index
    tuple val(meta), path("*.telomerehunter2")                      , emit: outdir
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cytoband_arg = cytoband ? "-b ${cytoband}" : ''
    def fast_mode_arg = fast_mode ? '--fast_mode' : ''
    def plot_arg = plot_none ? '--plotNone' : ''
    def repeats_arg = repeats ? "--repeats ${repeats.toString().tokenize(',').collect { it.trim() }.findAll { it }.join(' ')}" : ''
    def repeats_context_arg = repeats_context ? "--repeatsContext ${repeats_context.toString().tokenize(',').collect { it.trim() }.findAll { it }.join(' ')}" : ''
    """
    ln -s $bam ${prefix}.bam
    if [[ "$bai" == *.csi ]]; then
        ln -s $bai ${prefix}.bam.csi
    else
        ln -s $bai ${prefix}.bam.bai
    fi

    telomerehunter2 \\
        -ibt ${prefix}.bam \\
        -o ${prefix}.telomerehunter2 \\
        -p ${prefix} \\
        -c ${task.cpus} \\
        $cytoband_arg \\
        $fast_mode_arg \\
        $plot_arg \\
        $repeats_arg \\
        $repeats_context_arg \\
        $args

    find ${prefix}.telomerehunter2 -type f | sort > ${prefix}.telomerehunter2.files.txt
    find ${prefix}.telomerehunter2 -name summary.tsv -exec cp {} ${prefix}.telomerehunter2.summary.tsv \\; -quit
    find ${prefix}.telomerehunter2 -name TVR_top_contexts.tsv -exec cp {} ${prefix}.telomerehunter2.TVR_top_contexts.tsv \\; -quit
    find ${prefix}.telomerehunter2 -name singletons.tsv -exec cp {} ${prefix}.telomerehunter2.singletons.tsv \\; -quit

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        telomerehunter2: \$(python -c 'import importlib.metadata; print(importlib.metadata.version("telomerehunter2"))')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}.telomerehunter2/plots
    printf "PID\\tsample\\ttel_content\\ttotal_reads\\tintratelomeric_reads\\n${prefix}\\ttumor\\t0\\t0\\t0\\n" > ${prefix}.telomerehunter2/summary.tsv
    printf "repeat\\tcount\\nTTAGGG\\t0\\n" > ${prefix}.telomerehunter2/TVR_top_contexts.tsv
    printf "repeat\\tcount\\nTTAGGG\\t0\\n" > ${prefix}.telomerehunter2/singletons.tsv
    find ${prefix}.telomerehunter2 -type f | sort > ${prefix}.telomerehunter2.files.txt
    cp ${prefix}.telomerehunter2/summary.tsv ${prefix}.telomerehunter2.summary.tsv
    cp ${prefix}.telomerehunter2/TVR_top_contexts.tsv ${prefix}.telomerehunter2.TVR_top_contexts.tsv
    cp ${prefix}.telomerehunter2/singletons.tsv ${prefix}.telomerehunter2.singletons.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        telomerehunter2: 1.0.11
    END_VERSIONS
    """
}
