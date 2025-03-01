<h1 style="border:0px;padding-bottom:0px;margin-bottom:0px">quicksand-build</h1>
<p style="color:grey;border-bottom:1px solid lightgrey">The quicksand helper-pipeline</p>

![Singularity](https://img.shields.io/badge/run_with-Singularity-ff69b4?style=for-the-badge)
![Docker](https://img.shields.io/badge/run_with-Docker-0db7ed?style=for-the-badge)
![MIT License](https://img.shields.io/github/license/mpieva/quicksand?style=for-the-badge)


<!-- TOC -->
- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Parameters](#parameters)
- [quicksand](#quicksand)
<!-- /TOC -->

The quicksand-build pipeline is a helper-pipeline that supplements [quicksand](https://www.github.com/mpieva/quicksand). It is used to download a set of mtDNA reference-genomes from NCBI RefSeq, index a KrakenUniq database and create bed-files that are stored in the format that is required by quicksand.

Make sure to check the [RefSeq Website](https://www.ncbi.nlm.nih.gov/refseq/) and note down the current RefSeq Release that is used for your database

**The output** of the pipeline is structured as followes
```
    ncbi: 
         mitochondrion.{n}.genomic.gbff.gz - raw downloaded files from NCBI
    genomes: 
         genomes/{family}/{species}.fasta - The indexed mitochondrial genomes used for mapping with bwa
         genomes/taxid_map.tsv - A table with all nodes in the database (for backwards compability)
     masked:
         masked/{species}.masked.bed - Bed files for all species in the database showing low-complexity regions
    kraken:
         kraken/Mito_db_kmer{kmersize} - A preindexed Kraken-database for the given kmers containing all the species in the database
    work: contains nextflow-specific files and can be deleted after the run
```

## Requirements
To run the pipeline the following programms need to be installed:
1. Nextflow (tested on v.20.04.10): [Installation](https://www.nextflow.io/docs/latest/getstarted.html)
2. Singularity (tested on v3.7.1): [Installation](https://sylabs.io/guides/3.0/user-guide/installation.html) or Docker


## Quickstart

To run the pipeline with default parameters open the terminal and type

``` 
nextflow run mpieva/quicksand-build -profile singularity
```

This will construct the kraken-database for kmer 22 from all mitochondrial genomes in the current refseq-release \

## Parameters

The pipeline accepts the following parameters:

```    
  Pipeline ARGS
       --outdir  PATH    : Directory to save the output in. Default = "out"
       --kmers   KMERS   : Kmer-size to be used for the kraken database are created (e.g. 23). Default=22
       --include STRING  : comma-separated string of Taxa that should be in the DB, e.g. "Mammalia". Default='root'
       --exclude STRING  : comma-separated string of Taxa that mustn't be in the DB, e.g. "Pan,Gorilla".
       --genomes PATH    : A folder to provide extra genomes for the kraken-database // not implemented yet
       --taxonomy PATH   : A folder containing a custom NCBI style `names.dmp` and `nodes.dmp` files

  Nextflow ARGS (only one dash!)
       -profile  PROFILE : Run the pipeline with the assigned profile (see profiles below)
       -resume           : Resume the previous run (if it was stopped in the mean time)
       -w        PATH    : Specify a different "work" directory for intermediate files
       -c        PATH    : Path to a nextflow.config file that provides ADDITIONAL parameters
```

## quicksand
To integrate the created datastructure, run the quicksand pipeline with the following parameters:
```
    --genome <OUTDIR>/genomes
    --bedfiles <OUTDIR>/masked
    --db <OUTDIR>/kraken/Mito_db_kmer<KMER>/
```

## Customization

quicksand-build has some options to customize the databases.

### Add custom reference genomes to the database

- 1 fasta file that contains the references to be added
- 1 `map` file that has 3 columns and specifies the node in the mtDNA NCBI taxonomy
- provide the folder with the `--genomes` flag
- The extra genomes are included in the kraken-classification

Warning: Please provide only **1 genome per taxID**! If multiple genomes are added for a single TaxID, quickand-build will put them **together in the same fasta-file**. While this works for the KrakenUniq classification, quicksand will remove reads mapping to multiple genomes in the same fasta-file due to the low mapping-quality!  

If you want to include multiple genomes from the same species, please add a custom NCBI taxonomy and add additional nodes for each genome

### Update the NCBI Taxonomy

To use more than one genome per species, update the taxonomy to reflect that in the nodes

1. download the `names.dmp` and `nodes.dmp` files from NCBI
2. Update the files (see here: https://github.com/DerrickWood/kraken2/issues/436)
3. Provide a folder containing these files with the `--taxonomy` flag

