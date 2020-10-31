from Bio import SeqIO
from pathlib import Path
from collections import defaultdict
import gzip
import sys

acc_map_handle = open('accmap.tsv', 'w')
for arg in sys.argv[1:]:   
    with gzip.open(arg, 'rt') as gb:
        for seq_gb in SeqIO.parse(gb, 'genbank'):
            if 'Mammalia' in seq_gb.annotations['taxonomy']:
                family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae')][-1]
                organism = seq_gb.annotations['organism'].replace(' ', '_')
                acc = seq_gb.id
                print(acc,family,organism, sep='\t', file=acc_map_handle)
                filename = f"{family}_{acc}_{organism}.fasta"
                with open(filename,'w') as fasta_out:
                    SeqIO.write(seq_gb, fasta_out, 'fasta')
acc_map_handle.close()
