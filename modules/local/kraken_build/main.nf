process KRAKEN_BUILD{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken:1.1.1--pl5321h9f5acd7_7' :
        'quay.io/biocontainers/kraken:1.1.1--pl5321h9f5acd7_7' }"
    tag "Create KrakenDB: Kmer ${kmer}"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"
    beforeScript 'ulimit -Ss unlimited'

    input:
        tuple path("Mito_db_kmer${kmer}"), val(kmer)
        path("*.fasta")

    output:
        path("Mito_db_kmer${kmer}"), emit: database
        tuple path("nucl_gb.accession2taxid"), path("${dbname}/taxonomy/names.dmp"), val(kmer), emit: taxonomy

    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        for fasta in *.fasta; do \
            kraken-build --add-to-library \${fasta} --db ${dbname};\
            done
            kraken-build --build --db ${dbname} --kmer $kmer --threads ${params.threads}
        cp $dbname/taxonomy/nucl_gb.accession2taxid .
        """
}