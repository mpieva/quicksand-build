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
    acc, fam, sp = line.replace('\n','').split('\t', 2)
    sp_taxid = accession_taxid_dict[acc]
    fam_taxid = name_taxid_dict[fam]
    gen_taxid = name_taxid_dict[sp.split("_")[0]]
    print(sp_taxid, fam, sp, sep='\t', file=handle)
    print(gen_taxid, fam, sp, sep='\t', file=handle)
    print(fam_taxid, fam, sp, sep='\t', file=handle)

handle.close()

