process NUCLEOATAC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/nucleoatac:0.3.4--py27h984c793_7' :
        'quay.io/biocontainers/nucleoatac:0.3.4--py27h984c793_7' }"

    input:
    tuple val(meta), path(bam), path(bai), path(bed), path(fasta), path(fai)

    output:
    tuple val(meta), path("*.nucpos.bed.gz")                         , emit: nucpos, optional: true
    tuple val(meta), path("*.nucpos.redundant.bed.gz")               , emit: nucpos_redundant, optional: true
    tuple val(meta), path("*.nfrpos.bed.gz")                         , emit: nfrpos, optional: true
    tuple val(meta), path("*.nucmap_combined.bed.gz")                , emit: nucmap_combined, optional: true
    tuple val(meta), path("*.occpeaks.bed.gz")                       , emit: occpeaks, optional: true
    tuple val(meta), path("*.occ.bedgraph.gz")                       , emit: occupancy, optional: true
    tuple val(meta), path("*.occ.lower_bound.bedgraph.gz")           , emit: occupancy_lower_bound, optional: true
    tuple val(meta), path("*.occ.upper_bound.bedgraph.gz")           , emit: occupancy_upper_bound, optional: true
    tuple val(meta), path("*.nucleoatac_signal.bedgraph.gz")         , emit: signal, optional: true
    tuple val(meta), path("*.nucleoatac_signal.smooth.bedgraph.gz")  , emit: signal_smooth, optional: true
    tuple val(meta), path("*.fragmentsizes.txt")                     , emit: fragment_sizes, optional: true
    tuple val(meta), path("*.nuc_dist.txt")                          , emit: nuc_dist, optional: true
    tuple val(meta), path("*.VMat")                                  , emit: vmat, optional: true
    tuple val(meta), path("*.eps")                                   , emit: plots, optional: true
    path "versions.yml"                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ln -s $bam ${prefix}.bam
    if [[ "$bai" == *.csi ]]; then
        ln -s $bai ${prefix}.bam.csi
    else
        ln -s $bai ${prefix}.bam.bai
    fi

    nucleoatac run \\
        --bed $bed \\
        --bam ${prefix}.bam \\
        --fasta $fasta \\
        --out ${prefix} \\
        --cores ${task.cpus} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nucleoatac: \$(python -c 'import pkg_resources; print(pkg_resources.get_distribution("NucleoATAC").version)')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf "chr1\\t0\\t1\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\n" | gzip -c > ${prefix}.nucpos.bed.gz
    printf "chr1\\t0\\t1\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\t0\\n" | gzip -c > ${prefix}.nucpos.redundant.bed.gz
    printf "chr1\\t0\\t1\\t0\\t0\\t0\\t0\\n" | gzip -c > ${prefix}.nfrpos.bed.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.nucmap_combined.bed.gz
    printf "chr1\\t0\\t1\\t0\\t0\\t0\\t0\\n" | gzip -c > ${prefix}.occpeaks.bed.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.occ.bedgraph.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.occ.lower_bound.bedgraph.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.occ.upper_bound.bedgraph.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.nucleoatac_signal.bedgraph.gz
    printf "chr1\\t0\\t1\\t0\\n" | gzip -c > ${prefix}.nucleoatac_signal.smooth.bedgraph.gz
    printf "insert_size\\tcount\\n150\\t1\\n" > ${prefix}.fragmentsizes.txt
    printf "insert_size\\tdensity\\n150\\t1\\n" > ${prefix}.nuc_dist.txt
    printf "position\\tsignal\\n0\\t0\\n" > ${prefix}.VMat
    touch ${prefix}.nuc_dist.eps ${prefix}.occ_fit.eps

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nucleoatac: 0.3.4
    END_VERSIONS
    """
}
