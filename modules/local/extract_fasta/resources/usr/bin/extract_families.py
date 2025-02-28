#! /usr/bin/env python3

from Bio import SeqIO
import Bio
from pathlib import Path
from collections import defaultdict
import gzip
import sys

# give information about the groups that you want to have included (e.g. Mammalia)
# import a list of all orders in Refseq, as they are not annotated in the gb-file
# provide a list of species to exclude

include = (
    set([x.strip() for x in sys.argv[1].split(",")])
    if sys.argv[1] != "root"
    else "root"
)
orders = set([x.replace("\n", "") for x in open(sys.argv[2])])
exclude_string = sys.argv[3]
families = set([x.replace("\n", "") for x in open(sys.argv[4])])

# make a list of taxa that should be excluded from the database
exclude = (
    set([x for x in exclude_string.split(",")]) if exclude_string != "None" else set([])
)

acc_map_handle = open("accmap.tsv", "w")
krakenuniq_map = open("krakenuniq.map", "w")

for arg in sys.argv[5:]:
    with gzip.open(arg, "rt") as gb:
        for seq_gb in SeqIO.parse(gb, "genbank"):
            tax = set(seq_gb.annotations["taxonomy"])

            # check the include parameter 
            if include != "root" and len(include.intersection(tax)) == 0:
                continue
            # check exclude and skip entry if excluded
            if len(exclude.intersection(tax)) > 0:
                continue
            organism = seq_gb.annotations["organism"].replace(" ", "_").replace("/", "_")
            if any(
                x in organism for x in ["[", "(", "{"]
            ):  # [Candida], (In: Bacteria) --> unclear taxonomy, abort
                continue
            # extract the taxonomy-ID from the genebank entry
            taxid = seq_gb.features[0].qualifiers['db_xref'][0].split(":")[1]
            
            # make sure you have a biopython version after https://github.com/biopython/biopython/issues/2844
            try:
                family = families.intersection(
                    tax
                ).pop()  # is only one item, so pop is okay
            except KeyError:  # no family?
                family = "Unassigned"
            try:
                order = orders.intersection(tax).pop()
            except KeyError:  # No order assigned (e.g. Tenrecs and Moles)
                order = "Unassigned"
            
            acc = seq_gb.id
            filename = f"{family}_{acc}_{organism}.fasta"
            try:
                # some of the bacteria names contain '/'...
                with open(filename, "w") as fasta_out:
                    SeqIO.write(seq_gb, fasta_out, "fasta")
                # this is for backwarts-compability
                print(
                    acc,
                    order,
                    family,
                    organism,
                    sep="\t",
                    file=acc_map_handle,
                )
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

acc_map_handle.close()
krakenuniq_map.close()