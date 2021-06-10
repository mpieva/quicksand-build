# DATASTRUCTURE PIPELINE
This pipeline is an additional pipeline to the sediment_nf pipeline. It downloads all mammalian mitochondiral genomes from the current NCBI/RefSeq release and creates the datastructure and files required by the sediment_nf pipeline.

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
    work: contains nextflow-specific files and can be deleted
```

## Requirements
To run the pipeline the following programms need to be installed:
1. Nextflow (tested on v.20.04.10): [Installation](https://www.nextflow.io/docs/latest/getstarted.html)
2. Singularity (tested on v3.7.1) [Installation](https://sylabs.io/guides/3.0/user-guide/installation.html)

**Alternatively** one can run the pipeline with conda or Docker, in that case see the section "Profiles" below

## Download the code 
You can download the pipeline by running

``` git clone https://www.github.com/MerlinSzymanski/datastructure_nf ```


## Usage:
To run the pipeline with default parameters type

``` 
nextflow run datastructure_nf/main.nf -profile singularity --outdir <PATH> [ --kmers KMERS ]
```

**Arguments:**
```    
  Pipeline ARGS
       --outdir  PATH    : Directory to save the output in. Default = "out"
       --kmers   KMERS   : Comma-separated list of kmers for which databases are created (e.g. 21,22,23). Default=22
  Nextflow ARGS (only one dash!)
       -profile  PROFILE : Run the pipeline with the assigned profile (see profiles below)
       -resume           : Resume the previous run (if it was stopped in the mean time)
       -w        PATH    : Specify a different "work" directory for intermediate files
       -c        PATH    : Path to a nextflow.config file that provides ADDITIONAL parameters
```

## Usage with the Sediment_nf pipeline
To integrate the created datastructure in the pipeline, run the sediment_nf pipeline with the following parameters:
```
    --genome <OUTDIR>/genomes
    --bedfiles <OUTDIR>/masked
    --db <OUTDIR>/kraken/Mito_db_kmer<KMER>/
```

## Profiles
Besides the **Singularity** profile the pipeline provides two additional profiles that provide an alternative way to run the pipeline - Conda and Docker

### Conda 
**Requirements**
If one wants to run the pipeline in conda, make sure that (besides Nextflow) conda is installed: [Instructions](https://conda.io/projects/conda/en/latest/user-guide/install/index.html).
Additionally one needs to install the following programs
* rsync
* the network-aware branch of bwa: [Source](https://github.com/mpieva/network-aware-bwa)
* dustmasker (ncbi-blast+) [Source](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
* Kraken 1 [Source](https://github.com/DerrickWood/kraken)

And add them to the $PATH variable

**Running the pipeline**
``` 
nextflow run datastructure_nf/main.nf -profile conda --outdir <PATH> [ --kmers KMERS ]
```

### Docker
**Requirements**
Besides Nextflow, Docker needs to be installed: [Installation](https://docs.docker.com/get-docker/)

**Usage**
``` 
nextflow run datastructure_nf/main.nf -profile docker --outdir <PATH> [ --kmers KMERS ]
```
