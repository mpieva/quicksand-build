#!/usr/bin/env nextflow

params.kraken   =   ""
params.outdir   =   "."


process downloadGenomes{
    publishDir "${params.outdir}/Downloads", mode: 'link'

    output:
        file "*.gbff.gz" into downloaded_genomes

    script:
        """
        rsync -av rsync://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/*.genomic.gbff.gz .

        """
}

process extractFamilies{
    conda "$baseDir/envs/environment.yml"
    publishDir "${params.outdir}/Database/${stdout}/"

    input:
        file "genome.gbff.gz" from downloaded_genomes

    output:
        set "species.fasta", stdout into extracted_fasta

    script:
        """
        python3 $baseDir/scripts/extract_families.py genome.gbff.gz
        """
}
