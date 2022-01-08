#! usr/bin/env python3

import sys
import json

name_taxid_dict = json.load(open(sys.argv[3]))
accession_taxid_dict = {}

for line in [x for x in open(sys.argv[2])]:
    _,k,v,_ = line.split('\t', 3)
    accession_taxid_dict[k] = v

handle = open('taxid_map.tsv', 'w')

for line in [x for x in open(sys.argv[1])]:
    acc, order, fam, sp = line.replace('\n','').split('\t', 3)
    try:
        sp_taxid = accession_taxid_dict[acc]
        try:
            order_taxid = name_taxid_dict[order]
        except KeyError: # the Mules and Terecs again
            order_taxid = 'NA'
        fam_taxid = name_taxid_dict[fam]
        gen_taxid = name_taxid_dict[sp.split("_")[0]]
        print(sp_taxid, fam, sp, order, sep='\t', file=handle)
        print(gen_taxid, fam, sp, order,sep='\t', file=handle)
        print(fam_taxid, fam, sp, order, sep='\t', file=handle)
        print(order_taxid, fam, sp, order, sep='\t', file=handle)
    except KeyError:
        #it happens that genomes get retracted by RefSeq and dont show up in the downloaded taxonomy-files of kraken anymore
        #However, the genomes are still present in the ncbi-refseq-download until the next release (and thus the name in the acc_map.tsv).
        #This results in keyError. We ignore these cases - we trust the taxonomy files!
        pass

handle.close()

