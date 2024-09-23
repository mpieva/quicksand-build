process WRITE_BEDFILES{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    publishDir "${params.outdir}/masked/", saveAs: {"${species}.masked.bed"}, mode:'copy'
    tag "$family:$species"

    input:
        tuple val(family), val(species), path("acclist.txt")

    output:
        path("${species}.masked.bed"), emit: bed

    script:
        """
        cat acclist.txt | \
        python3 dustmasker_interval_to_bed.py \
        > "${species}.masked.bed";
        """
}