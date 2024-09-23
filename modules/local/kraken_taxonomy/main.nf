process KRAKEN_TAXONOMY{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken:1.1.1--pl5321h9f5acd7_7' :
        'quay.io/biocontainers/kraken:1.1.1--pl5321h9f5acd7_7' }"
    tag "Download NCBI taxonomy"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"

    input:
        val(kmer)

    output:
        tuple path("Mito_db_kmer${kmer}"), val(kmer), emit: database
        tuple path("${dbname}/taxonomy/names.dmp"), path("${dbname}/taxonomy/nodes.dmp"), emit: nodes

    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        kraken-build --download-taxonomy --db ${dbname} --threads ${params.threads}
        """
}