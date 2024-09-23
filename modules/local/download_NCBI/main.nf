process DOWNLOAD_NCBI{
    publishDir "${params.outdir}/ncbi", mode: 'copy'
    tag "Download RefSeq"

    output:
        path('*.gz'), emit: gbff

    script:
        """
        rsync -av rsync://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/*.genomic.gbff.gz .
        """
}