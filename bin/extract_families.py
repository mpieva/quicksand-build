from Bio import SeqIO
import Bio
from pathlib import Path
from collections import defaultdict
import gzip
import sys

#give information about the groups that you want to have included (e.g. Mammalia)
#import a list of all orders in Refseq, as they are not annotated in the gb-file
#provide a list of species to exclude

include = set([x.strip() for x in sys.argv[1].split(',')]) if sys.argv[1] != 'root' else 'root'
orders = set([x.replace('\n','') for x in open(sys.argv[2])])
exclude_string = sys.argv[3]
families = set([x.replace('\n','') for x in open(sys.argv[4])])

#make a list of taxa that should be excluded from the database
exclude = set([x for x in exclude_string.split(',')]) if exclude_string != 'None' else set([])

acc_map_handle = open('accmap.tsv', 'w')
for arg in sys.argv[5:]:   
    with gzip.open(arg, 'rt') as gb:
        for seq_gb in SeqIO.parse(gb, 'genbank'):
            tax = set(seq_gb.annotations['taxonomy'])
            if include !='root' and len(include.intersection(tax))==0:
                continue
            #check exclude and skip entry if excluded
            if len(exclude.intersection(tax))>0:
                continue
            #make sure you have a biopython version after https://github.com/biopython/biopython/issues/2844
            try:
                family = families.intersection(tax).pop() #is only one item, so pop is okay
            except TypeError: #no family?
                family = 'N/A'
            try:
                order = orders.intersection(tax).pop()
            except TypeError: #No order assigned (e.g. Tenrecs and Moles)
                order = 'N/A'
            organism = seq_gb.annotations['organism'].replace(' ', '_')
            if any(x in organism for x in ['[','(','{']): #[Candida], (In: Bacteria) --> unclear taxonomy, abort
                continue
            acc = seq_gb.id
            filename = f"{family}_{acc}_{organism}.fasta"
            try:
                # some of the bacteria names contain '/'...
                with open(filename.replace('/','_'),'w') as fasta_out:
                    SeqIO.write(seq_gb, fasta_out, 'fasta')
                print(acc,order,family,organism.replace('/','_'), sep='\t',file=acc_map_handle)

            except Bio.Seq.UndefinedSequenceError:
                #sometimes fresh releases contain sequences without the actual letters.
                Path(filename.replace('/','_')).unlink() # delete the empty file 
                print(f'No sequence contained in {acc}', file=sys.stderr)
                continue

acc_map_handle.close()
