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
            if 'Mammalia' in seq_gb.annotations['taxonomy']:
                try:
                    order = [name for name in seq_gb.annotations['taxonomy'] if name in orders ][-1]
                except IndexError: #No order assigned (Tenrecs and Moles)
                    order = 'NA'
                family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae')][-1]
                organism = seq_gb.annotations['organism'].replace(' ', '_')
                if organism in excluded_species:
                    continue
                acc = seq_gb.id
                filename = f"{family}_{acc}_{organism}.fasta"
                try:
                    with open(filename,'w') as fasta_out:
                        SeqIO.write(seq_gb, fasta_out, 'fasta')
                    print(acc,order,family,organism, sep='\t',file=acc_map_handle)
                except Bio.Seq.UndefinedSequenceError:
                    #sometimes fresh releases contain sequences without the actual letters.
                    Path(filename).unlink() # delete the empty file 
                    print(f'No sequence contained in {acc}', file=sys.stderr)
                    continue
acc_map_handle.close()
