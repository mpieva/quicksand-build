#!/usr/bin/env nextflow

nextflow.enable.dsl = 1

red = "\033[0;31m"
white = "\033[0m"
cyan = "\033[0;36m"
yellow = "\033[0;33m"


log.info """
[quicksand-build]: Execution started: ${workflow.start.format('dd.MM.yyyy HH:mm')} ${cyan}

  =============================
  =  ================  =====  =
  =  =====  =  ==  ==  =====  =
  =    ===  =  ======  ===    =
  =  =  ==  =  ==  ==  ==  =  =
  =  =  ==  =  ==  ==  ==  =  =
  =  =  ==  =  ==  ==  ==  =  =
  =    ====    ==  ==  ===    =
  =============================

  ${white}${workflow.manifest.description} ${cyan}~ Version ${workflow.manifest.version} ${white}

 --------------------------------------------------------------
"""

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

// Parsing parameters

kmers = Channel.from(params.kmers.toString().split(','))

//
//
// The Pipeline
//
//


process downloadTaxonomy{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken:1.1.1--pl5321h9f5acd7_7' :
        'quay.io/biocontainers/kraken:1.1.1--pl5321h9f5acd7_7' }"
    tag "Download NCBI taxonomy"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"

    input:
        each kmer from kmers 
    
    output:
        tuple "Mito_db_kmer${kmer}", kmer into kraken_db
        file "${dbname}/taxonomy/nodes.dmp" into nodes
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        kraken-build --download-taxonomy --db ${dbname}
        """ 
}

process parseNamesfromNodes{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    tag "Extract names from nodes"

    input:
        file 'nodes.dmp' from nodes
    
    output:
        file "order_names.txt" into orders
        file "family_names.txt" into families
    
    script:
        """
        extract_names.py nodes.dmp order
        extract_names.py nodes.dmp family
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

process extractTaxa{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.78' :
        'quay.io/biocontainers/biopython:1.78' }"
    tag "Extracting..."

    input:
        file genome from downloaded_genomes
        file 'orders.txt' from orders
        file 'families.txt' from families

    output:
        file "*.fasta" into extracted_fasta mode flatten
        file "*.tsv" into convert_acc

    script:
        """
        python3 $baseDir/bin/extract_families.py ${params.include} orders.txt ${params.exclude} families.txt $genome 
        """
}

extracted_fasta
    .map{[it.baseName.split("_")[0],it.baseName.split('_')[1..2].join("_"), it.baseName.split("_")[3..-1].join("_"), file(it)]}
    .set{extracted_fasta}


process writeFastas{
    publishDir "${params.outdir}/genomes/${family}/", saveAs: {"${species}.fasta"}, pattern: "*.fasta", mode:'copy'
    tag "Writing $family:$species"
    
    input:
        tuple family, accession, species, "input.fasta" from extracted_fasta

    output:
        tuple family, species, "${species}.fasta" into (for_bed, for_bwa, for_kraken)
    
    script:
        """
        cat input.fasta > "${species}.fasta"
        """
}

process indexFasta{
    container (workflow.containerEngine ? "merszym/network-aware-bwa:v0.5.10" : null)
    publishDir "${params.outdir}/genomes/${family}/", mode: 'copy'
    tag "$family:$species"
    
    input:
        tuple family, species, "${species}.fasta" from for_bwa

    output:
        file "${species}.fasta.*"
   
    script:
        """
        bwa index "${species}.fasta"
        """
}

process runDustmasker{
    container (workflow.containerEngine ? "merszym/dustmasker:nextflow" : null)
    tag "$family:$species"

    input:
        tuple family, species, "${species}.fasta" from for_bed

    output:
        tuple family, species, "acclist.txt" into acclist

    script:
        """
        dustmasker -in "${species}.fasta" -outfmt acclist > "acclist.txt"
        """
}

process writeBedFiles{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    publishDir "${params.outdir}/masked/", saveAs: {"${species}.masked.bed"}, mode:'copy'
    tag "$family:$species"

    input:
        tuple family, species, "acclist.txt" from acclist

    output:
        file "${species}.masked.bed"

    script:
        """
        cat acclist.txt | \
        python3 $baseDir/bin/dustmasker_interval_to_bed.py \
        > "${species}.masked.bed";
        """
}

for_kraken
    .map{it[2]}
    .toList()
    .set{for_kraken}

process createKrakenDB{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken:1.1.1--pl5321h9f5acd7_7' :
        'quay.io/biocontainers/kraken:1.1.1--pl5321h9f5acd7_7' }"
    tag "Create KrakenDB: Kmer ${kmer}"
    publishDir "${params.outdir}/kraken", mode: 'copy', pattern: "Mito_db*"
    beforeScript 'ulimit -Ss unlimited'

    input:
        tuple file(db), kmer from kraken_db
        file "*.fasta" from for_kraken
    
    output:
        file "Mito_db_kmer${kmer}"
        tuple "nucl_gb.accession2taxid", "${dbname}/taxonomy/names.dmp" into for_taxid_map
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        for fasta in *.fasta; do \
            kraken-build --add-to-library \${fasta} --db ${dbname};\
            done
            kraken-build --build --db ${dbname} --kmer $kmer
        cp $dbname/taxonomy/nucl_gb.accession2taxid .
        """
}

process prepareTaxonomyFile{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    tag "Parse Taxonomy: Kmer ${kmer}"

    input:
        tuple "nucl_gb.accession2taxid", "names.dmp" from for_taxid_map
    
    output:
        tuple "nucl_gb.accession2taxid", "names_dict.json" into taxid_map
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        python3 $baseDir/bin/parse_names.py names.dmp
        """
}

process createFileMap{
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"
    publishDir "${params.outdir}/genomes", mode:'copy'
    
    input:
        file "acc_map.tsv" from convert_acc
        tuple "nucl_gb.accession2taxid", "names_dict.json" from taxid_map

    output:
        file "*.tsv" 

    script:
        """ 
        python3 $baseDir/bin/convert_acc_to_taxid.py acc_map.tsv nucl_gb.accession2taxid names_dict.json
        """
}

