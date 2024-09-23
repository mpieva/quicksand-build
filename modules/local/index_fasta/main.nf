process INDEX_FASTA{
    container (workflow.containerEngine ? "merszym/network-aware-bwa:v0.5.10" : null)
    publishDir "${params.outdir}/genomes/${family}/", mode: 'copy'
    tag "$family:$species"

    input:
        tuple val(family), val(species), path("${species}.fasta")

    output:
        path("${species}.fasta.*")

    script:
        """
        bwa index "${species}.fasta"
        """
}