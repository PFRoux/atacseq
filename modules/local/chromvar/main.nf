process CHROMVAR {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] ?
        'docker://quay.io/biocontainers/bioconductor-chromvar:1.32.0--r45ha27e39d_0' :
        'quay.io/biocontainers/bioconductor-chromvar:1.32.0--r45ha27e39d_0' }"

    input:
    tuple val(meta), path(counts), path(matches), path(motif_peaks), path(motif_ids), path(fasta)

    output:
    tuple val(meta), path("*.chromvar_deviations.tsv") , emit: deviations
    tuple val(meta), path("*.chromvar_z.tsv")          , emit: z
    tuple val(meta), path("*.chromvar_variability.tsv"), emit: variability
    tuple val(meta), path("*.chromvar_pca.tsv")        , emit: pca
    tuple val(meta), path("*.chromvar.rds")            , emit: rds
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ''
    """
    Rscript ${moduleDir}/resources/usr/bin/chromvar_run.R \\
        --counts ${counts} \\
        --matches ${matches} \\
        --motif-peaks ${motif_peaks} \\
        --motif-ids ${motif_ids} \\
        --fasta ${fasta} \\
        --out-prefix ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chromvar: \$(Rscript -e 'cat(as.character(utils::packageVersion("chromVAR")))')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    printf "motif_id\\tmotif_name\\tsample\\tdeviation\\nMA0001.1\\tstub_motif\\tstub_sample\\t0\\n" > ${prefix}.chromvar_deviations.tsv
    printf "motif_id\\tmotif_name\\tsample\\tz\\nMA0001.1\\tstub_motif\\tstub_sample\\t0\\n" > ${prefix}.chromvar_z.tsv
    printf "motif_id\\tmotif_name\\tvariability\\tp_value\\tpadj\\nMA0001.1\\tstub_motif\\t0\\t1\\t1\\n" > ${prefix}.chromvar_variability.tsv
    printf "sample\\tPC1\\tPC2\\n\\t0\\t0\\n" > ${prefix}.chromvar_pca.tsv
    touch ${prefix}.chromvar.rds

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chromvar: 1.32.0
    END_VERSIONS
    """
}
