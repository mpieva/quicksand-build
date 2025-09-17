#! /usr/bin/env python3

from Bio import SeqIO
import Bio
from pathlib import Path
from collections import defaultdict
import gzip
import sys

# include can be Taxa (e.g. 'Mammalia') based on the taxonomy string
# include can be Accession IDs

include = (
    set([x.strip() for x in sys.argv[1].split(",")])
    if sys.argv[1] != "root"
    else "root"
)

# exclude can be Taxa (e.g. 'Mammalia') based on the taxonomy string
# exclude can be Accession IDs

exclude_string = sys.argv[2]

exclude = (
    set([x for x in exclude_string.split(",")]) if exclude_string != "None" else set([])
)

krakenuniq_map = open("krakenuniq.map", "w")

for arg in sys.argv[3:]:
    with gzip.open(arg, "rt") as gb:
        for seq_gb in SeqIO.parse(gb, "genbank"):
            tax = set(seq_gb.annotations["taxonomy"])
            accession = seq_gb.annotations["accessions"][0]

            # check the include parameter for taxonomy, skip if _not_ included
            if include != "root" and len(include.intersection(tax)) == 0:
                #Now check the accession
                #the accession could be entered with a version, but we strip the version 
                # e.g. ["Mammalia", "NC_023100.1", "Gorilla", "Pan"] --> yes, if accession is "NC_023100"
                if not any(x.split('.')[0] == accession for x in include):
                    continue
            # check exclude and skip entry if excluded
            if len(exclude.intersection(tax)) > 0:
                continue
            # passes the taxonomy-exclude, but check for accession-exclude
            if any(x.split('.')[0] == accession for x in exclude):
                continue
            organism = seq_gb.annotations["organism"].replace(" ", "_").replace("/", "_")
            if any(
                x in organism for x in ["[", "(", "{"]
            ):  # [Candida], (In: Bacteria) --> unclear taxonomy, abort
                continue
            # extract the taxonomy-ID from the genebank entry
            taxid = [x for x in seq_gb.features[0].qualifiers["db_xref"] if x.startswith("taxon")][0].split(":")[1]
            acc = seq_gb.id
            
            filename = f"{taxid}__{acc}.fasta"
            try:
                with open(filename, "w") as fasta_out:
                    SeqIO.write(seq_gb, fasta_out, "fasta")
                # this is for kraken-uniq based database construction 
                print(
                    acc,
                    taxid,
                    organism,
                    sep="\t",
                    file=krakenuniq_map
                )

            except Bio.Seq.UndefinedSequenceError:
                # sometimes fresh releases contain sequences without the actual letters.
                Path(filename).unlink()  # delete the empty file
                print(f"No sequence contained in {acc}", file=sys.stderr)
                continue

krakenuniq_map.close()
