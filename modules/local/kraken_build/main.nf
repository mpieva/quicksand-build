process KRAKEN_BUILD{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krakenuniq:1.0.2--pl5321h19e8d03_0':
        'quay.io/biocontainers/krakenuniq:1.0.2--pl5321h19e8d03_0' }"
    tag "Index DB (Kmer ${kmer})"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"
    beforeScript 'ulimit -Ss unlimited'

    input:
        tuple path("Mito_db_kmer${kmer}"), val(kmer)
        path("*.fasta")
        path("krakenuniq.map")
        path(extra_genomes)

    output:
        path("Mito_db_kmer${kmer}"), emit: database
        //tuple path("seqid2taxid.map"), path("${dbname}/taxonomy/names.dmp"), val(kmer), emit: taxonomy

    script:
        dbname = "Mito_db_kmer${kmer}"
        extra_genomes_command = extra_genomes ? "cp ${extra_genomes}/* ${dbname}/library/" : ""

        """
        mkdir -p ${dbname}/library
        for fasta in *.fasta; do \
            mv \${fasta} ${dbname}/library;\
        done
        cp krakenuniq.map ${dbname}/library/

        $extra_genomes_command

        krakenuniq-build --db ${dbname} --kmer $kmer --threads ${params.threads} --taxids-for-genomes

        cut ${dbname}/seqid2taxid.map.orig -f 1,2 > seqid2taxid_correct.map
        mv seqid2taxid_correct.map ${dbname}/seqid2taxid.map
        """
}