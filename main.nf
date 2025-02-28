#!/usr/bin/env nextflow

// include modules

include { KRAKEN_TAXONOMY } from './modules/local/kraken_taxonomy'
include { KRAKEN_BUILD } from './modules/local/kraken_build'
include { PARSE_NAMES } from './modules/local/parse_names'
include { DOWNLOAD_NCBI } from './modules/local/download_NCBI'
include { EXTRACT_FASTA } from './modules/local/extract_fasta'
include { WRITE_FASTA } from './modules/local/write_fasta'
include { INDEX_FASTA } from './modules/local/index_fasta'
include { RUN_DUSTMASKER } from './modules/local/run_dustmasker'
include { WRITE_BEDFILES } from './modules/local/make_bedfiles'
include { MAKE_FILEMAP } from './modules/local/make_filemap'
include { PREPARE_TAXONOMY } from './modules/local/prepare_taxonomy'

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

kmer = Channel.from(params.kmer)
taxonomy = params.taxonomy ? Channel.fromPath("${params.taxonomy}", type:'dir', checkIfExists:true) : []
ch_genomes = params.genomes ? Channel.fromPath("${params.genomes}", type:'dir', checkIfExists:true) : []
    
//
//
// The Pipeline
//
//


workflow {

//
// 1. Setup, show logo
//

cyan = "\033[0;36m"
red = "\033[0;31m"
white = "\033[0m"
yellow = "\033[0;33m"


// write the commandline down
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

${white}${workflow.manifest.description}
${cyan}Version ${workflow.manifest.version} ${white}
-----------------------------------------------------
"""

//
// 2. Download and parse Taxonomy
//

KRAKEN_TAXONOMY( kmer, taxonomy )

ch_database = KRAKEN_TAXONOMY.out.database
ch_nodes = KRAKEN_TAXONOMY.out.nodes

PARSE_NAMES( ch_nodes )

ch_families = PARSE_NAMES.out.families
ch_orders = PARSE_NAMES.out.orders


//
// 3. In parallel, download the genomes from NCBI
//

DOWNLOAD_NCBI()

ch_gbff = DOWNLOAD_NCBI.out.gbff


//
// 4. Extract the genbank files into individual fasta files
//

EXTRACT_FASTA(
        [params.include, params.exclude],
        ch_gbff,
        ch_orders,
        ch_families
)

ch_fasta = EXTRACT_FASTA.out.fasta.flatten()
ch_convert = EXTRACT_FASTA.out.tsv
ch_taxidmap = EXTRACT_FASTA.out.taxidmap

ch_extracted_fasta = ch_fasta.map{
    [it.baseName.split("_")[0], it.baseName.split('_')[1..2].join("_"), it.baseName.split("_")[3..-1].join("_"), it]
    }

WRITE_FASTA(ch_extracted_fasta)

ch_raw_fasta = WRITE_FASTA.out.fasta

// for BWA, index the fasta files
INDEX_FASTA(ch_raw_fasta)

//for dustmasker, mask the fasta files
RUN_DUSTMASKER(ch_raw_fasta)

ch_acclist = RUN_DUSTMASKER.out.txt

WRITE_BEDFILES(ch_acclist)


//
// 5. Make the kraken database and file-mappings
//


// for kraken: we only need the fasta files
ch_forkraken = ch_raw_fasta
    .map{it[2]}
    .toList()

//mix in the 

KRAKEN_BUILD(ch_database, ch_forkraken, ch_taxidmap, ch_genomes)

//ch_taxonomy = KRAKEN_BUILD.out.taxonomy

//PREPARE_TAXONOMY(ch_taxonomy)

//ch_json = PREPARE_TAXONOMY.out.json

//MAKE_FILEMAP( ch_convert, ch_json)

}