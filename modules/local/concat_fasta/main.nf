process CONCAT_FASTA{
    tag "Concat ${taxid} | ${taxonomy.species}"

    input:
        tuple path(fasta), val(taxid), val(taxonomy)

    output:
        tuple path("${taxid}.fasta"), val(taxid), val(taxonomy), emit: fasta

    script:
        """
        cat *.fasta > "${taxid}.fasta"
        """
}