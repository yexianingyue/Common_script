#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2024-11-05, 14:54:26
# Modiffed date :  2024-11-05, 14:54:26
##########################################################
import argparse
import sys, gzip, re, os, bz2
import copy
# import numpy as np

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", required=True, help="MMseqs2 result.tsv")
    parser.add_argument("-l", required=True, help="Strain list")
    parser.add_argument("-lv", required=False, default=1, type=int, help="which col is strain id.[1:default]")
    parser.add_argument("-o", required=True, help="output")
    args = parser.parse_args()
    return args


def parse_strain_list(inf, lv, mydict, myorder):
    f = open(inf, 'r')
    for index, line in enumerate(f):
        line = line.strip().split("\t")
        strain = line[lv-1]
        mydict[strain] = index
        myorder.append(strain)
    f.close()


def main(args):
    out = open(args.o, 'w')

    strain_order = {}
    myorder = []
    parse_strain_list(args.l, args.lv, strain_order, myorder)
    out.write(f"geneset\t" + '\t'.join(myorder) + "\n") # 写入标题
    template = [0 for i in range(0, len(strain_order)) ] # 模板

    f = open(args.i, 'r')
    del_str = re.compile('_\d+_\d+$')
    tmp = copy.deepcopy(template)
    gf = ''
    for line in f:
        family, gene = line.strip().split("\t")
        strain = del_str.sub('', gene)
        strain_index = strain_order[strain]
        if gf != family:
            if gf == '':
                tmp[strain_index] += 1
                gf = family
                continue
            else:
                out.write(f"{gf}\t" + '\t'.join([str(x) for x in tmp]) + "\n")
                tmp = copy.deepcopy(template)
        gf = family
        tmp[strain_index] += 1
    out.write(f"{gf}\t" + '\t'.join([str(x) for x in tmp]) + "\n")
    out.close()


if __name__ == "__main__":
    args = get_args()
    main(args)


