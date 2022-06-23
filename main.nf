#!/usr/bin/env nextflow

red = "\033[0;31m"
white = "\033[0m"
cyan = "\033[0;36m"
yellow = "\033[0;33m"


//
//
// Help
//
//

params.help = false
if (params.help || params.outdir == false ) {
    print file("$baseDir/assets/help.txt").text
    exit 0
}
kmers = Channel.from(params.kmers.toString().split(','))
params.exclude = ''

exclude = params.exclude ? Channel.fromPath("${params.exclude}", type:'file') : Channel.from('None')


//
//
// The Pipeline
//
//


process downloadTaxonomy{
    tag "Download NCBI taxonomy"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"

    input:
        each kmer from kmers 
    
    output:
        tuple "Mito_db_kmer${kmer}", kmer into kraken_db
        file "orders.txt" into orders
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        kraken-build --download-taxonomy --db ${dbname}
        extract_orders.py $dbname/taxonomy/names.dmp $dbname/taxonomy/nodes.dmp
        """ 
}


process downloadGenomes{
    publishDir "${params.outdir}/ncbi", mode: 'copy'
    tag "Downloading..."

    output:
        file '*.gz' into downloaded_genomes

    script:
        """
        rsync -av rsync://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/*.genomic.gbff.gz .
        """
}

process extractFamilies{
    tag "Extracting..."

    input:
        file genome from downloaded_genomes
        file ex from exclude
        file 'orders.txt' from orders

    output:
        file "*.fasta" into extracted_fasta mode flatten
        file "*.tsv" into convert_acc

    script:
        if(! params.exclude){
            ex = 'None'
        }
        """
        python3 $baseDir/bin/extract_families.py orders.txt $ex $genome
        """
}

extracted_fasta
    .map{[it.baseName.split("_")[0],it.baseName.split('_')[1..2].join("_"), it.baseName.split("_")[3..-1].join("_"), file(it)]}
    .set{extracted_fasta}


process writeFastas{
    publishDir "${params.outdir}/genomes/${family}/", saveAs: {"${species}.fasta"}, pattern: "*.fasta", mode:'copy'
    tag "Writing $family:$species"
    
    input:
        set family, accession, species, "input.fasta" from extracted_fasta

    output:
        set family, species, "${species}.fasta" into (for_bed, for_bwa, for_kraken)
    
    script:
        """
        cat input.fasta > "${species}.fasta"
        """
}

process indexFasta{
    publishDir "${params.outdir}/genomes/${family}/", mode: 'copy'
    tag "$family:$species"
    
    input:
        set family, species, "${species}.fasta" from for_bwa

    output:
        file "${species}.fasta.*"
   
    script:
        """
        bwa index "${species}.fasta"
        """
}

process writeBedFiles{
    publishDir "${params.outdir}/masked/", saveAs: {"${species}.masked.bed"}, mode:'copy'
    tag "$family:$species"

    input:
        set family, species, "${species}.fasta" from for_bed

    output:
        file "${species}.masked.bed"

    script:
        """
        dustmasker -in "${species}.fasta" -outfmt acclist | \
        python3 $baseDir/bin/dustmasker_interval_to_bed.py \
        > "${species}.masked.bed";
        """
}

for_kraken
    .map{it[2]}
    .toList()
    .set{for_kraken}

process createKrakenDB{
    tag "Create KrakenDB: Kmer ${kmer}"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"
    beforeScript 'ulimit -Ss unlimited'

    input:
        tuple file(db), kmer from kraken_db
        file "*.fasta" from for_kraken
    
    output:
        file "Mito_db_kmer${kmer}"
        set "nucl_gb.accession2taxid", "names_dict.json" into taxid_map
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        for fasta in *.fasta; do \
            kraken-build --add-to-library \${fasta} --db ${dbname};\
            done
            kraken-build --build --db ${dbname} --kmer $kmer
        cp $dbname/taxonomy/nucl_gb.accession2taxid .
        python3 $baseDir/bin/parse_names.py $dbname/taxonomy/names.dmp
        """
}


process createFileMap{
    publishDir "${params.outdir}/genomes", mode:'copy'
    
    input:
        file "acc_map.tsv" from convert_acc
        set "nucl_gb.accession2taxid", "names_dict.json" from taxid_map

    output:
        file "*.tsv" 

    script:
        """ 
        python3 $baseDir/bin/convert_acc_to_taxid.py acc_map.tsv nucl_gb.accession2taxid names_dict.json
        """
}

