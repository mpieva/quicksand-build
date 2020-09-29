#!/usr/bin/env nextflow

params.kraken   =   "/home/merlin_szymanski/Kraken/install/"
params.outdir   =   false

def helpMessage(){
    log.info"""
    DATASTRUCTURE PIPELINE

    Download all mammalian mitochondiral genomes from the current NCBI/Refseq
    release and create the datastructure required by the sediment_nf pipeline.
    Creates 4 folders:
    
    1. ncbi:     raw Downloaded files from NCBI
    2. genomes:  Fasta files grouped by Family
    3. masked:   For all fasta files in 'genomes' a masked bed file
    4. kraken:   For the given kmers the kraken databases
    
    USAGE:
    nextflow run path/to/main.nf --outdir PATH

    required:
        --outdir  PATH:   path to the save-dir. e.g. "/mnt/scratch/.../out"

    optional:
        --kraken  PATH:   path to your kraken installation folder.
                          default: '/home/merlin_szymanski/Kraken/install'
        
        --kmers   ARRAY:  please change that in the nextflow.config file
    """.stripIndent()
}
if(params.outdir == false){
    helpMessage()
    exit 0
}


process downloadGenomes{
    cache false
    publishDir "${params.outdir}/ncbi", mode: 'link'
    tag "Downloading..."

    output:
        file '*.gz' into downloaded_genomes

    script:
        """
        rsync -av rsync://ftp.ncbi.nlm.nih.gov/refseq/release/mitochondrion/*.genomic.gbff.gz .

        """
}

process extractFamilies{
    cache false
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
    .map{[it.baseName.split("_")[0], it.baseName.split("_")[1..-1].join("_"), file(it)]}
    .set{extracted_fasta}


process writeFastas{
    cache false
    publishDir "${params.outdir}/genomes/${family}/", saveAs: {"${species}.fasta"}, pattern: "*.fasta", mode:'link'

    tag "$family:$species"
    
    input:
        set family, species, "input.fasta" from extracted_fasta

    output:
        set family, species, "output.fasta" into (for_bed, for_bwa, for_kraken)

    script:
        """
        cat input.fasta > output.fasta
        """
}

process indexFasta{
    cache false
    publishDir "${params.outdir}/genomes/${family}/", mode: 'link'
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
    cache false
    publishDir "${params.outdir}/masked/", saveAs: {"${species}.masked.bed"}, mode:'link'
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
    cache false
    conda "$baseDir/envs/environment.yml"
    tag "Wait ~ 30min."
    
    input:
        each kmer from params.kmers
        file fasta_list from for_kraken
    
    output:
        file "output.txt" into log
    
    script:
        dbname = "Mito_db_kmer${kmer}"
        """
        if [[ "${params.outdir}" = /* ]]; \
            then out="${params.outdir}";\
            else out="${launchDir}/${params.outdir}";\
        fi;
        ${params.kraken}/kraken-build --download-taxonomy --db ${dbname}
        for fasta in $fasta_list; \
            do file=\$(cut -f3 -d',' \$fasta);\
            ${params.kraken}/kraken-build --add-to-library \${file%?} --db ${dbname};\
            done
            ${params.kraken}/kraken-build --build --db ${dbname} --kmer $kmer
            ${params.kraken}/kraken-build --clean --db ${dbname}
        if [[ -d \$out/kraken ]];\
            then rm -fr \$out/kraken;\
            fi;
        mkdir \$out/kraken
        cp -r ${dbname} \$out/kraken
        touch "output.txt"
        """
}

