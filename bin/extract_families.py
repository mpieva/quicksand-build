from Bio import SeqIO
import Bio
from pathlib import Path
from collections import defaultdict
import gzip
import sys

#import a list of mammalian orders, as they are not annotated in the gb-file
orders = [x.replace('\n','') for x in open(sys.argv[1])]
exclude = sys.argv[2]

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
for arg in sys.argv[3:]:   
    with gzip.open(arg, 'rt') as gb:
        for seq_gb in SeqIO.parse(gb, 'genbank'):
            #make sure you have a biopython version after https://github.com/biopython/biopython/issues/2844
            try:
                family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae') or name.endswith('aceae')][-1]
            except IndexError: #other family syntaz
                family = 'others'
            try:
                order = seq_gb.annotations['taxonomy'][seq_gb.annotations['taxonomy'].index(family)-1]
            except: #No order assigned (Tenrecs and Moles)
                order = 'NA'
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
