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
```git clone https://www.github.com/MerlinSzymanski/datastructure_nf```

## USAGE: ##

Assuming you have nextflow and conda installed run

```nextflow run main.nf --outdir ABSOLUTE_PATH```

required:
    --outdir  PATH:   absolute path to the save-dir. e.g. "/mnt/scratch/.../out"

optional (if you are at the MPI EVA):
    --kraken  PATH:   path to your kraken installation folder.
                      default: '/home/merlin_szymanski/Kraken/install'

    --kmers   ARRAY:  Array of kmers for which databases should be created (this is not tested) 
                      default: '["22"]'

Now you can run the sediment pipline with the following tags:
    --genome ABSOLUTE_PATH/genomes
    --bedfiles ABSOLUTE_PATH/masked
    --db ABSOLUTE_PATH/kraken/Mito_db_kmer22


