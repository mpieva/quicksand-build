process WRITE_FASTA{
    publishDir "${params.outdir}/genomes/${family}/", saveAs: {"${species}.fasta"}, pattern: "*.fasta", mode:'copy'
    tag "Writing $family:$species"

    input:
        tuple val(family), val(species), path("input.fasta")

    output:
        tuple val(family), val(species), path("*.fasta"), emit: fasta

    script:
        """
        cp input.fasta "${species}.fasta"
        """
}