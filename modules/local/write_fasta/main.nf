process WRITE_FASTA{
    publishDir "${params.outdir}/genomes/${family}/", saveAs: {"${species}.fasta"}, pattern: "*.fasta", mode:'copy'
    tag "Writing $family:$species"

    input:
        tuple val(family), val(accession), val(species), path("input.fasta")

    output:
        tuple val(family), val(species), path("${species}.fasta"), emit: fasta

    script:
        """
        cat input.fasta > "${species}.fasta"
        """
}