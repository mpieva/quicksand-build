process PREPARE_TAXONOMY{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    tag "Parse Taxonomy: Kmer ${kmer}"

    input:
        tuple path("nucl_gb.accession2taxid"), path("names.dmp"), val(kmer)

    output:
        tuple path("nucl_gb.accession2taxid"), path("names_dict.json"), emit: json

    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        parse_names.py names.dmp
        """
}