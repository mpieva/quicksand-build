# Quicksand-build
This repostory is an addition to the mpieva/quicksand pipeline [see here](https://www.github.com/mpieva/quicksand). 
Starting quicksand-build will downloads all mammalian mitochondiral genomes from the current NCBI/RefSeq release and 
create the datastructure and files required by the quicksand pipeline.

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
2. Singularity (tested on v3.7.1): [Installation](https://sylabs.io/guides/3.0/user-guide/installation.html)

**Alternatively** one can run the pipeline with conda or Docker, in that case see the section "Profiles" below


## Quickstart:
To run the pipeline with default parameters open the terminal and type

``` 
nextflow run mpieva/quicksand-build --outdir <PATH> [ --kmers KMERS ]
```

alternatively one can download the repository and start the pipeline from the local file

## Or download the code 

Download the repository and start the pipeline from the local files by running:

``` 
git clone https://www.github.com/mpieva/quicksand-build
nextflow run quicksand-build/main.nf -profile singularity --outdir <PATH> [ --kmers KMERS ]
```

on the local repository.

**Arguments:**
```    
  Pipeline ARGS
       --outdir  PATH    : Directory to save the output in. Default = "out"
       --kmers   KMERS   : Comma-separated list of kmers for which databases are created (e.g. 21,22,23). Default=22
       --include STRING  : comma-separated string of Taxa that should be in the DB, e.g. "Mammalia". Default='root'
  Nextflow ARGS (only one dash!)
       -profile  PROFILE : Run the pipeline with the assigned profile (see profiles below)
       -resume           : Resume the previous run (if it was stopped in the mean time)
       -w        PATH    : Specify a different "work" directory for intermediate files
       -c        PATH    : Path to a nextflow.config file that provides ADDITIONAL parameters
```

## Link to quicksand pipeline
To integrate the created datastructure, run the quicksand pipeline with the following parameters:
```
    --genome <OUTDIR>/genomes
    --bedfiles <OUTDIR>/masked
    --db <OUTDIR>/kraken/Mito_db_kmer<KMER>/
```

## Profiles
Besides the **Default** singularity profile the pipeline provides two additional profiles that provide an alternative way to run the pipeline - Conda and Docker

### Conda 
**Requirements**\
If one wants to run the pipeline in conda, make sure that (besides Nextflow) conda is installed: [Instructions](https://conda.io/projects/conda/en/latest/user-guide/install/index.html).
Additionally one needs to install the following programs
* rsync
* the network-aware branch of bwa: [Source](https://github.com/mpieva/network-aware-bwa)
* dustmasker (ncbi-blast+) [Source](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
* Kraken 1 [Source](https://github.com/DerrickWood/kraken)

And add them to the $PATH variable

**Running the pipeline**
``` 
nextflow run mpieva/quicksand-build -profile conda --outdir <PATH> [ --kmers KMERS ]
```

### Docker
**Requirements**\
Besides Nextflow, Docker needs to be installed: [Installation](https://docs.docker.com/get-docker/)

**Usage**
``` 
nextflow run mpieva/quicksand-build -profile docker --outdir <PATH> [ --kmers KMERS ]
```
