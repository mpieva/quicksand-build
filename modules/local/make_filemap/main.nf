process MAKE_FILEMAP{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    publishDir "${params.outdir}/genomes", mode:'copy'

    input:
        path("acc_map.tsv")
        tuple path("nucl_gb.accession2taxid"), path("names_dict.json")

    output:
        path("*.tsv")

    script:
        """
        convert_acc_to_taxid.py acc_map.tsv nucl_gb.accession2taxid names_dict.json
        """
}