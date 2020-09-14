from Bio import SeqIO
from pathlib import Path
from collections import defaultdict
import gzip
import sys


with gzip.open(sys.argv[1], 'rt') as gb:
    for n, seq_gb in enumerate(SeqIO.parse(gb, 'genbank')):
        if 'Mammalia' in seq_gb.annotations['taxonomy']:
            family = [name for name in seq_gb.annotations['taxonomy'] if name.endswith('idae')][-1]
            print(family, file=sys.stdout)
            organism = seq_gb.annotations['organism'].replace(' ', '_')
            filename = organism + '.fasta'
            family_species[family].append(organism)
            with p.open(mode='w') as fasta_out:
                SeqIO.write(seq_gb, fasta_out, 'fasta')
