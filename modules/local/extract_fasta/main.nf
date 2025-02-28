process EXTRACT_FASTA{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.78' :
        'quay.io/biocontainers/biopython:1.78' }"
    tag "Extract RefSeq"

    input:
        tuple val(include), val(exclude)
        path(genome)
        path('orders.txt')
        path('families.txt')

    output:
        path("*.fasta"), emit: fasta
        path("*.tsv"), emit: tsv
        path("*.map"), emit: krakenuniq_map

    script:
        """
        extract_families.py ${include} orders.txt ${exclude} families.txt ${genome}
        """
}