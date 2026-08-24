#!/share/data1/software/miniconda3/bin/python3
# -*- conding: utf-8 -*-
from Bio import Phylo
import sys

if len(sys.argv) < 3:
    print(f"{sys.argv[0]} tree.nwk node1[ node2 node3 node4 ...]")
    exit(0)

tree = Phylo.read(f"{sys.argv[1]}", 'newick')

def calculate_pd(tree, species_subset):
    pd = 0
    for clade in tree.find_clades():
        if any(term.name in species_subset for term in clade.get_terminals()):
            if clade.branch_length:
                pd += clade.branch_length
    return pd

pd_value = calculate_pd(tree, sys.argv[1:])
print(pd_value)
