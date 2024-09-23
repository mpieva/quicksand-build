process RUN_DUSTMASKER{
    container (workflow.containerEngine ? "merszym/dustmasker:nextflow" : null)
    tag "$family:$species"

    input:
        tuple val(family), val(species), path("${species}.fasta")

    output:
        tuple val(family), val(species), path("acclist.txt"), emit: txt

    script:
        """
        dustmasker -in "${species}.fasta" -outfmt acclist > "acclist.txt"
        """
}