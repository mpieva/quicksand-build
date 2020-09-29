# DATASTRUCTURE PIPELINE #

This pipeline is meant as an additional pipeline to the sediment_nf pipeline.
It downloads all mammalian mitochondiral genomes from the current NCBI/Refseq
release and creates the datastructure and files required by the 
sediment_nf pipeline in the correct format.

The output of the pipeline is 4 folders:

1. ncbi:     raw downloaded files from NCBI
2. genomes:  the genomes used for mapping with bwa grouped by family
3. masked:   the masked bed files for all fasta files in 'genomes'
4. kraken:   A preindexed Kraken-database for the given kmers containing the genomes above

## DOWNLOAD ##

Get the files by running 

``` git clone https://www.github.com/MerlinSzymanski/datastructure_nf ```

and change into the directory  

``` cd datastructure_nf ```


## Install Nextflow ##

create an environment containing nextflow with
```
conda env create -f envs/base.yml
```

## USAGE: ##

To create the datastructure above, run

``` 
conda activate nextflow
nextflow run path/to/main.nf --outdir PATH [--kraken PATH] 
```

**Arguments:**
```    
       --outdir  PATH:   REQUIRED: path to the (to be created) save-dir, e.g. "out"
    
       --kraken  PATH:   OPTIONAL: path to your kraken installation folder.
                         default: '/home/merlin_szymanski/Kraken/install'
```

**Additional:**

    additional settings can be set in the nextflow.config file.
    
    params.kmers:    Array of kmers for which databases will be created. Add more
                     kmers to create more preindexed kraken databases
                     Default: params.kmers = ["22"]

## Sediment_nf ##

One can now integrate the databases in the sediment_nf pipline using the following tags:
```
    --genome OUTDIR/genomes
    --bedfiles OUTDIR/masked
    --db OUTDIR/kraken/Mito_db_kmerKMER
```

## Questions? ##
Feel free to contact me

