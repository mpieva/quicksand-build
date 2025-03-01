#!/usr/bin/env nextflow

// include modules

include { KRAKEN_TAXONOMY } from './modules/local/kraken_taxonomy'
include { PARSE_TAXONOMY } from './modules/local/parse_taxonomy'
include { KRAKEN_BUILD } from './modules/local/kraken_build'
include { DOWNLOAD_NCBI } from './modules/local/download_NCBI'
include { EXTRACT_FASTA } from './modules/local/extract_fasta'
include { CONCAT_FASTA } from './modules/local/concat_fasta'
include { WRITE_FASTA } from './modules/local/write_fasta'
include { INDEX_FASTA } from './modules/local/index_fasta'
include { RUN_DUSTMASKER } from './modules/local/run_dustmasker'
include { WRITE_BEDFILES } from './modules/local/make_bedfiles'

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
// some required functions
def has_ending(file, extension){
    return extension.any{ file.toString().toLowerCase().endsWith(it) }
}

// Parsing parameters
kmer = Channel.from(params.kmer)
taxonomy = params.taxonomy ? Channel.fromPath("${params.taxonomy}", type:'dir', checkIfExists:true) : []
ch_extra_genomes = params.genomes ? Channel.fromPath("${params.genomes}/*", checkIfExists:true) : Channel.empty()

//
//
// The Pipeline
//
//

import groovy.json.JsonSlurper


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
)

ch_fasta = EXTRACT_FASTA.out.fasta.flatten()
ch_krakenuniq_map = EXTRACT_FASTA.out.krakenuniq_map.splitCsv(sep:'\t', header:["id","TaxID","ident"]).map{[it.id, it]}
// [id, data]

ch_extracted_fasta = ch_fasta.map{ it -> 
    [it.baseName.split("__")[1], it.baseName.split("__")[0], it]
}
// [id, taxid, fasta]

//
// 5. Parse extra-genomes and mix with extracted genomes
//

//separate input-fasta and map file
ch_extra_genomes = ch_extra_genomes.branch{
    fasta: has_ending(it, ['fa','fasta','fas'])
    maps: has_ending(it, ['map'])
    fail:true
}

// mix the added map-file to the extracted one
// now remove duplicated accession IDs
ch_krakenuniq_map = ch_krakenuniq_map.mix(
    ch_extra_genomes.maps.splitCsv(sep:'\t', header:['id','TaxID','ident']).map{[it.id, it]}
).unique{it[0]}

// create ONE maps file to extract the taxonomy
ch_genomes_maps_file = ch_krakenuniq_map.collectFile( name:"krakenUniq.map", newLine:true){ [it[1].id, it[1].TaxID, it[1].ident].join("\t") }

// Extract the Taxonomy JSON!
PARSE_TAXONOMY ( ch_nodes, ch_genomes_maps_file )
ch_taxonomy_json = PARSE_TAXONOMY.out.json

def jsonSlurper = new JsonSlurper()
ch_taxonomy_json.map{ json ->
    [jsonSlurper.parseText(file(json).text)]
}.set{ json }

// Now add the taxID to the genomes that are not yet with taxID
ch_genomes_fasta = ch_extra_genomes.fasta.splitFasta(record: [id: true, seqString: true]).map{[it.id, it]}

// collect the fasta by taxID --> all extra genomes of e.g. Homo_sapiens go into 1 fasta file
ch_genomes_fasta_files = ch_genomes_fasta.collectFile(
        newLine:true
    ){ it -> ["${it[0]}.fasta", ">${it[0]}\n${it[1].seqString}"] }
        .map{file -> [file.baseName, file]} //[accession, file]

//bring merge them together to add the taxID
ch_genomes_fasta_files = ch_genomes_fasta_files.combine(ch_krakenuniq_map, by:0).map{
    [it[0], it[2].TaxID, it[1]] // [id, taxid, fasta]
}

//combine with the extracted fasta
ch_extracted_fasta = ch_extracted_fasta.mix(ch_genomes_fasta_files).unique{it[0]}

//and get the taxonomy from the json
ch_extracted_fasta = ch_extracted_fasta.combine(json).map{id,taxid,fasta,json -> [id,fasta,taxid,json[taxid]]}

//now we MIGHT have multiple fasta from the same organism. So er read all the fasta-files AGAIN and
//save the records into files by taxID
//if we only download from RefSeq, that results in the same files, since its a non-redundant database
//but extra-genomes (e.g. 5 different neanderthals) would otherwise overwrite each other later 

ch_fasta_for_cat = ch_extracted_fasta
    .groupTuple(by:2).map{it -> [it[1], it[2], it[3].first()]}

CONCAT_FASTA(ch_fasta_for_cat)

ch_genomes = CONCAT_FASTA.out.fasta

ch_for_writing = ch_genomes.map{
    [
        it[2].family,
        it[2].subspecies ?: it[2].species,
        it[0]
    ]
}

// add the extra_genomes to the extracted_fasta
WRITE_FASTA(
    ch_for_writing
)

ch_raw_fasta = WRITE_FASTA.out.fasta

// for BWA, index the fasta files
INDEX_FASTA(ch_raw_fasta)

//for dustmasker, mask the fasta files
RUN_DUSTMASKER(ch_raw_fasta)

ch_acclist = RUN_DUSTMASKER.out.txt

WRITE_BEDFILES(ch_acclist)

//
// 6. Make the kraken database
//

// for kraken: we only need the fasta files, the map goes in separately
ch_forkraken = ch_genomes.map{it[0]}.collect()


KRAKEN_BUILD(ch_database, ch_forkraken, ch_genomes_maps_file)

}