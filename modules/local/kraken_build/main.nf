process KRAKEN_BUILD{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krakenuniq:1.0.2--pl5321h19e8d03_0':
        'quay.io/biocontainers/krakenuniq:1.0.2--pl5321h19e8d03_0' }"
    tag "Index DB (Kmer ${kmer})"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"
    beforeScript 'ulimit -Ss unlimited'

    input:
        val(kmer)
        path("*.fasta")
        path("krakenuniq.map")
        tuple path(names), path(nodes)

    output:
        path("Mito_db_kmer${kmer}"), emit: database

    script:
        dbname = "Mito_db_kmer${kmer}"

        """
        mkdir -p ${dbname}/library
        mkdir -p ${dbname}/taxonomy

        cp ${names} ${dbname}/taxonomy/names.dmp
        cp ${nodes} ${dbname}/taxonomy/nodes.dmp

        for fasta in *.fasta; do \
            cp \${fasta} ${dbname}/library;\
        done
        cp krakenuniq.map ${dbname}/library/

        krakenuniq-build --db ${dbname} --kmer $kmer --threads ${params.threads}

        cut ${dbname}/seqid2taxid.map -f 1,2 > seqid2taxid_correct.map
        mv seqid2taxid_correct.map ${dbname}/seqid2taxid.map
        """
}
