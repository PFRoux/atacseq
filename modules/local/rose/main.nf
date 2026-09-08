process ROSE {
    tag "$meta.id"
    label 'process_medium'

    // ROSE is not available from Bioconda. The St. Jude Python 3-compatible
    // image bundles ROSE_main.py and its helper scripts.
    conda "${moduleDir}/environment.yml"
    container "ghcr.io/stjude/abralab/rose:v1.3.2"

    input:
    tuple val(meta), path(peaks), path(bam), path(bai), path(annotation)
    val stitch
    val tss_exclusion

    output:
    tuple val(meta), path("*_SuperStitched.table.txt")          , emit: super_enhancers, optional: true
    tuple val(meta), path("*_AllStitched.table.txt")            , emit: all_enhancers, optional: true
    tuple val(meta), path("*_Stitched_withSuper.bed")           , emit: enhancers_bed, optional: true
    tuple val(meta), path("*_SuperStitched.table_withGENES.txt"), emit: super_genes, optional: true
    tuple val(meta), path("*_Plot_points.png")                  , emit: plot, optional: true
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp -L $peaks ${prefix}_peaks.bed
    ln -s $bam ${prefix}.bam
    if [[ "$bai" == *.csi ]]; then
        ln -s $bai ${prefix}.bam.csi
    else
        ln -s $bai ${prefix}.bam.bai
    fi

    ROSE_main.py \\
        --custom $annotation \\
        -i ${prefix}_peaks.bed \\
        -r ${prefix}.bam \\
        -o . \\
        -s ${stitch} \\
        -t ${tss_exclusion} \\
        $args

    if [ ! -s ${prefix}_peaks_SuperStitched.table.txt ]; then
        echo "WARNING: ROSE produced no super-enhancer table for '${prefix}'. This can happen when too few stitched enhancers are available to fit the super-enhancer cutoff." >&2
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rose: \$(echo "\${ROSE_VERSION:-1.3.2}")
        python: \$(python3 --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_peaks_SuperStitched.table.txt
    touch ${prefix}_peaks_AllStitched.table.txt
    touch ${prefix}_peaks_Stitched_withSuper.bed
    touch ${prefix}_peaks_SuperStitched.table_withGENES.txt
    touch ${prefix}_peaks_Plot_points.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rose: 1.3.2
        python: 3.10.0
    END_VERSIONS
    """
}
