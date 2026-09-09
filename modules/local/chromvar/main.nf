process CHROMVAR {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-chromvar:1.28.0--r44hdfd78af_0' :
        'biocontainers/bioconductor-chromvar:1.28.0--r44hdfd78af_0' }"

    input:
    tuple val(meta), path(counts), path(regions), path(fasta), path(fai), path(motifs), val(min_counts), val(min_samples), val(background_peaks), val(motif_p_cutoff)

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
    """
    Rscript ${moduleDir}/resources/usr/bin/chromvar_run.R \\
        --counts ${counts} \\
        --regions ${regions} \\
        --fasta ${fasta} \\
        --motifs ${motifs} \\
        --out-prefix ${prefix} \\
        --min-counts ${min_counts} \\
        --min-samples ${min_samples} \\
        --background-peaks ${background_peaks} \\
        --motif-p-cutoff ${motif_p_cutoff}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chromvar: \$(Rscript -e 'cat(as.character(utils::packageVersion("chromVAR")))')
        motifmatchr: \$(Rscript -e 'cat(as.character(utils::packageVersion("motifmatchr")))')
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
        chromvar: 1.28.0
        motifmatchr: 1.28.0
    END_VERSIONS
    """
}
