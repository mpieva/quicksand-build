#!/usr/bin/env nextflow

params.kraken   =   "/home/merlin_szymanski/Kraken/install/"
params.kmers    =   ["22"]
params.outdir   =   "./out"


process downloadGenomes{
    publishDir "${params.outdir}/Downloads", mode: 'link'
    tag "Downloading..."

    output:
        file '*.gz' into downloaded_genomes

    script:
        """
        rsync -av rsync://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/*.genomic.gbff.gz .

        """
}

process extractFamilies{
    conda "$baseDir/envs/environment.yml"
    tag "Extracting..."

    input:
        file genome from downloaded_genomes

    output:
        file "*.fasta" into extracted_fasta mode flatten

    script:
        """
        python3 $baseDir/bin/extract_families.py $genome
        """
}

extracted_fasta
    .map{[it.baseName.split("_")[0], it.baseName.split("_")[1..2].join("_"), file(it)]}
    .set{extracted_fasta}


process writeFastas{
    publishDir "${params.outdir}/Database/genomes/${family}/", saveAs: {"${species}.fasta"}
    tag "$family:$species"
    
    input:
        set family, species, file(fasta) from extracted_fasta

    output:
        set family, species, file(fasta) into (for_bed, for_kraken)

    script:
        """
        touch "$fasta"
        """
}

process writeBedFiles{
    publishDir "${params.outdir}/Database/masked/${family}/", saveAs: {"${species}.masked.bed"}
    tag "$family:$species"

    input:
        set family, species, "species.fasta" from for_bed

    output:
        file "species.masked.bed"

    script:
        """
        dustmasker -in species.fasta -outfmt acclist | \
        python3 $baseDir/bin/dustmasker_interval_to_bed.py \
        > species.masked.bed;

        """
}

for_kraken
    .toList()
    .set{for_kraken}
    

process createKrakenDB{
    conda "$baseDir/envs/environment.yml"
    publishDir "${params.outdir}/Kraken/${dbname}", pattern: "*.{tmp, idx, kdb, txt}"
    publishDir "${params.outdir}/Kraken/${dbname}/taxonomy", pattern: "*.{dmp}"
    tag "THIS TAKES A LONG TIME"
    
    input:
        each kmer from params.kmers
        file fasta_list from for_kraken
    
    output:
        file "${dbname}/taxonomy/*.dmp"
	file "${dbname}/*.{tmp, idx, kdb, txt}"
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        ${params.kraken}/kraken-build --download-taxonomy --db ${dbname}
	for fasta in $fasta_list; \
		do file=\$(cut -f3 -d',' \$fasta);\
		${params.kraken}/kraken-build --add-to-library \${file%?} --db ${dbname};\
		done
        ${params.kraken}/kraken-build --build --db ${dbname} --kmer $kmer
        ${params.kraken}/kraken-build --clean --db ${dbname}
        find ${dbname} -type f -exec touch {} +
	"""
}

