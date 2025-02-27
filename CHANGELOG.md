# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres (a bit) to [Semantic Versioning](http://semver.org/).

## NEW
### Major Changes

- Download NCBI taxonomy and construct the kraken-database using `krakenuniq` instead of `kraken`, because the kraken-build command doesnt work anymore and downloads a corrupted gzip.
- add `--taxonomy` flag to provide a custom taxonomy (folder with `names.dmp` and `nodes.dmp` file)

## v2.0

This is a conversion of the former dsl1 code to dsl2 syntax. The major version update is only caused by the framework shift from dsl1 to dsl2. The conversion is a "quick and dirty" conversion, with a 1:1 mapping of former processes to local modules without optimization of the channels or restructuring of the code.

### Major Changes

- modularize processes to account for the dsl2 nextflow syntax

### Minor Changes

- rename `--kmers` to `--kmer`
- accept only a single 'kmer' as input for the `--kmer` flag (mutiple kmers was broken)
