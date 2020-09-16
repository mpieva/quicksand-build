from Bio import SeqIO
from pathlib import Path
from collections import defaultdict
import gzip
import sys

for arg in sys.argv[1:]:   
    with gzip.open(arg, 'rt') as gb:
        for seq_gb in SeqIO.parse(gb, 'genbank'):
            if 'Mammalia' in seq_gb.annotations['taxonomy']:
                family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae')][-1]
                organism = seq_gb.annotations['organism'].replace(' ', '_')
                filename = f"{family}_{organism}.fasta"
                with open(filename,'w') as fasta_out:
                    SeqIO.write(seq_gb, fasta_out, 'fasta')
