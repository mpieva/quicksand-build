# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres (a bit) to [Semantic Versioning](http://semver.org/).

## v3.0

This is a major update of the quicksand-build pipeline, as the structure created here can **no longer be used with quicksand v1.x**. Compatibility with quicksand versions **v2.x** is still given.

### Major Changes
- Download the NCBI taxonomy and construct the quicksand database with `krakenuniq` instead of `kraken`. Reason: The kraken-build command didnt work anymore and yielded a corrupted gzip file.
- remove backwarts-compability with quicksand versions v1.x (`taxid_map.tsv` was removed from the output)
- add `--genomes` flag to provide custom genomes that get integrated into the database (folder with `sequences.fasta` and `file.map` files)
- add `--taxonomy` flag to provide a custom taxonomy (folder with `names.dmp` and `nodes.dmp` files). Skip download of taxonomy
- add `--gbff` flag to provide a folder with the downloaded RefSeq mitochondrion file (e.g. a quicksand-build `ncbi` folder)

## v2.0

This is a conversion of the former dsl1 code to dsl2 syntax. The major version update is only caused by the framework shift from dsl1 to dsl2. The conversion is a "quick and dirty" conversion, with a 1:1 mapping of former processes to local modules without optimization of the channels or restructuring of the code.

### Major Changes

- modularize processes to account for the dsl2 nextflow syntax

### Minor Changes

- rename `--kmers` to `--kmer`
- accept only a single 'kmer' as input for the `--kmer` flag (mutiple kmers was broken)
