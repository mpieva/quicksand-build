from Bio import SeqIO
import Bio
from pathlib import Path
from collections import defaultdict
import gzip
import sys

#give information about the groups that you want to have included (e.g. Mammalia)
#import a list of all orders in Refseq, as they are not annotated in the gb-file
#provide a list of species to exclude

include = [x.strip() for x in sys.argv[1].split(',')] if sys.argv[1] != 'root' else 'root'
orders = [x.replace('\n','') for x in open(sys.argv[2])]
exclude = sys.argv[3]

#make a list of species that should not be in the database
excluded_species = []
try:
    with open(exclude, 'r') as ex:
        for line in ex:
            #Hominidae\tHomo_sapiens,Homo_neandertalensis
            excluded_species.extend(line.replace('\n','').split('\t')[1].split(','))
except FileNotFoundError: #no excluded species
    pass

acc_map_handle = open('accmap.tsv', 'w')
for arg in sys.argv[4:]:   
    with gzip.open(arg, 'rt') as gb:
        for seq_gb in SeqIO.parse(gb, 'genbank'):
            print(seq_gb.annotations['taxonomy'])
            if include !='root' and not any(x in include for x in seq_gb.annotations['taxonomy']):
                continue
            #make sure you have a biopython version after https://github.com/biopython/biopython/issues/2844
            try:
                family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae') or name.endswith('aceae')][-1]
            except IndexError: #other family syntax
                family = 'N/A'
            try:
                order = [name for name in seq_gb.annotations['taxonomy'] if name in orders ][-1]
            except: #No order assigned (Tenrecs and Moles)
                order = 'N/A'
            organism = seq_gb.annotations['organism'].replace(' ', '_')
            if any(x in organism for x in ['[','(','{']): #[Candida], (In: Bacteria) --> unclear taxonomy, abort
                continue
            if organism in excluded_species:
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
