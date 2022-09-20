<h1 style="border:0px;padding-bottom:0px;margin-bottom:0px">Quicksand-build</h1>
<p style="color:grey;border-bottom:1px solid lightgrey">The quicksand helper-pipeline</p>

![Singularity](https://img.shields.io/badge/run_with-Singularity-ff69b4?style=for-the-badge)
![Docker](https://img.shields.io/badge/run_with-Docker-0db7ed?style=for-the-badge)
![MIT License](https://img.shields.io/github/license/mpieva/quicksand?style=for-the-badge)


See the [Github Pages](https://mpieva.github.io/quicksand) of quicksand for a comprehensive documentation of the pipeline.

<!-- TOC -->
- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Parameters](#parameters)
- [quicksand](#quicksand)
<!-- /TOC -->

This repostory is an addition to the mpieva/quicksand pipeline [see here](https://www.github.com/mpieva/quicksand). 
Starting quicksand-build will download the mitochondiral genomes from the current NCBI/RefSeq release and 
create - for the given taxa - the datastructure and files required by the quicksand pipeline.

Make sure to check the [RefSeq Website](https://www.ncbi.nlm.nih.gov/refseq/) and note down the current RefSeq Release that is used for your database

**The output** of the pipeline is structured as followes
```
    ncbi: 
         mitochondrion.{n}.genomic.gbff.gz - raw downloaded files from NCBI
    genomes: 
         genomes/{family}/{species}.fasta - The indexed mitochondrial genomes used for mapping with bwa
         genomes/taxid_map.tsv - A table with all nodes in the database - used to get all reference genomes for one taxon ID
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
       --kmers   KMERS   : Comma-separated list of kmers for which databases are created (e.g. 21,22,23). Default=22
       --include STRING  : comma-separated string of Taxa that should be in the DB, e.g. "Mammalia". Default='root'
       --exclude STRING  : comma-separated string of Taxa that mustn't be in the DB, e.g. "Pan,Gorilla".

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
