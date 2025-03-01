#! /usr/bin/env pypy3

import sys, shutil 

def find_highest_taxID(names):
    """
    given the names.dmp data, return the highest taxID, so that new IDs can be created
    """    
    highest_taxid = 0
    for line in names:
        taxid,data = line.split("\t|\t",1)
        if int(taxid) > highest_taxid:
            highest_taxid = int(taxid)
    return highest_taxid


if __name__ == "__main__":
    names_file = sys.argv[1]
    nodes_file = sys.argv[2]
    filemap = sys.argv[3]
    
    with open(names_file) as infile:
        highest_taxid = find_highest_taxID(infile) + 10000 #add a random number, just to be high

    # first, create the new filemap
    new_taxid_dict = {}
    with open(filemap) as infile:
        with open("updated_map.map","w") as outfile:
            for line in infile:
                acc,taxid,name = line.replace("\n","").split("\t",2)
                # mint a new taxid
                highest_taxid = highest_taxid + 1
                # add the new taxid to the dict (old, new)
                new_taxid_dict[acc] = (taxid, highest_taxid)
                # write the new map-file
                print(acc, highest_taxid, name, sep="\t", file=outfile)

    #now update the names.dmp file
    with open(names_file) as infile, open("new_names.dmp", "w") as outfile:
        # Copy all content from infile to outfile
        shutil.copyfileobj(infile, outfile)

        # Append new content
        for acc in new_taxid_dict:
            print(
                new_taxid_dict[acc][1],  # new taxid
                acc,  # name
                f"{acc}_{new_taxid_dict[acc][1]}",  # unique_name
                "scientific name",  # class, requires "scientific name" for quicksand
                sep="\t|\t",  # NCBI separator
                end="\t|\n",  # end of file
                file=outfile
            )
    
    #now update the nodes.dmp file
    with open(nodes_file) as infile, open("new_nodes.dmp", "w") as outfile:
        # Copy all content from infile to outfile
        shutil.copyfileobj(infile, outfile)

        # Append new content
        for acc in new_taxid_dict:
            print(
                new_taxid_dict[acc][1], # new taxid
                new_taxid_dict[acc][0], # old taxid / parent
                "subspecies",  # rank
                "", # EMBL Code, leave empty
                2, # Division ID, 2=Eukaryota.
                1, # Inherited div flag -> Use the Division ID from the parent
                2, # which genetic code? 2 = Vertebrate Mammalia
                1, # inherit this flag from the parent
                2, # mtCode Id
                1, # inherit from parent
                0, # not hidden (dont know if this has an effect...)
                0, # not the root of a hidden subtree
                "Attention. This node created by the quicksand-build pipeline. The taxid is FAKE. Dont use this taxonomy outside the quicksand context",
                sep="\t|\t",  # NCBI separator
                end="\t|\n",  # end of file
                file=outfile
            )