process PARSE_NAMES{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    tag "Extract names from nodes"

    input:
        tuple path('names.dmp'),path('nodes.dmp')

    output:
        path("order_names.txt"), emit: orders
        path("family_names.txt"), emit: families

    script:
        """
        extract_names.py names.dmp nodes.dmp order
        extract_names.py names.dmp nodes.dmp family
        """
}