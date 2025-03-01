process KRAKEN_TAXONOMY{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krakenuniq:1.0.2--pl5321h19e8d03_0':
        'quay.io/biocontainers/krakenuniq:1.0.2--pl5321h19e8d03_0' }"
    tag "NCBI taxonomy"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"

    input:
        val(kmer)
        path("taxonomy")

    output:
        tuple path("Mito_db_kmer${kmer}"), val(kmer), emit: database
        tuple path("${dbname}/taxonomy/names.dmp"), path("${dbname}/taxonomy/nodes.dmp"), emit: taxonomy

    script:
        dbname = "Mito_db_kmer${kmer}"
        if(taxonomy){ // if we provide a custom taxonomy
            """
            mkdir -p ${dbname}/taxonomy
            cp ${taxonomy}/* ${dbname}/taxonomy/
            """
        } else {
            """
            krakenuniq-build --download-taxonomy --db ${dbname} --threads ${params.threads}
            """
        }
}