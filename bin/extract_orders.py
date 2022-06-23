#! /usr/bin/env python3

import pandas as pd
import sys

def main(names, nodes):
    names = pd.read_csv(names, sep='\t', header=None)
    names = names[names[6]=='scientific name'].copy()

    nodes = pd.read_csv(nodes, sep='\t', header=None)
    orders = nodes[nodes[4]=='order'].copy()

    res = orders.merge(names, on=0, validate='1:1')
    res['2_y'].to_csv('orders.txt', index=False, header=None)
    return True

if __name__ == "__main__":
    names = sys.argv[1]
    nodes = sys.argv[2]
    main(names,nodes)
