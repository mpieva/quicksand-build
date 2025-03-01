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
- [Customization](#customization)
     - [Add custom reference genomes to the database](#add-custom-reference-genomes-to-the-database)
     - [Update the NCBI Taxonomy](#update-the-ncbi-taxonomy)
<!-- /TOC -->

quicksand-build is a helper-pipeline that supplements [quicksand](https://www.github.com/mpieva/quicksand). It is used to download a set of mtDNA reference-genomes from NCBI RefSeq, index a KrakenUniq database and create bed-files that are stored in the format that is required by quicksand.

Make sure to check the [RefSeq Website](https://www.ncbi.nlm.nih.gov/refseq/) and note down the current RefSeq Release that is used for your database

**The output** of the pipeline is structured as followes
```
     ncbi: 
         mitochondrion.{n}.genomic.gbff.gz - raw downloaded files from NCBI
     genomes: 
         genomes/{family}/{species}.fasta - The mtDNA reference genomes that are part of the database
     masked:
         masked/{species}.masked.bed - bed files for the mtDNA reference genomes in the database masking low-complexity regions
     kraken:
         kraken/Mito_db_kmer{kmersize} - A preindexed KrakenUniq database containing all the mtDNA reference genomes in the database
     work: contains nextflow-specific files and can be deleted after the run
```

## Requirements
To run the pipeline the following programms need to be installed:
1. Nextflow >= v22.10: [Installation](https://www.nextflow.io/docs/latest/getstarted.html)
2. Singularity (v3.7.1): [Installation](https://sylabs.io/guides/3.0/user-guide/installation.html) or Docker


## quickstart

To create a minimal database run

``` 
nextflow run mpieva/quicksand-build -profile singularity --include Hominidae
```

This will download all mtDNA genomes that are part of the Hominidae family from NCBI RefSeq and construct a KrakenUniq database with a kmer-size of 22. The genomes and bedfiles are then structured in the file-system for the use with quicksand as indicated above 

## Parameters

The pipeline accepts the following parameters:

```    
  Pipeline ARGS
       --outdir   PATH    : Directory to save the output in. (Default = "out")
       --kmer     KMER    : The kmer-size to be used for the kraken database are created. (Default=22)
       --include  STRING  : comma-separated string of taxa to be downloaded from NCBI RefSeq. e.g. "Mammalia". (Default='root')
       --exclude  STRING  : comma-separated string of taxa to exclude from the DB, e.g. "Pan,Gorilla".
       --genomes  PATH    : A folder with extra genomes to be included in the database construction (see below)
       --taxonomy PATH    : A folder containing custom NCBI style `names.dmp` and `nodes.dmp` files. If provided, skip download of taxonomy from NCBI
       --gbff     PATH    : A folder containing gbff.gz files. If provided, skip download of RefSeq from NCBI

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

## Customize

quicksand-build provides options to customize the database.

### Custom reference genomes

We provide the option to add custom genomes to the quicksand-build run with the `--genomes` flag. These genomes are added to the KrakenUniq database and renamed to fit the requirements of quicksand.

The `--genomes` flag should point to a single directory containing a **single** `.fasta` and a **single** `.map` file (the file-names dont matter)

```
genomes/
├── genomes.fasta
└── genomes.map
```

The fasta file should contain all the extra genomes as individual records.

```
genomes.fasta

>MyCustomGenome_1
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
>MyCustomGenome_2
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
```

The map-file is a tab-separated table with three columns and no header. It links the unique identifiers in the fasta file (1st column) to a (sub)species (2nd column) by its NCBI Taxonomy TaxID (see https://www.ncbi.nlm.nih.gov/taxonomy to find the organism to your custom genomes). The 3rd column is a custom name, but in quicksand-build we reuse the identifiers again.  

```
genomes.map

MyCustomGenome_1    9606 MyCustomGenome_1
MyCustomGenome_2    9606 MyCustomGenome_2
```

**What happens in quicksand-build?**

quicksand is designed to run with only one genome per species. To allow *multiple* custom reference genomes for a single species, quicksand-build mints fake TaxIDs and manipulates the NCBI taxonomy by adding the custom genomes as subspecies of the original species.

```
quicksand-build taxonomy without --genomes

9604 family Hominidae
└── 9605 genus Homo
     └── 9606 species Homo sapiens

quicksand-build taxonomy with --genomes

9604 family Hominidae
└── 9605 genus Homo
     └── 9606 species Homo sapiens
          ├── 3111583 subspecies MyCustomGenome_1
          └── 3111584 subspecies MyCustomGenome_2

```

### Update the NCBI taxonomy

Independent of the custom genomes, we also provide the option to use a custom version of the NCBI taxonomy in quicksand-build, with the `--taxonomy` flag. If this flag is used, the taxonomy is not downloaded from NCBI

The `--taxonomy` flag should point to a single directory containing a `names.dmp` and a `nodes.dmp` file, as can be downloaded from [NCBI](https://ftp.ncbi.nih.gov/pub/taxonomy/)

```
taxonomy/
├── names.dmp
└── nodes.dmp
```
Please be aware that also the custom taxonomy is updated with additional subspecies nodes if used in combination with the `--genomes` flag 