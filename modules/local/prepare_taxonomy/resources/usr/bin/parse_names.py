#! /usr/bin/env python3

import json
import sys

name_taxid_dict = {}
with open(sys.argv[1]) as infile:
    for row in infile:
        if "scientific name" in row:
            taxid, name, _ = row.replace("\t", "").split("|", 2)
            name_taxid_dict[name] = taxid

json.dump(name_taxid_dict, open("names_dict.json", "w"))
